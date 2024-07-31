module m_fire
  use precision, only: DP

  implicit none

  private
  public :: fire_init, fire_step
  public :: fire_get


  logical, protected :: fire_is_ready = .false.
  integer, protected :: nmin = 5
  real(DP), protected :: &   !! NOTE: QE UNITS FOR dt!!
       f_inc = 1.1_DP, &
       f_dec = 0.5_DP, &
       falpha = 0.99_DP, &
       alpha_init = 0.2_DP, &
       dt_max_f = 10.0_DP, &    !! factor to compute dt_max=dt_current*dt_max_f
       dt_init = 20.0_DP  

  interface fire_get
     module procedure :: fire_get_int, fire_get_real
  end interface fire_get

contains

  !> @details
  !! initialise the fire parameters (convert dt to engine_units)
  function fire_init()result(ierr)
    use units, only: units_are_set
    use units, only: unconvert_time
    use m_error, only: err_set, ERR_UNITS
    implicit none
    integer :: ierr
    ierr = 0
    if( .not. units_are_set ) then
       ierr = ERR_UNITS
       call err_set( ierr, __FILE__, __LINE__, msg="engine_units are not set!" )
       return
    end if

    dt_init = unconvert_time( dt_init )

    fire_is_ready = .true.

  end function fire_init
  !! C wrapper
  function fire_cinit()result(cerr)bind(C,name="fire_init")
    use, intrinsic :: iso_c_binding, only: c_int
    integer( c_int ) :: cerr
    cerr = int( fire_init(), kind=c_int )
  end function fire_cinit


  function fire_get_int( name, val )result(ierr)
    use m_error, only: merr
    implicit none
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer :: ierr
    select case( name )
    case( "nmin" ); val = nmin
    case default
       write(*,*) "unknown name in fire_get_int: "//trim(name)
       call merr(__FILE__,__LINE__,kill=.true.)
       ierr = -1
    end select
    ierr = 0
  end function fire_get_int
  function fire_get_real( name, val )result(ierr)
    use m_error, only: merr
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
       write(*,*) "unknown name in fire_get_int: "//trim(name)
       call merr(__FILE__,__LINE__,kill=.true.)
       ierr = -1
    end select
    ierr = 0
  end function fire_get_real
  !! C wrapepr
  function fire_cget( cname, cval )result(cerr)bind(C, name="fire_get")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char, c_malloc
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
    allocate( fname, source=c2f_char(cname) )
    select case( fname )
    case( "nmin" )
       cval = c_malloc( c_sizeof(0_c_int) )
       call c_f_pointer( cval, p_ival )
       cerr = int( fire_get(fname, ival), kind=c_int)
       p_ival = int(ival, kind=c_int)
    case default
       cval = c_malloc( c_sizeof(0.0_c_double) )
       call c_f_pointer( cval, p_rval )
       cerr = int( fire_get(fname, rval), kind=c_int)
       p_rval = real(rval, kind=c_double)
    end select
  end function fire_cget




  ! SUBROUTINE fire_step (nat, force, etot, etotold,  displ_vec)
  subroutine fire_step (nat, force, nsteppos, vel, dt, alpha, displ_vec)
    use units, only: mass
    use m_error, only: err_set, ERR_OTHER, err_write, merr
    use m_tools, only: dnrm2, ddot
    ! use artn_params, only: vel, nmin_fire, f_inc, f_dec, falpha, &
    !      dt_max_f, step_max, alpha_init, dt_init, alpha, dt, nsteppos

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

    ! real(DP) :: mass=1.0_DP


    write(*,*) " >> enter fire_step"
    !
    ! check if fire has been initialised
    !
    if( .not. fire_is_ready ) then
       call err_set(ERR_OTHER, __FILE__, __LINE__, msg="fire is not ready! call fire_init before fire_step.")
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if
    8 format(2(a),*(1x,g12.5))
    write(*,8) here, "fire params dt, alpha, nsteppos:", dt, alpha, nsteppos
    write(*,8) here, "vel",norm2(vel)
    write(*,8) here, "mass",mass
    write(*,8) here, "dt_init",dt_init
    !
    dt_max = dt_init*dt_max_f
    !
    ! calculate acceleration
    !
    acc(:,:) = force(:,:) / mass
    !
    ! calculate the projection of the velocity on the force
    p = ddot(3*nat,force, 1, vel, 1)
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
       vel_step(:,:) = 0.d0
       alpha = alpha_init
       nsteppos = 0
       dt = dt*f_dec
    end if
    ! report current parameters
    ! write (*, '(/,5x, "fire native parameters: p = ", f10.8 ", dt = ", f5.2", &
    !       alpha = ", f5.3, " nsteppos = ", i3,  /)' ) p, dt, alpha, nsteppos

    write(*,8) here, "fire params after:, dt, alpha, nsteppos, p, dt/mass", dt, alpha, nsteppos, p, dt/mass, dt*dt/mass
    !
    ! calculate v(t+dt) = v(t) + a(t)*dt
    !
    vel_step(:,:) = vel(:,:) + dt*acc(:,:)
    write(*,*) "vel_step(:,1)",vel_step(:,1)
    !
    ! velocity mixing
    !
    vel_step(:,:) = (1.d0 - alpha)*vel_step(:,:) + alpha*force(:,:)*dnrm2(3*nat,vel_step,1)/dnrm2(3*nat,force,1)
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
    write(*,8) here,"> vel",norm2(vel)
    write(*,8) here,"> norm_displ_vec",norm_displ_vec
    ! displ_vec(:,:) = displ_vec(:,:)*min(norm_displ_vec, step_max)
    displ_vec(:,:) = displ_vec(:,:)*norm_displ_vec
    !
    write(*,*) " >> exit fire_step"
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

  subroutine inoutme( val )bind(C, name="inoutme")
    use, intrinsic :: iso_c_binding, only: c_double
    real( c_double ), intent(inout) :: val

    write(*,*) "F got val:", val
    val = 34.14_c_double
    write(*,*) "F return:", val
  end subroutine inoutme


end module m_fire
