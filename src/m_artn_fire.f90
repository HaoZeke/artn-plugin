module m_artn_fire
  use h_artn_precision, only: DP

  implicit none

  private
  public :: fire_init, fire_step
  public :: fire_get, fire_set
  public :: fire_dtype


  logical, protected :: fire_is_ready = .false.
  integer, protected :: nmin = 5
  real(DP) :: &   !! NOTE: QE UNITS FOR dt!!
       f_inc = 1.1_DP, &
       f_dec = 0.5_DP, &
       falpha = 0.99_DP, &
       alpha_init = 0.2_DP, &
       dt_max_f = 10.0_DP, &    !! factor to compute dt_max=dt_current*dt_max_f
       dt_init = 20.0_DP

  character(len=255), protected :: infile=""

  namelist/fire_params/ &
       nmin, f_inc, f_dec, falpha, alpha_init, dt_max_f, dt_init

  interface fire_get
     module procedure :: fire_get_int, fire_get_real, fire_get_realdp, fire_get_char
  end interface fire_get

  interface fire_set
     module procedure :: fire_set_int, fire_set_real, fire_set_realdp, fire_set_char
  end interface fire_set

contains

  !> @details
  !! initialise the fire parameters (convert dt to engine_units)
  function fire_init()result(ierr)
    use, intrinsic :: iso_fortran_env, only: io_end => iostat_end
    use h_artn_units, only: units_are_set
    use h_artn_units, only: defined_var
    use d_artn_params, only: filin
    use m_artn_error, only: err_set, ERR_UNITS
    implicit none
    integer :: ierr

    logical :: exist
    character(:), allocatable :: fname
    integer :: u0, ios
    character(len=500) :: msg, line
    ierr = ERR_UNITS
    if( .not. units_are_set ) then
       call err_set( ierr, __FILE__, __LINE__, msg="engine_units are not set!" )
       return
    end if

    ierr = 0
    !! fire is already initialised
    if( fire_is_ready ) return


    !! see if we read from file or not
    if( len_trim(infile) > 1 ) then
       !!
       !! separate file for fire params has been set
       inquire(file=trim(infile), exist=exist)
       if( exist ) then
          !! if the file exists, read from it
          fname=trim(infile)
          !! try reading nml fire_params from it
          open(newunit=u0, file=fname, status="old")
          read(u0, nml=fire_params, iostat=ios, iomsg=msg )
          !!
          if( ios == io_end ) then
             ierr = ios
             call err_set(ierr, __FILE__,__LINE__,&
                  msg="Namelist fire_params not found in file. "//trim(msg)//" file: "//fname )
             return
          elseif( ios /= 0 ) then
             ierr = ios
             backspace(u0)
             read(u0, "(a)") line
             call err_set(ierr, __FILE__,__LINE__,&
                  msg=trim(msg)//" file: "//fname//" line: "//trim(line) )
             return
          end if
          close(u0, status="keep")

       else
          !! file does not exist
          ierr = -1
          call err_set(ierr, __FILE__, __LINE__, &
               msg="specified infile does not exist: "//trim(infile))
          return
       endif
       !!
    else
       !! if artn filin is defined, try to read from there
       if( defined_var(filin)) then
          fname=trim(filin)
          open(newunit=u0, file=fname, status="old")
          read(u0, nml=fire_params, iostat=ios, iomsg=msg )
          !! no error on io_end, since maybe the params are not there at all
          if( ios /= 0 .and. ios /= io_end ) then
             call err_set(ios,__FILE__,__LINE__,msg=trim(msg)//" file: "//fname)
             ierr=ios
             return
          end if
          close(u0)
       end if
    end if


    fire_is_ready = .true.
    ! write(*,*) "dt_init", dt_init
    ! write(*,*) "fire:infile", trim(infile)

  end function fire_init
  !! C wrapper
  function fire_cinit()result(cerr)bind(C,name="fire_init")
    use, intrinsic :: iso_c_binding, only: c_int
    integer( c_int ) :: cerr
    cerr = int( fire_init(), kind=c_int )
  end function fire_cinit



  ! SUBROUTINE fire_step (nat, force, etot, etotold,  displ_vec)
  subroutine fire_step (nat, force, nsteppos, vel, dt, alpha, displ_vec )
    use h_artn_units, only: mass
    use m_artn_error, only: err_set, ERR_OTHER, err_write, merr
    use m_artn_tools, only: dnrm2, ddot

    !> @param [in] nat            size of lists : number of atoms
    !> @param [in] force          list of force on atoms
    !> @param [inout] nsteppos    number of steps with p > 0
    !> @param [inout] vel         list of atomic velicity
    !> @param [inout] dt          current time step (updated after call to routine)
    !> @param [inout] alpha       value of alpha for fire minimization
    !> @param [out] displ_vec     the displacement according to the fire algorithm
    implicit none
    integer,  intent(in)    :: nat
    real(DP), intent(in)    :: force(3,nat)
    integer,  intent(inout) :: nsteppos
    real(DP), intent(inout) :: vel(3,nat)
    real(DP), intent(inout) :: dt
    real(DP), intent(inout) :: alpha
    real(DP), intent(out)   :: displ_vec(3,nat)

    character(8), parameter :: here = "FIRE:"
    real(DP) :: vel_step(3,nat)
    real(DP) :: acc(3,nat)

    real(DP) :: dt_max                 ! initial time step ...
    real(DP) :: norm_displ_vec         ! norm of the displacement vector
    real(DP) :: p                      ! dot product of velocity and force
    real(DP) :: force_norm             ! norm of force vector (for FPE prevention)
    logical :: verbose

    verbose = .true.
    verbose = .false.

    if( verbose )write(*,*) " >> enter fire_step"
    !
    ! check if fire has been initialised
    !
    if( .not. fire_is_ready ) then
       call err_set(ERR_OTHER, __FILE__, __LINE__, msg="fire is not ready! call fire_init before fire_step.")
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    if( verbose )then
      write(*,*) here, "params entering:"
      write(*,"(2(a10,2x)  ,2x,2(a10,2x)  ,2x,a4,4x,2(a8,2x)  )") &
           "dt", "dt_init", "alpha", "alpha_init", "nsteppos", "norm2(vel)", "mass"
      write(*,"(2(g0.8,2x),2x,2(g0.8,2x),2x,i4,4x,2(g0.6,2x))") &
           dt, dt_init, alpha, alpha_init, nsteppos, norm2(vel), mass
    endif
    !
    dt_max = dt_init*dt_max_f
    !
    ! calculate acceleration
    !
    acc(:,:) = force(:,:) / mass
    !
    ! calculate the projection of the velocity on the force
    p = ddot(3*nat,force, 1, vel, 1)
    if( verbose )write(*,"(a,1x,g0.6)") "computed p:",p
    !
    displ_vec(:,:) = 0.0_DP
    !
    if ( p < 0.0_DP  )  then
       ! fire 2.0 algorithm: if p < 0 go back by half a step
       ! for details see reference (2), doi: 10.1016/j.commatsci.2020.109584
       displ_vec(:,:) = displ_vec(:,:) - 0.5_DP*vel(:,:)
    endif
    !
    ! ... manipulate the time step ...
    !
    ! notes:
    ! in original fire the condition is p > 0,
    ! however to prevent the time step decrease in the first step where v=0
    ! (p=0 and etot=etotold) the equality was changed to p >= 0
    ! the energy difference criterion is also added to prevent
    ! the minimization from going uphill
    !
    ! if ( p >= 0.0_DP .and. (etot - etotold) <= 0.d0  ) then
    if ( p >= 0.0_DP ) then
       !
       nsteppos = nsteppos + 1
       ! increase time step and modify mixing factor only after nmin steps in positive direction
       if ( nsteppos > nmin ) then
          dt = min(dt*f_inc, dt_max )
          alpha = alpha*falpha
       end if
    else
       !
       ! set velocity to 0; return alpha to the initial value; reduce time step
       !
       if( verbose )then
         write(*,*) "p < 0.0:: dt, f_dec",dt,f_dec
         write(*,*) "p < 0.0:: alpha, alpha_init",alpha, alpha_init
       endif
       vel_step(:,:) = 0.0_dp
       alpha = alpha_init
       nsteppos = 0
       dt = dt*f_dec
    end if
    !
    ! calculate v(t+dt) = v(t) + a(t)*dt
    !
    vel_step(:,:) = vel(:,:) + dt*acc(:,:)
    if( verbose )write(*,*) "vel_step(:,1)",vel_step(:,1)
    !
    ! velocity mixing
    !
    force_norm = dnrm2(3*nat,force,1)
    IF ( force_norm > epsilon(1.0_dp) ) THEN
       vel_step(:,:) = (1.0_dp - alpha)*vel_step(:,:) + alpha*force(:,:)*dnrm2(3*nat,vel_step,1)/force_norm
    END IF
    !
    ! calculate the displacement x(t+dt) = x(t) + v(t+dt)*dt
    !
    displ_vec(:,:) = displ_vec(:,:) +  vel_step(:,:)*dt
    !
    norm_displ_vec = dnrm2( 3*nat, displ_vec, 1 )
    !
    displ_vec(:,:) = displ_vec(:,:) / norm_displ_vec
    !
    ! keep the step within a threshold
    !
    ! return the velocity to be stored in artn_step
    vel = vel_step
    if( verbose )then
      write(*,*) here,"> vel",norm2(vel)
      write(*,*) here,"> norm_displ_vec",norm_displ_vec
    endif
    ! displ_vec(:,:) = displ_vec(:,:)*min(norm_displ_vec, step_max)
    displ_vec(:,:) = displ_vec(:,:)*norm_displ_vec
    !
    if( verbose )then
      write(*,*) here, "params exiting:"
      write(*,"(2(a10,2x)  ,2x,2(a10,2x)  ,2x,a4,4x,2(a8,2x)  )") &
           "dt", "dt_init", "alpha", "alpha_init", "nsteppos", "norm2(vel)", "mass"
      write(*,"(2(g0.8,2x),2x,2(g0.8,2x),2x,i4,4x,2(g0.6,2x))") &
           dt, dt_init, alpha, alpha_init, nsteppos, norm2(vel), mass

      write(*,*) " >> exit fire_step"
    endif
  endsubroutine fire_step
  !! C wrapper
  subroutine fire_cstep (cnat, cforce, cnsteppos, cvel, cdt, calpha, cdispl_vec)bind(C, name="fire_step")
    use, intrinsic :: iso_c_binding
    integer( c_int ), intent(in), value :: cnat
    real( c_double ), intent(in) :: cforce(3,cnat)
    integer( c_int ), intent(inout) :: cnsteppos
    real( c_double ), intent(inout) :: cvel(3,cnat)
    real( c_double ), intent(inout) :: cdt
    real( c_double ), intent(inout) :: calpha
    real( c_double ), intent(out) :: cdispl_vec(3,cnat)

    real(DP) :: force(3,cnat)
    real(DP) :: vel(3,cnat)
    integer  :: nsteppos
    real(DP) :: dt
    real(DP) :: alpha
    real(DP) :: displ_vec(3,cnat)

    !! read input
    force = real(cforce, kind=DP )
    vel = real( cvel, kind=DP )
    nsteppos = int( cnsteppos )
    dt = real(cdt, kind=DP )
    alpha = real( calpha, kind=DP )

    call fire_step( int(cnat), force, nsteppos, vel, dt, alpha, displ_vec )

    !! set output
    cnsteppos = int( nsteppos, kind=c_int )
    cvel = real( vel, kind = c_double )
    cdt = real( dt, kind=c_double )
    calpha = real( alpha, kind=c_double )
    cdispl_vec = real( displ_vec, kind=c_double )
  end subroutine fire_cstep


  !! fire_set function

  ! nmin
  ! f_inc = 1.1_DP, &
  !      f_dec = 0.5_DP, &
  !      falpha = 0.99_DP, &
  !      alpha_init = 0.2_DP, &
  !      dt_max_f = 10.0_DP, &    !! factor to compute dt_max=dt_current*dt_max_f
  !      dt_init = 20.0_DP
  ! infile

  subroutine fire_set_int( name, val, ierr )
    use m_artn_error, only: err_set
    use m_artn_tools, only: to_lower
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer, intent(out), optional :: ierr
    integer :: ier
    ier = 0
    select case( to_lower(name) )
    case( "nmin"       ); nmin = int(val)
    case default
       ier = -1
       call err_set(ier, __FILE__, __LINE__, &
            msg="invalid name in fire_set: "//name)
    end select
    if(present(ierr))ierr=ier
  end subroutine fire_set_int
  subroutine fire_set_real( name, val, ierr )
    use m_artn_error, only: err_set
    use m_artn_tools, only: to_lower
    implicit none
    character(*), intent(in) :: name
    real, intent(in) :: val
    integer, intent(out), optional :: ierr
    integer :: ier
    call fire_set_realdp( name, real(val, DP), ier )
    if(present(ierr))ierr=ier
  end subroutine fire_set_real
  subroutine fire_set_realdp( name, val, ierr )
    use m_artn_error, only: err_set
    use m_artn_tools, only: to_lower
    implicit none
    character(*), intent(in) :: name
    real(DP), intent(in) :: val
    integer, intent(out), optional :: ierr
    integer :: ier
    ier = 0
    select case( to_lower(name))
    case( "f_inc"      ); f_inc = val
    case( "f_dec"      ); f_dec = val
    case( "falpha"     ); falpha = val
    case( "alpha_init" ); alpha_init = val
    case( "dt_max_f"   ); dt_max_f = val
    case( "dt_init"    ); dt_init = val
    case default
       ier = -1
       call err_set(ier, __FILE__, __LINE__, &
            msg="invalid name in fire_set: "//name)
    end select
    if(present(ierr))ierr=ier
  end subroutine fire_set_realdp
  subroutine fire_set_char( name, val, ierr )
    use m_artn_error, only: err_set
    use m_artn_tools, only: to_lower
    implicit none
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer, intent(out), optional :: ierr
    integer :: ier
    ier = 0
    select case( to_lower(name))
    case( "infile" ); infile = val
    case default
       ier = -1
       call err_set(ier, __FILE__, __LINE__, &
            msg="invalid name in fire_set: "//name)
    end select
    if(present(ierr))ierr=ier
  end subroutine fire_set_char
  !

  !! fire_get functions
  function fire_get_int( name, val )result(ierr)
    use m_artn_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer :: ierr
    select case( name )
    case( "nmin" ); val = nmin
    case default
       ierr = -1
       call err_set(ierr, __FILE__,__LINE__,&
            msg="unknown name in fire_get_realdp: "//trim(name) )
    end select
    ierr = 0
  end function fire_get_int
  function fire_get_real( name, val )result(ierr)
    use m_artn_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    real, intent(out) :: val
    real(DP) :: valdp
    integer :: ierr
    ierr = fire_get_realdp(name, valdp)
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__,__LINE__,&
            msg="unknown name in fire_get_real: "//trim(name) )
       return
    end if
    val = real(valdp)
  end function fire_get_real
  function fire_get_realdp( name, val )result(ierr)
    use m_artn_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer :: ierr
    select case( name )
    case( "dt_init" ); val = dt_init
    case( "f_inc" ); val = f_inc
    case( "f_dec" ); val = f_dec
    case( "falpha" ); val = falpha
    case( "alpha_init" ); val = alpha_init
    case( "dt_max_f" ); val = dt_max_f
    case default
       ierr = -1
       call err_set(ierr, __FILE__,__LINE__,&
            msg="unknown name in fire_get_realdp: "//trim(name) )
    end select
    ierr = 0
  end function fire_get_realdp
  function fire_get_char( name, val )result(ierr)
    use m_artn_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer :: ierr
    select case( name )
    case( "infile"); val = infile
    case default
       ierr = -1
       call err_set(ierr, __FILE__,__LINE__,&
            msg="unknown name in fire_get_char: "//trim(name) )
    end select
    ierr = 0
  end function fire_get_char

  !! C wrapepr
  function fire_cget( cname, cval )result(cerr)bind(C, name="fire_get")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char, c_malloc, f2c_string
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    integer :: ival
    integer, pointer :: p_ival
    real(DP) :: rval
    real(c_double), pointer :: p_rval
    cval = c_null_ptr
    cerr = 0_c_int
    allocate( fname, source=c2f_char(cname) )
    select case( fname )
    case( "nmin" )
       cval = c_malloc( c_sizeof(0_c_int) )
       call c_f_pointer( cval, p_ival )
       cerr = int( fire_get(fname, ival), kind=c_int)
       p_ival = int(ival, kind=c_int)
    case( "infile" )
       cval = f2c_string( fname )
    case default
       cval = c_malloc( c_sizeof(0.0_c_double) )
       call c_f_pointer( cval, p_rval )
       cerr = int( fire_get(fname, rval), kind=c_int)
       p_rval = real(rval, kind=c_double)
    end select
  end function fire_cget


  function fire_dtype( name )result(dtype)
    use d_datainfo
    implicit none
    character(*), intent(in) :: name
    integer :: dtype
    select case( name )
    case( "nmin" )
       dtype = ARTN_DTYPE_INT
    case( "f_inc", "f_dec", "falpha", "alpha_init", "dt_max_f", "dt_init" )
       dtype = ARTN_DTYPE_REAL
    case( "infile" )
       dtype = ARTN_DTYPE_STR
    case default
       dtype = ARTN_DTYPE_UNKNOWN
    end select
  end function fire_dtype
  ! C wrapper
  function fire_ctype( cname )result(ctype)bind(C, name="fire_dtype")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ) :: ctype
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname) )
    ctype = int( fire_dtype(fname), c_int )
  end function fire_ctype


end module m_artn_fire


  ! int fire_set ( const char *name, void* cval );
  function fire_cset( cname, cval )result(cerr)bind(C,name="fire_set")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char
    use d_datainfo, only: ARTN_DTYPE_INT, ARTN_DTYPE_REAL
    use m_artn_error
    use m_artn_fire, only: fire_set_x => fire_set
    use m_artn_fire, only: fire_dtype
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    integer :: dtype
    integer( c_int ), pointer :: iptr
    real( c_double ), pointer :: rptr

    cerr = 0_c_int
    allocate( fname, source=c2f_char(cname))

    dtype = fire_dtype( fname )
    select case( dtype )
    case( ARTN_DTYPE_INT )
       call c_f_pointer( cval, iptr )
       call fire_set_x(fname, iptr, cerr )
    case( ARTN_DTYPE_REAL )
       call c_f_pointer( cval, rptr )
       call fire_set_x(fname, rptr, cerr)
    case default
       cerr = int( ERR_VARNAME, c_int )
       call err_set( int(cerr), __FILE__,__LINE__,&
            msg="unknown variable name: "//fname)
       return
    end select

  end function fire_cset

