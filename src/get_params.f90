submodule( artn_params )get_params
  use m_error
  use units
  use m_tools
  use precision
  !! routines to extract the user-accessible variables from artn_params_mod
  implicit none
contains


  !! helper functions
  module function get_param_dtype( name )result( dtype )
    !! return value of expected data type of variable <name>, even if variable is not set
    character(*), intent(in) :: name
    integer :: dtype
    select case( name )
    case( &
         "ninit", &
         "neigen", &
         "nperp", &
         "lanczos_max_size", &
         "lanczos_min_size", &
         "nsmooth", &
         "nevalf_max", &
         "zseed", &
         "nnewchance", &
         "nrelax_print", &
         "restart_freq" &
         ); dtype = ARTN_DTYPE_INT

    case( &
         "push_dist_thr", &
         "forc_thr", &
         "eigval_thr", &
         "delr_thr", &
         "lanczos_eval_conv_thr", &
         "push_step_size", &
         "push_step_size_per_atom", &
         "lanczos_disp", &
         "eigen_step_size", &
         "etot_diff_limit", &
         "alpha_mix_cr" &
         ); dtype = ARTN_DTYPE_REAL

    case( &
         "bb" ); dtype = ARTN_DTYPE_BOOL

    case(&
         "cc" ); dtype = ARTN_DTYPE_STR

    case default
       dtype = ARTN_DTYPE_UNKNOWN
    end select
  end function get_param_dtype

  module function get_param_drank( name )result( drank )
    !! return value of expected rank of variable <name>, even if variable is not set
    character(*), intent(in) :: name
    integer :: drank
  end function get_param_drank

  module subroutine get_param_dsize( name, drank, dsize, ierr )
    !! return actual size of variable <name>, if varibale not allocated return negative ierr
    character(*), intent(in) :: name
    integer, intent(in) :: drank
    integer, dimension(drank), intent(out) :: dsize
    integer, intent(out) :: ierr
  end subroutine get_param_dsize


  !! fortran version
  module subroutine get_param_int( name, val, ierr )
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "ninit"            ); val = ninit
    case( "neigen"           ); val = neigen
    case( "nperp"            ); val = nperp
    case( "lanczos_max_size" ); val = lanczos_max_size
    case( "lanczos_min_size" ); val = lanczos_min_size
    case( "nsmooth"          ); val = nsmooth
    case( "nevalf_max"       ); val = nevalf_max
    case( "zseed"            ); val = zseed
    case( "nnewchance"       ); val = nnewchance
    case( "nrelax_print"     ); val = nrelax_print
    case( "restart_freq"     ); val = restart_freq
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_int(): "//name )
    end select
  end subroutine get_param_int
  module subroutine get_param_real( name, val, ierr )
    !! return unconverted values
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer, intent(out) :: ierr
    real(DP) :: converted_val
    ierr = 0
    !! get the converted value
    select case( name )
    case( "push_dist_thr"           ); converted_val = push_dist_thr
    case( "forc_thr"                ); converted_val = forc_thr
    case( "eigval_thr"              ); converted_val = eigval_thr
    case( "delr_thr"                ); converted_val = delr_thr
    case( "lanczos_eval_conv_thr"   ); converted_val = lanczos_eval_conv_thr
    case( "push_step_size"          ); converted_val = push_step_size
    case( "push_step_size_per_atom" ); converted_val = push_step_size_per_atom
    case( "lanczos_disp"            ); converted_val = lanczos_disp
    case( "eigen_step_size"         ); converted_val = eigen_step_size
    case( "etot_diff_limit"         ); converted_val = etot_diff_limit
    case( "alpha_mix_cr"            ); converted_val = alpha_mix_cr
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_real(): "//name )
       call err_write(__FILE__,__LINE__)
       return
    end select
    !! unconvert
    val = unconvert_param( name, converted_val, ierr )
    if( ierr /= 0 ) then
       !! error when units are not set
       call err_write(__FILE__,__LINE__)
       return
    end if
  end subroutine get_param_real
  module subroutine get_param_bool( name, val, ierr )
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_bool(): "//name )
    end select
  end subroutine get_param_bool
  module subroutine get_param_str( name, val, ierr )
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_str(): "//name )
    end select
  end subroutine get_param_str


  !> @details
  !! wrapper to get_param_int. Visible to C as "get_param_int()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int get_param_int( const char *name, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  module function get_cparam_int( cname, cerr )result(cval)bind(C,name="get_param_int")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ), intent(out) :: cerr
    integer( c_int ) :: cval
    character(:), allocatable :: fname
    integer :: ierr
    integer :: fval
    allocate( fname, source=c2f_char(cname) )
    call get_param_int( fname, fval, ierr )
    cerr = int( ierr, c_int )
    cval = int( fval, c_int )
    deallocate( fname )
  end function get_cparam_int


  !> @details
  !! wrapper to get_param_real. Visible to C as "get_param_real()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! double get_param_real( const char *name, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  module function get_cparam_real( cname, cerr )result(cval)bind(C,name="get_param_real")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ), intent(out) :: cerr
    real( c_double ) :: cval
    character(:), allocatable :: fname
    integer :: ierr
    real(DP) :: fval
    allocate( fname, source=c2f_char(cname) )
    call get_param_real( fname, fval, ierr )
    cerr = int( ierr, c_int )
    cval = real( fval, c_double )
    deallocate( fname )
  end function get_cparam_real


  !> @details
  !! wrapper to get_param_bool. Visible to C as "get_param_bool()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! bool get_param_bool( const char *name, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  module function get_cparam_bool( cname, cerr )result(cval)bind(C,name="get_param_bool")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ), intent(out) :: cerr
    logical( c_bool ) :: cval
    character(:), allocatable :: fname
    integer :: ierr
    logical :: fval
    allocate( fname, source=c2f_char(cname) )
    call get_param_bool( fname, fval, ierr )
    cerr = int( ierr, c_int )
    cval = logical( fval, c_bool )
    deallocate( fname )
  end function get_cparam_bool


  !> @details
  !! wrapper to get_param_str. Visible to C as "get_param_str()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! str* get_param_str( const char *name, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  module function get_cparam_str( cname, cerr )result(cval)bind(C,name="get_param_str")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ), intent(out) :: cerr
    type( c_ptr ) :: cval
    character(:), allocatable :: fname
    integer :: ierr
    character(:), allocatable :: fval
    allocate( fname, source=c2f_char(cname) )
    call get_param_str( fname, fval, ierr )
    cval = f2c_string(fval)
    cerr = int( ierr, c_int )
    deallocate( fname )
  end function get_cparam_str



  !> @details
  !! generalize get_cparam
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_param ( const char *name, void* cval );
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
  !! /* read the double value from void* */
  !! double forc_thr = *(double *) c_val;
  !! printf( "forc threshold value: %f\n", forc_thr );
  !!~~~~~~~~~~~~~~~~
  !!
  module function get_cparam( cname, cval )result(cerr)bind(C,name="get_param")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(:), allocatable :: fname, fstr
    integer :: ierr, dtype
    integer :: fint
    real(DP) :: freal
    logical :: fbool
    character(len=64) :: msg
    integer( c_int ), pointer :: iptr => null()
    real( c_double ), pointer :: rptr => null()
    logical( c_bool ), pointer :: bptr => null()


    cval = c_null_ptr

    allocate( fname, source=c2f_char(cname) )
    write(*,*) "got fname:",fname

    !! get dtype
    dtype = get_param_dtype( fname )
    write(*,*) "dtype:",dtype
    !! unknown dtype at this point is an error due to unknown variable
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       cerr = int( ERR_VARNAME, c_int )
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="Unknown variable name: "//fname )
       call err_write( __FILE__, __LINE__)
       return
    end if

    !! decide what to do based on dtype
    select case( dtype )
    case( ARTN_DTYPE_INT )
       call get_param_int( fname, fint, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
          return
       end if
       allocate( iptr, source=int(fint, c_int) )
       cval = c_loc( iptr )

    case( ARTN_DTYPE_REAL )
       call get_param_real( fname, freal, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
          return
       end if
       allocate( rptr, source=real(freal,c_double) )
       cval = c_loc( rptr )

    case( ARTN_DTYPE_BOOL )
       call get_param_bool( fname, fbool, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
          return
       end if
       allocate( bptr, source=logical(fbool, c_bool) )
       cval = c_loc( bptr )

    case( ARTN_DTYPE_STR )
       call get_param_str( fname, fstr, cerr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
          return
       end if
       cval = f2c_string( fstr )

    case default
       ierr = ERR_DTYPE
       write(msg, "(a,1x,i0)") "unknwon dtpe value:",dtype
       call err_set(ierr, __FILE__, __LINE__, msg=msg )
       call err_write( __FILE__,__LINE__)
       return
    end select

    cerr = 0_c_int
    deallocate( fname )
  end function get_cparam


end submodule get_params
