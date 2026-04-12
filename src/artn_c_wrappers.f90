module artn_c_wrappers

  !! This module contains all the C-wrappers to artn routines.

  use h_artn_precision, only : DP
  use m_artn_error, only : err_set, merr, err_write, &
                           ERR_DRANK, ERR_DTYPE, ERR_VARNAME
  use d_datainfo, only : artn_get_dtype, artn_get_drank, artn_get_dsize, &
                         ARTN_DTYPE_INT, ARTN_DTYPE_REAL, ARTN_DTYPE_STR, ARTN_DTYPE_BOOL, &
                         ARTN_DTYPE_UNKNOWN
  use m_artn_tools
contains


  !> @details C wrapper to setup_artn
  !! C header
  !!~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void setup_artn( const int nat, const char *filnam, bool *cerror)
  !!~~~~~~~~~~~~~~~~~~~~~
  subroutine setup_artn2c( cnat, cerror )bind(C,name="setup_artn")
    use, intrinsic :: iso_c_binding
    use m_setup_artn, only: setup_artn
    integer( c_int ), value :: cnat
    logical( c_bool), intent(out) :: cerror
    logical :: lerror
    call setup_artn( int(cnat), lerror )
    cerror = logical(lerror, c_bool )
  end subroutine setup_artn2c



  !> @details
  !! C-wrapper to artn() routine.
  !! Visible as "artn()" from C.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void artn(
  !!           const int nat,
  !!           const double *etot,
  !!           const double *f,
  !!           int const *ityp,
  !!           double *const tau,
  !!           const int *order,
  !!           const double *lat,
  !!           const int *if_pos,
  !!           int *disp_code,
  !!           double *disp_vec,
  !!           bool *lconv);
  !!~~~~~~~~~~~~~~~~
  !!
  SUBROUTINE artn_c( c_nat, c_etot_eng, c_force, c_ityp, c_tau, c_order, c_at, &
       c_if_pos, c_disp_code, c_displ_vec, c_lconv )&
       bind(C, name="artn")
    use, intrinsic :: iso_c_binding, only: c_int, c_double, c_bool
    use m_artn, only: artn

    integer(c_int), value, intent(in)    :: c_nat                !  number of atoms
    real( c_double ),      intent(in)    :: c_etot_eng           !  total energy in current step
    real( c_double ),      intent(in)    :: c_force(3,c_nat)     !  force calculated by the engine
    integer( c_int ),      intent(inout) :: c_ityp(c_nat)        !  atom types
    real( c_double ),      intent(inout) :: c_tau(3,c_nat)       !  atomic positions
    integer( c_int ),      intent(in)    :: c_order(c_nat)       !  engine order of atom
    real( c_double ),      intent(in)    :: c_at(3,3)            !  lattice parameters in alat units
    integer( c_int ),      intent(in)    :: c_if_pos(3,c_nat)    !  coordinates fixed by engine
    integer( c_int ),      intent(out)   :: c_disp_code          !  encoder of stage for move_mode
    real( c_double ),      intent(out)   :: c_displ_vec(3,c_nat) !  displacement vector communicated to move mode
    logical( c_bool ),     intent(out)   :: c_lconv              !  flag for controlling convergence

    !! fortran variables
    integer           :: nat
    real(dp)          :: etot_eng
    integer           :: order(c_nat)
    real(dp)          :: at(3,3)
    integer           :: ityp(c_nat)
    integer           :: if_pos(3,c_nat)
    real(dp)          :: force(3,c_nat)
    real(dp)          :: tau(3,c_nat)
    real(dp)          :: displ_vec(3,c_nat)
    integer           :: disp_code
    logical           :: lconv

    !! transfer c input to fortran
    nat      = int( c_nat )
    etot_eng = real( c_etot_eng, DP )
    order    = int( c_order )
    at       = real( c_at, DP )
    ityp     = int( c_ityp )
    if_pos   = int( c_if_pos )
    force    = real( c_force, DP )
    tau      = real( c_tau, DP )

    call artn( nat, etot_eng, force, ityp, tau, order, at, if_pos, disp_code, displ_vec, lconv )

    !! transfer output to C
    c_displ_vec = real( displ_vec, c_double )
    c_disp_code      = int( disp_code, c_int )
    c_lconv     = logical( lconv, c_bool )

    !! inout args
    ! c_etot_eng = real( etot_eng, c_double )
    c_tau      = real( tau, c_double )

  end SUBROUTINE artn_c


  !> @details
  !! C-wrapper to move_mode() routine.
  !! Visible as "move_mode()" from C.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~{.c}
  !! void move_mode(const int nat,
  !!                const int *order,
  !!                double *const f,
  !!                double *const vel,
  !!                double *etot,
  !!                int *nsteppos,
  !!                double *dt_curr,
  !!                double *alpha,
  !!                const double *alpha_init,
  !!                const double *dt_init,
  !!                int *disp,
  !!                double *disp_vec );
  !!~~~~~~~~~~~~~~~~~~~~
  !!
  subroutine move_mode_c( c_nat, c_order, c_force, c_vel, c_etot, c_nsteppos, c_dt_curr, &
       c_alpha, c_alpha_init, c_dt_init, c_disp, c_displ_vec ) bind(C,name="move_mode")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    use m_move_mode, only: move_mode
    integer( c_int ), value, intent(in)    :: c_nat                ! Size of list: Number of atoms
    integer( c_int ),        intent(in)    :: c_order(c_nat)       ! Order of engine atoms list
    real( c_double ),        intent(inout) :: c_force(3,c_nat)     ! force on atoms
    real( c_double ),        intent(inout) :: c_vel(3,c_nat)       ! atomic velicity
    real( c_double ),        intent(inout) :: c_etot               ! Actual energy total of the system
    integer( c_int ),        intent(inout) :: c_nsteppos           ! ??
    real( c_double ),        intent(inout) :: c_dt_curr            ! Value of dt of FIRE algorithm
    real( c_double ),        intent(inout) :: c_alpha              ! Value of alpha of FIRE algorithm
    real( c_double ),        intent(in)    :: c_alpha_init         ! Initial Value of alpha of FIRE algorithm
    real( c_double ),        intent(in)    :: c_dt_init            ! Initial Value of dt of FIRE algorithm
    integer( c_int ),        intent(in)    :: c_disp               ! Kind of actual displacement
    real( c_double ),        intent(in)    :: c_displ_vec(3,c_nat) ! Displacement field (unit lemgth/force/hessian )

    !! fortran variables
    integer  :: nat
    integer  :: order(c_nat)
    real(dp) :: displ_vec(3,c_nat)
    real(dp) :: force(3,c_nat)
    real(dp) :: vel(3,c_nat)
    real(dp) :: alpha_init, dt_init
    real(dp) :: etot, alpha, dt_curr
    integer  :: nsteppos
    integer  :: disp

    !! transfer input to F
    nat        = int( c_nat )
    order      = int( c_order )
    force      = real( c_force, DP )
    vel        = real( c_vel, DP )
    etot       = real( c_etot, DP )
    nsteppos   = int( c_nsteppos )
    dt_curr    = real( c_dt_curr, DP )
    alpha      = real( c_alpha, DP )
    alpha_init = real( c_alpha_init, DP )
    dt_init    = real( c_dt_init, DP )
    disp       = int( c_disp )
    displ_vec  = real( c_displ_vec, DP )

    call move_mode( nat, order, force, vel, etot, nsteppos, dt_curr, &
         alpha, alpha_init, dt_init, disp, displ_vec )

    !! transfer output to C
    c_force    = real( force, c_double )
    c_vel      = real( vel, c_double )
    c_etot     = real( etot, c_double )
    c_nsteppos = int( nsteppos, c_int )
    c_dt_curr  = real( dt_curr, c_double )
    c_alpha    = real( alpha, c_double )
  end subroutine move_mode_c



  ! C-wrapper
  subroutine cclean_artn()bind(C,name="clean_artn")
    use m_setup_artn, only: clean_artn
    call clean_artn()
  end subroutine cclean_artn



  !> @details
  !! general C setter for variables from `d_artn_data`
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_data( const char * const name, const int crank, const int* csize, const void *cval );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function set_cdata( cname, crank, csize, cval ) result(cerr)bind(C,name="set_data")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char, c2f_string
    !use d_datainfo
    !! call explicitly each set_data_* routine, not the overload
    use d_artn_data, only: set_data_int, set_data_int1d, set_data_real, set_data_real2d
    use d_artn_data, only: set_data_bool, set_data_str
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ), value :: crank
    integer( c_int ), dimension(crank) :: csize
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    ! integer( c_int ), pointer :: dsize(:)
    real( c_double ), pointer :: rptr, r2ptr(:,:)
    integer( c_int ), pointer :: iptr, i1ptr(:)
    logical( c_bool ), pointer :: bptr
    character(:), allocatable :: strval
    character(len=128) :: msg
    integer :: dtype, drank

    cerr = 0_c_int
    allocate( fname, source=c2f_char(cname))
    ! write(*,*) "got cname:", fname
    ! write(*,*) "got crank:",crank
    ! write(*,*) "got csize:",csize

    dtype = artn_get_dtype( fname )
    drank = artn_get_drank( fname )

    !! check if input rank and expected rank are equal
    if( int(crank) .ne. drank ) then
       write(msg, '(a,1x,i0,1x,a,1x,i0)') ". Expected:", drank, "Got:", int(crank)
       call err_set(ERR_DRANK, __FILE__, __LINE__, msg="Invalid data rank for name: "//fname//trim(msg) )
       call err_write(__FILE__,__LINE__ )
       cerr = int( ERR_DRANK, c_int )
    else

    !! the size can only be checked once artn main routine is called (need info of nat)

    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, iptr )
          cerr = int( set_data_int( fname, int(iptr)), c_int )
       case( 1 )
          call c_f_pointer( cval, i1ptr, shape=[csize] )
          cerr = int( set_data_int1d(fname, csize(1), int(i1ptr) ), c_int)
       case default
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__,__LINE__,msg="unsupported data rank for name: "//fname )
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, rptr )
          cerr = int( set_data_real(fname, real(rptr, DP) ), c_int)
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape=[csize] )
          cerr = int( set_data_real2d( fname, csize(1), csize(2), real(r2ptr, DP) ), c_int )
       case default
          write(msg, "(i0)") drank
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__, __LINE__, msg="unsupported data rank for name: "//fname )
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, bptr )
       cerr = int( set_data_bool(fname, logical(bptr)), c_int)

    case( ARTN_DTYPE_STR )
       allocate(strval, source = c2f_string(cval) )
       cerr = int( set_data_str( fname, strval), c_int )

    case default
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="unknown variable name: "//fname )
       cerr = int( ERR_VARNAME, c_int )
    end select

    end if ! rank check

    deallocate( fname )
    if( allocated(strval) ) deallocate( strval )
  end function set_cdata



  !> @details
  !! general get_cdata for all types of variables in d_artn_data.
  !! Arrays are allocated explicitly with `c_malloc()`, thus they can be free'd
  !! by `free()` from C normally.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_data ( const char *name, void** cval );
  !!~~~~~~~~~~~~~~~~
  !!
  !! To cast the value, i.e. into double:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void *c_val;
  !! int cerr;
  !!
  !! if( get_data( "eigval_sad", &c_val) ){
  !!    /* there is error */
  !!    err_write( __FILE__, __LINE__ );
  !! }
  !! /* read the double value from void*, and free its allocation */
  !! double eigval_sad = *(double *) c_val;
  !! free( c_val );
  !! printf( "eigenvalue at saddle value: %f\n", eigval_sad );
  !!~~~~~~~~~~~~~~~~
  !!
  function get_cdata( cname, cval )result(cerr)bind(C,name="get_data")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: f2c_string, c_malloc, c_free
    !use d_datainfo
    use d_artn_data, only: get_data_int, get_data_int1d
    use d_artn_data, only: get_data_real, get_data_real2d
    use d_artn_data, only: get_data_bool, get_data_str
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(:), allocatable :: fname, fstr
    integer :: ierr, dtype, drank
    integer, allocatable :: dsize(:)
    integer :: fint
    integer, allocatable :: fint1d(:)
    real(DP) :: freal
    real(DP), allocatable :: freal2d(:,:)
    logical :: fbool
    character(len=64) :: msg
    integer( c_int ), pointer :: iptr => null(), i1ptr(:) => null()
    real( c_double ), pointer :: rptr => null(), r2ptr(:,:) => null()
    logical( c_bool ), pointer :: bptr => null()


    cval = c_null_ptr

    allocate( fname, source=c2f_char(cname) )
    ! write(*,*) "got fname:",fname

    !! get dtype
    dtype = artn_get_dtype( fname )
    ! write(*,*) "dtype:",dtype

    !! unknown dtype at this point is an error due to unknown variable
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       cerr = int( ERR_VARNAME, c_int )
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="Unknown variable name: "//fname )
       call err_write( __FILE__, __LINE__)
    else

    !! get drank
    drank = artn_get_drank( fname )

    !! get dsize
    ierr = artn_get_dsize( fname, dsize )
    if( ierr /= 0 ) then
       cerr = int(ierr, c_int)
       call err_write( __FILE__, __LINE__)
    else

    !! decide what to do based on dtype
    select case( dtype )
    case( ARTN_DTYPE_INT )

       !! cast pointer based on rank
       select case( drank )
       case( 0 )
          cval = c_malloc( c_sizeof(1_c_int) )
          call c_f_pointer( cval, iptr )
          call get_data_int( fname, fint, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             iptr = int( fint, c_int )
          end if

       case( 1 )
          cval = c_malloc( c_sizeof(1_c_int)*int(dsize(1), c_size_t) )
          call c_f_pointer( cval, i1ptr, shape=[dsize(1)] )
          call get_data_int1d( fname, fint1d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             i1ptr = int( fint1d, c_int )
          end if

       case default
          cerr = int(ERR_DRANK, c_int )
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for int")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select


    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          cval = c_malloc( c_sizeof(1.0_c_double) )
          call c_f_pointer( cval, rptr )
          call get_data_real( fname, freal, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             rptr = real(freal, c_double)
          end if

       case( 2 )
          cval = c_malloc( c_sizeof(1.0_c_double)*int(dsize(1)*dsize(2), c_size_t) )
          call c_f_pointer( cval, r2ptr, shape=[dsize(1), dsize(2)])
          call get_data_real2d( fname, freal2d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             r2ptr = real( freal2d, c_double )
          end if

       case default
          cerr = int(ERR_DRANK, c_int )
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for real")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select

    case( ARTN_DTYPE_BOOL )
       cval = c_malloc( c_sizeof(1_c_bool) )
       call c_f_pointer( cval, bptr )
       call get_data_bool( fname, fbool, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call c_free(cval); cval = c_null_ptr
          call err_write(__FILE__,__LINE__)
       else
          bptr = logical(fbool, c_bool)
       end if

    case( ARTN_DTYPE_STR )
       call get_data_str( fname, fstr, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
       else
          cval = f2c_string( fstr )
       end if

    case default
       ierr = ERR_DTYPE
       write(msg, "(a,1x,i0)") "unknwon dtpe value:",dtype
       call err_set(ierr, __FILE__, __LINE__, msg=msg )
       call err_write( __FILE__,__LINE__)
       cerr = int(ierr, c_int )
    end select

    end if ! dsize check
    end if ! dtype check

    deallocate( fname )
    if( allocated(dsize) ) deallocate( dsize )
  end function get_cdata

  !> @details
  !! C-wrapper to artn_list_extract() from get_data.f90
  !! header
  !!~~~~~~~~~~~~~(.c)
  !! void artn_list_extract();
  !!~~~~~~~~~~~~~
  subroutine cartn_list_extract()bind(C,name="artn_list_extract")
    use d_artn_data, only: artn_list_extract
    call artn_list_extract()
  end subroutine cartn_list_extract





  !> @details
  !! wrapper to general `set_param`
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_param( const char * const name, const int crank, const int* csize, const void *cval );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function set_cparam( cname, crank, csize, cval ) result(cerr)bind(C,name="set_param")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char, c2f_string
    !use d_datainfo
    use d_artn_params, only: set_param_int, set_param_int1d
    use d_artn_params, only: set_param_real, set_param_real2d
    use d_artn_params, only: set_param_bool, set_param_str
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ), value :: crank
    integer( c_int ), dimension(crank) :: csize
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    ! integer( c_int ), pointer :: dsize(:)
    real( c_double ), pointer :: rptr, r2ptr(:,:)
    integer( c_int ), pointer :: iptr, i1ptr(:)
    logical( c_bool ), pointer :: bptr
    character(:), allocatable :: strval
    character(len=128) :: msg
    integer :: dtype, drank

    cerr = 0_c_int
    allocate( fname, source=c2f_char(cname))

    dtype = artn_get_dtype( fname )
    drank = artn_get_drank( fname )

    !! check if input rank and expected rank are equal
    if( int(crank) .ne. drank ) then
       write(msg, '(a,1x,i0,1x,a,1x,i0)') ". Expected:", drank, "Got:", int(crank)
       call err_set(ERR_DRANK, __FILE__, __LINE__, msg="Invalid data rank for name: "//fname//trim(msg) )
       call err_write(__FILE__,__LINE__ )
       cerr = int( ERR_DRANK, c_int )
    else

    !! the size can only be checked once artn main routine is called (need info of nat)

    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, iptr )
          cerr = int( set_param_int( fname, int(iptr)), c_int )
       case( 1 )
          call c_f_pointer( cval, i1ptr, shape=[csize] )
          cerr = int( set_param_int1d(fname, csize(1), int(i1ptr) ), c_int)
       case default
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__,__LINE__,msg="unsupported data rank for name: "//fname )
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, rptr )
          cerr = int( set_param_real(fname, real(rptr, DP) ), c_int)
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape=[csize] )
          cerr = int( set_param_real2d( fname, csize(1), csize(2), real(r2ptr, DP) ), c_int )
       case default
          write(msg, "(i0)") drank
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__, __LINE__, msg="unsupported data rank for name: "//fname )
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, bptr )
       cerr = int( set_param_bool(fname, logical(bptr)), c_int)

    case( ARTN_DTYPE_STR )
       allocate(strval, source = c2f_string(cval))
       cerr = int( set_param_str( fname, strval), c_int )

    case default
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="unknown variable name: "//fname )
       cerr = int( ERR_VARNAME, c_int )
    end select

    end if ! rank check

    deallocate( fname )
    if( allocated(strval) ) deallocate( strval )
  end function set_cparam


  !> @details
  !! generalize get_cparam for all variable types in d_artn_params.
  !! Arrays are allocated explicitly with `c_malloc()`, thus they can be free'd
  !! by `free()` from C normally.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_param ( const char *name, void** cval );
  !!~~~~~~~~~~~~~~~~
  !!
  !! To cast the value, i.e. into double:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void *c_val;
  !! int cerr;
  !!
  !! if( !get_param( "forc_thr", &c_val) ){
  !!    /* there is error */
  !!    err_write( __FILE__, __LINE__ );
  !! }
  !! /* read the double value from void*, and free its allocation */
  !! double forc_thr = *(double *) c_val;
  !! free( c_val );
  !! printf( "forc threshold value: %f\n", forc_thr );
  !!~~~~~~~~~~~~~~~~
  !!
  function get_cparam( cname, cval )result(cerr)bind(C,name="get_param")
    use, intrinsic :: iso_c_binding
    !use d_datainfo
    use m_artn_tools, only: c_malloc, c_free
    use d_artn_params, only: get_param_int, get_param_int1d
    use d_artn_params, only: get_param_real, get_param_real2d
    use d_artn_params, only: get_param_bool, get_param_str
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(:), allocatable :: fname, fstr
    integer :: ierr, dtype, drank
    integer, allocatable :: dsize(:)
    integer :: fint
    integer, allocatable :: fint1d(:)
    real(DP) :: freal
    real(DP), allocatable :: freal2d(:,:)
    logical :: fbool
    character(len=64) :: msg
    integer( c_int ), pointer :: iptr => null(), i1ptr(:) => null()
    real( c_double ), pointer :: rptr => null(), r2ptr(:,:) => null()
    logical( c_bool ), pointer :: bptr => null()


    cval = c_null_ptr

    allocate( fname, source=c2f_char(cname) )

    !! get dtype
    dtype = artn_get_dtype( fname )
    !! unknown dtype at this point is an error due to unknown variable
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       cerr = int( ERR_VARNAME, c_int )
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="Unknown variable name: "//fname )
       call err_write( __FILE__, __LINE__)
    else

    !! get drank
    drank = artn_get_drank( fname )

    !! get dsize
    ierr = artn_get_dsize( fname, dsize )
    if( ierr /= 0 ) then
       cerr = int(ierr, c_int)
       call err_write( __FILE__, __LINE__)
    else

    !! decide what to do based on dtype
    select case( dtype )
    case( ARTN_DTYPE_INT )

       select case( drank )
       case( 0 )
          cval = c_malloc( c_sizeof(1_c_int) )
          call c_f_pointer( cval, iptr )
          call get_param_int( fname, fint, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             iptr = int(fint, c_int )
          end if

       case( 1 )
          cval = c_malloc( c_sizeof(1_c_int)*int(dsize(1), c_size_t) )
          call c_f_pointer( cval, i1ptr, shape=[dsize(1)] )
          call get_param_int1d( fname, fint1d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             i1ptr = int( fint1d, c_int )
          end if

       case default
          cerr = int( ERR_DRANK, c_int )
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for int")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select


    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          cval = c_malloc( c_sizeof(1.0_c_double) )
          call c_f_pointer( cval, rptr )
          call get_param_real( fname, freal, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             rptr = real(freal, c_double )
          end if

       case( 2 )
          cval = c_malloc( c_sizeof(1.0_c_double)*int(dsize(1)*dsize(2), c_size_t) )
          call c_f_pointer( cval, r2ptr, shape=[dsize(1), dsize(2)])
          call get_param_real2d( fname, freal2d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             r2ptr = real( freal2d, c_double )
          end if

       case default
          cerr = int( ERR_DRANK, c_int )
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for real")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select

    case( ARTN_DTYPE_BOOL )
       cval = c_malloc( c_sizeof(1_c_bool) )
       call c_f_pointer( cval, bptr )
       call get_param_bool( fname, fbool, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call c_free(cval); cval = c_null_ptr
          call err_write(__FILE__,__LINE__)
       else
          bptr = logical(fbool, c_bool)
       end if

    case( ARTN_DTYPE_STR )
       call get_param_str( fname, fstr, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
       else
          cval = f2c_string( fstr )
       end if

    case default
       ierr = ERR_DTYPE
       write(msg, "(a,1x,i0)") "unknwon dtpe value:",dtype
       call err_set(ierr, __FILE__, __LINE__, msg=msg )
       call err_write( __FILE__,__LINE__)
       cerr = int(ierr, c_int)
    end select

    end if ! dsize check
    end if ! dtype check

    deallocate( fname )
    if( allocated(dsize) ) deallocate( dsize )
  end function get_cparam



  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_runparam( const char * const name, const int crank, const int* csize, const void *cval );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function set_crunparam( cname, crank, csize, cval ) result(cerr)bind(C,name="set_runparam")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char, c2f_string
    !use d_datainfo
    use d_artn_params, only: set_runparam_int
    use d_artn_params, only: set_runparam_real1d, set_runparam_real2d
    use d_artn_params, only: set_runparam_bool, set_runparam_str
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ), value :: crank
    integer( c_int ), dimension(crank) :: csize
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    ! integer( c_int ), pointer :: dsize(:)
    real( c_double ), pointer :: r1ptr(:), r2ptr(:,:)
    integer( c_int ), pointer :: iptr
    logical( c_bool ), pointer :: bptr
    character(:), allocatable :: strval
    character(len=128) :: msg
    integer :: dtype, drank

    cerr = 0_c_int
    allocate( fname, source=c2f_char(cname))
    ! write(*,*) "got cname:", fname
    ! write(*,*) "got crank:",crank
    ! write(*,*) "got csize:",csize

    dtype = artn_get_dtype( fname )
    drank = artn_get_drank( fname )

    !! check if input rank and expected rank are equal
    if( int(crank) .ne. drank ) then
       write(msg, '(a,1x,i0,1x,a,1x,i0)') ". Expected:", drank, "Got:", int(crank)
       call err_set(ERR_DRANK, __FILE__, __LINE__, msg="Invalid data rank for name: "//fname//trim(msg) )
       call err_write(__FILE__,__LINE__ )
       cerr = int( ERR_DRANK, c_int )
    else

    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, iptr )
          cerr = int( set_runparam_int( fname, int(iptr)), c_int )
       case default
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__,__LINE__,msg="unsupported data rank for name: "//fname )
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 1 )
          call c_f_pointer( cval, r1ptr, shape=[csize] )
          cerr = int( set_runparam_real1d( fname, csize(1), real(r1ptr, DP) ), c_int )
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape=[csize] )
          cerr = int( set_runparam_real2d( fname, csize(1), csize(2), real(r2ptr, DP) ), c_int )
       case default
          write(msg, "(i0)") drank
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__, __LINE__, msg="unsupported data rank for name: "//fname )
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, bptr )
       cerr = int( set_runparam_bool(fname, logical(bptr)), c_int)

    case( ARTN_DTYPE_STR )
       allocate(strval, source = c2f_string(cval) )
       cerr = int( set_runparam_str( fname, strval), c_int )

    case default
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="unknown variable name: "//fname )
       cerr = int( ERR_VARNAME, c_int )
    end select

    end if ! rank check

    deallocate( fname )
    if( allocated(strval) ) deallocate( strval )
  end function set_crunparam


  !> @details
  !! generalize get_cparam.
  !! Arrays are allocated explicitly with `c_malloc()`, thus they can be free'd
  !! by `free()` from C normally.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_runparam ( const char *name, void** cval );
  !!~~~~~~~~~~~~~~~~
  !!
  !! The `void* cval` needs to be freed afterwards.
  function get_crunparam( cname, cval )result(cerr)bind(C,name="get_runparam")
    use, intrinsic :: iso_c_binding
    !use d_datainfo
    use m_artn_tools, only: c2f_char, f2c_string, c_malloc, c_free
    use d_artn_params, only: get_runparam_int
    use d_artn_params, only: get_runparam_real, get_runparam_real1d, get_runparam_real2d
    use d_artn_params, only: get_runparam_bool, get_runparam_str
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(:), allocatable :: fname, fstr
    integer :: ierr, dtype, drank
    integer, allocatable :: dsize(:)
    integer :: fint
    real(DP) :: freal
    real(DP), allocatable :: freal1d(:), freal2d(:,:)
    logical :: fbool
    character(len=64) :: msg
    integer( c_int ), pointer :: iptr => null()
    real( c_double ), pointer :: rptr => null(), r1ptr(:) => null(), r2ptr(:,:) => null()
    logical( c_bool ), pointer :: bptr => null()


    cval = c_null_ptr

    allocate( fname, source=c2f_char(cname) )
    ! write(*,*) "got fname:",fname

    !! get dtype
    dtype = artn_get_dtype( fname )
    ! write(*,*) "dtype:",dtype

    !! unknown dtype at this point is an error due to unknown variable
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       cerr = int( ERR_VARNAME, c_int )
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="Unknown variable name: "//fname )
       call err_write( __FILE__, __LINE__)
    else

    !! get drank
    drank = artn_get_drank( fname )

    !! get dsize
    ierr = artn_get_dsize( fname, dsize )
    if( ierr /= 0 ) then
       cerr = int(ierr, c_int)
       call err_write(__FILE__,__LINE__)
    else

    !! decide what to do based on dtype
    select case( dtype )
    case( ARTN_DTYPE_INT )

       select case( drank )
       case( 0 )
          cval = c_malloc( c_sizeof(1_c_int) )
          call c_f_pointer( cval, iptr )
          call get_runparam_int( fname, fint, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             iptr = int( fint, c_int )
          end if

       case default
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for int")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select


    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          cval = c_malloc( c_sizeof(1.0_c_double) )
          call c_f_pointer( cval, rptr )
          call get_runparam_real( fname, freal, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             rptr = real( freal, c_double )
          end if

       case( 1 )
          cval = c_malloc( c_sizeof(1.0_c_double)*int(dsize(1), c_size_t) )
          call c_f_pointer( cval, r1ptr, shape=[dsize(1)])
          call get_runparam_real1d( fname, freal1d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             r1ptr = real( freal1d, c_double )
          end if

       case( 2 )
          cval = c_malloc( c_sizeof(1.0_c_double)*int(dsize(1)*dsize(2), c_size_t) )
          call c_f_pointer( cval, r2ptr, shape=[dsize(1), dsize(2)])
          call get_runparam_real2d( fname, freal2d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call c_free(cval); cval = c_null_ptr
             call err_write(__FILE__,__LINE__)
          else
             r2ptr = real(freal2d, c_double)
          end if

       case default
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for real")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select

    case( ARTN_DTYPE_BOOL )
       cval = c_malloc( c_sizeof(1_c_bool) )
       call c_f_pointer( cval, bptr )
       call get_runparam_bool( fname, fbool, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call c_free(cval); cval = c_null_ptr
          call err_write(__FILE__,__LINE__)
       else
          bptr = logical( fbool, c_bool )
       end if

    case( ARTN_DTYPE_STR )
       call get_runparam_str( fname, fstr, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
       else
          cval = f2c_string( fstr )
       end if

    case default
       cerr = int( ERR_DTYPE )
       write(msg, "(a,1x,i0)") "unknwon dtpe value:",dtype
       call err_set(ERR_DTYPE, __FILE__, __LINE__, msg=msg )
       call err_write( __FILE__,__LINE__)
    end select

    end if ! dsize check
    end if ! dtype check

    deallocate( fname )
    if( allocated(dsize) ) deallocate( dsize )
  end function get_crunparam





  !! C-wrapper
  !! header:
  !!~~~~~~~~~~~~~~~{.c}
  !! void artn_list_set();
  !!~~~~~~~~~~~~~~~
  subroutine cartn_list_set()bind(C,name="artn_list_set")
    use d_artn_params, only: artn_list_set
    call artn_list_set()
  end subroutine cartn_list_set

  !!details
  !! C-wrapper
  !! header:
  !!~~~~~~~~~~~~~~{.c}
  !! void artn_list_extract_param();
  !!~~~~~~~~~~~~~~
  subroutine cartn_list_extract_param()bind(C,name="artn_list_extract_param")
    use d_artn_params, only: artn_list_extract_param
    call artn_list_extract_param()
  end subroutine cartn_list_extract_param

  !! C-wrapper
  subroutine cdump_input( cname )bind(C,name="dump_input")
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char
    use d_artn_params, only: dump_input
    character(len=1, kind=c_char), intent(in) :: cname(*)
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    call dump_input( fname )
    deallocate( fname )
  end subroutine cdump_input

  !! C wrapper
  subroutine cdump_data( cname )bind(C, name="dump_data" )
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char
    use d_artn_params, only: dump_data
    character(len=1, kind=c_char), intent(in) :: cname(*)
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    call dump_data( fname )
    deallocate( fname )
  end subroutine cdump_data


  !! C- wrapper
  function cread_datadump( cname )result(cerr)bind(C, name="read_datadump" )
    use, intrinsic :: iso_c_binding
    use m_artn_tools, only: c2f_char
    use d_artn_params, only: read_datadump
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer(c_int) :: cerr
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    cerr = int(read_datadump( fname ), c_int )
    deallocate( fname )
  end function cread_datadump




  !> @details
  !! Wrapper for permute_int1d, corder should contain fortran-style indices (start at 1)
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void permute_int1d( const int dim1, int *const array, const int* order );
  !!~~~~~~~~~~~~~~~~~~~~~~
  subroutine permute_int1d_c( cdim1, carray, corder )bind(C, name="permute_int1d")
    use, intrinsic :: iso_c_binding, only: c_int
    use m_artn_tools, only: permute_int1d
    implicit none
    integer( c_int ), value, intent(in) :: cdim1
    integer(c_int), intent(inout) :: carray(cdim1)
    integer(c_int), intent(in) :: corder(cdim1)
    integer :: array(cdim1), order(cdim1)
    array = int(carray); order = int(corder)
    call permute_int1d( int(cdim1), array, order )
    carray = int(array, c_int)
  end subroutine permute_int1d_c

  !> @details
  !! Wrapper for unpermute_int1d, corder shoudl contain fortran-style indices (start at 1)
  !!~~~~~~~~~~~~~~~{.c}
  !! void unpermute_int1d( const int dim1, int *const array, const int* order );
  !!~~~~~~~~~~~~~~~
  subroutine unpermute_int1d_c( cdim1, carray, corder )bind(C, name="unpermute_int1d")
    use, intrinsic :: iso_c_binding, only: c_int
    use m_artn_tools, only: unpermute_int1d
    implicit none
    integer( c_int ), value, intent(in) :: cdim1
    integer(c_int), intent(inout) :: carray(cdim1)
    integer(c_int), intent(in) :: corder(cdim1)
    integer :: array(cdim1), order(cdim1)
    array = int(carray); order = int(corder)
    call unpermute_int1d( int(cdim1), array, order )
    carray = int(array, c_int)
  end subroutine unpermute_int1d_c

  !> @details
  !! Wrapper for permute_real2d, corder should contain fortran-style indices (start at 1)
  !!~~~~~~~~~~~~~~~~~~~{.c}
  !! void permute_real2d( const int dim1, double * const array, const int * order );
  !!~~~~~~~~~~~~~~~~~~~
  subroutine permute_real2d_c( cdim1, carray, corder )bind(C,name="permute_real2d")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    use m_artn_tools, only: permute_real2d
    integer( c_int ), value, intent(in) :: cdim1
    real( c_double ), intent(inout) :: carray(3, cdim1)
    integer( c_int ), intent(in) :: corder(cdim1)
    real(DP), dimension(3,cdim1) :: array
    integer, dimension(cdim1) :: order
    array = real( carray, DP ); order = int( corder )
    call permute_real2d( int(cdim1), array, order )
    carray = real( array, c_double )
  end subroutine permute_real2d_c


  !> @details
  !! Wrapper for unpermute_real2d, corder should contain fortran-style indices (start at 1)
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void unpermute_real2d( const int dim1, double * const array, const int * order );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  subroutine unpermute_real2d_c( cdim1, carray, corder )bind(C,name="unpermute_real2d")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    use m_artn_tools, only: unpermute_real2d
    integer( c_int ), value, intent(in) :: cdim1
    real( c_double ), intent(inout) :: carray(3, cdim1)
    integer( c_int ), intent(in) :: corder(cdim1)
    real(DP), dimension(3,cdim1) :: array
    integer, dimension(cdim1) :: order
    array = real( carray, DP ); order = int( corder )
    call unpermute_real2d( int(cdim1), array, order )
    carray = real( array, c_double )
  end subroutine unpermute_real2d_c


  !> @details
  !! wrapper to call `c_free` on memory allocated by `c_malloc` in the
  !! pArtn-C interface (get_data, etc). From C you can directly call `free( val )`,
  !! but this wrapper is needed for the python interface.
  !!~~~~~~~~{.c}
  !! void artn_free( void* );
  !!~~~~~~~~
  subroutine artn_cfree( cptr )bind(C,name="artn_free")
    use, intrinsic :: iso_c_binding, only: c_ptr
    use m_artn_tools, only: c_free
    type( c_ptr ), value :: cptr
    call c_free( cptr )
  end subroutine artn_cfree


end module artn_c_wrappers
