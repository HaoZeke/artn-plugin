submodule( artn_params )get_params
  use m_error
  use units
  use m_tools
  use precision
  use, intrinsic :: iso_c_binding
  implicit none


  !!====================================
  !! functionality to extract the user-accessible variables from artn_params_mod.
  !! The user-accessible variables are the ones defined in
  !! artn_parameters namelist, plus push_init, eigenvec_init, and filin
  !!====================================

  interface
     function c_malloc(size) bind(C, name="malloc")
       import c_ptr, c_size_t
       integer(c_size_t), intent(in), value :: size
       type(c_ptr) :: c_malloc
     end function c_malloc
  end interface

contains


  !! helper functions

  !> @details
  !! return value of expected data type of variable <name>, even if variable is not set.
  !! If variable <name> is unknown, dtype has a negative value.
  module function get_param_dtype( name )result( dtype )
    character(*), intent(in) :: name
    integer :: dtype
    select case( name )
    case( &
         "verbose",          &
         "ninit",            &
         "neigen",           &
         "nperp",            &
         "lanczos_max_size", &
         "lanczos_min_size", &
         "nsmooth",          &
         "nevalf_max",       &
         "zseed",            &
         "nnewchance",       &
         "nrelax_print",     &
         "restart_freq",     &
         "push_ids",         &
         "nperp_limitation"  &
         ); dtype = ARTN_DTYPE_INT

    case( &
         "push_dist_thr",           &
         "forc_thr",                &
         "eigval_thr",              &
         "delr_thr",                &
         "lanczos_eval_conv_thr",   &
         "push_step_size",          &
         "push_step_size_per_atom", &
         "lanczos_disp",            &
         "eigen_step_size",         &
         "etot_diff_limit",         &
         "alpha_mix_cr",            &
         "push_add_const"           &
         ); dtype = ARTN_DTYPE_REAL

    case( &
         "lpush_final",           &
         "lrestart",              &
         "lrelax",                &
         "lmove_nextmin",         &
         "lserialize_output",     &
         "lanczos_at_min",        &
         "lanczos_always_random", &
         "lnperp_limitation"      &
         ); dtype = ARTN_DTYPE_BOOL

    case(&
         "engine_units",      &
         "push_mode",         &
         "converge_property", &
         "push_guess",        &
         "eigenvec_guess",    &
         "filin",             &
         "filout",            &
         "initpfname",        &
         "eigenfname",        &
         "restartfname",      &
         "struc_format_out",  &
         "prefix_min",        &
         "prefix_sad"         &
         ); dtype = ARTN_DTYPE_STR

    case default
       dtype = ARTN_DTYPE_UNKNOWN
    end select
  end function get_param_dtype
  !> @details
  !! C-wrapper for get_param_dtype
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_param_dtype( const char *name );
  !!~~~~~~~~~~~~~~~~
  function get_cparam_dtype( cname )result( ctype )bind(C, name="get_param_dtype")
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ) :: ctype
    ctype = int( get_param_dtype( c2f_char(cname)), c_int )
  end function get_cparam_dtype


  !> @details
  !! Return value of expected rank of variable <name>, even if variable is not set/allocated.
  !! If variable is unknown, this will return drank=0
  module function get_param_drank( name )result( drank )
    character(*), intent(in) :: name
    integer :: drank
    select case( name )
    case( &
         "nperp_limitation", &
         "push_ids" &
         ); drank = 1
    case( &
         "push_add_const", &
         "push_init",      &
         "eigenvec_init" &
         ); drank = 2
    case default
       drank = 0
    end select
  end function get_param_drank
  !> @details
  !! C wrapper for get_param_drank
  !!~~~~~~~~~~~~~~{.c}
  !! int get_param_drank( const char *name );
  !!~~~~~~~~~~~~~~
  function get_cparam_drank( cname )result( crank )bind(C, name="get_param_drank")
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ) :: crank
    crank = int( get_param_drank( c2f_char(cname)), c_int )
  end function get_cparam_drank


  !> @details
  !! return actual size of variable <name>, if varibale not allocated return negative ierr.
  module function get_param_dsize( name, dsize )result(ierr)
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: dsize(:)
    integer :: ierr
    integer :: drank
    if( get_param_dtype(name) < 0 ) then
       ierr = -1
       call err_set( ierr, __FILE__,__LINE__,msg="unknwon variable in get_param_dsize: "//name)
       call err_write(__FILE__,__LINE__)
       return
    end if
    drank = get_param_drank( name )
    allocate( dsize(1:drank),source=0)
    ierr = 0
    if( drank == 0 ) return

    select case( name )
    case( "push_ids"         ); dsize(1) = size_i1d( push_ids )
    case( "nperp_limitation" ); dsize(1) = size_i1d( nperp_limitation )
    case( "push_add_const"   )
       dsize(1) = size_r2d( push_add_const, 1 )
       dsize(2) = size_r2d( push_add_const, 2 )
    ! case( "push_init" )
    !    dsize(1) = size_r2d(push_init, 1)
    !    dsize(2) = size_r2d(push_init, 2)
    ! case( "eigenvec_init" )
    !    dsize(1) = size_r2d(eigenvec_init, 1)
    !    dsize(2) = size_r2d(eigenvec_init, 2)
    case default
       ierr = ERR_OTHER
       call err_set(ierr, __FILE__,__LINE__,msg="unknown error in get_param_dsize for name: "//name )
       return
    end select
    if( any(dsize .le. 0)) ierr = -2
  end function get_param_dsize
  !!~~~~~~~~~~~~~~{.c}
  !! int get_param_dsize( const char *name, int **csize );
  !!~~~~~~~~~~~~~~
  function get_cparam_dsize( cname, csize )result( cerr )bind(C, name="get_param_dsize")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(inout) :: csize
    integer( c_int ) :: cerr
    integer, allocatable :: fsize(:)
    integer(c_int), pointer :: i1d(:)
    csize = c_null_ptr
    cerr = int( get_param_dsize( c2f_char(cname), fsize ), c_int )
    if( cerr /= 0_c_int ) then
       call err_write(__FILE__, __LINE__)
       return
    end if
    allocate( i1d, source=int(fsize, c_int))
    csize = c_loc( i1d(1) )
  end function get_cparam_dsize




  !! fortran version
  module subroutine get_param_int( name, val, ierr )
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "verbose"          ); val = verbose
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
    case( "lpush_final"           ); val = lpush_final
    case( "lrestart"              ); val = lrestart
    case( "lrelax"                ); val = lrelax
    case( "lmove_nextmin"         ); val = lmove_nextmin
    case( "lserialize_output"     ); val = lserialize_output
    case( "lanczos_at_min"        ); val = lanczos_at_min
    case( "lanczos_always_random" ); val = lanczos_always_random
    case( "lnperp_limitation"     ); val = lnperp_limitation
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
    case( "engine_units"      ); allocate( val, source = trim(engine_units) )
    case( "push_mode"         ); allocate( val, source = trim(push_mode) )
    case( "converge_property" ); allocate( val, source = trim(converge_property) )
    case( "push_guess"        ); allocate( val, source = trim(push_guess) )
    case( "eigenvec_guess"    ); allocate( val, source = trim(eigenvec_guess) )
    case( "filin"             ); allocate( val, source = trim(filin) )
    case( "filout"            ); allocate( val, source = trim(filout) )
    case( "initpfname"        ); allocate( val, source = trim(initpfname) )
    case( "eigenfname"        ); allocate( val, source = trim(eigenfname) )
    case( "restartfname"      ); allocate( val, source = trim(restartfname) )
    case( "struc_format_out"  ); allocate( val, source = trim(struc_format_out) )
    case( "prefix_min"        ); allocate( val, source = trim(prefix_min) )
    case( "prefix_sad"        ); allocate( val, source = trim(prefix_sad) )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_str(): "//name )
    end select
  end subroutine get_param_str
  module subroutine get_param_int1d( name, val, ierr )
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: val(:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "push_ids"         ); allocate(val, source = push_ids )
    case( "nperp_limitation" ); allocate(val, source = nperp_limitation )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_int1d(): "//name )
    end select
  end subroutine get_param_int1d
  module subroutine get_param_real2d( name, val, ierr )
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:,:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "push_add_const" ); allocate( val, source = push_add_const )
    ! case( "push_init" ); allocate( val, source = push_init )
    ! case( "eigenvec_init" ); allocate( val, source = eigenvec_init )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_real2d(): "//name )
    end select
  end subroutine get_param_real2d




  !> @details
  !! wrapper to get_param_int. Visible to C as "get_param_int()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int get_param_int( const char *name, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  function get_cparam_int( cname, cerr )result(cval)bind(C,name="get_param_int")
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
  !! wrapper to get_param_int1d. Visible to C as "get_param_int1d()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int* get_param_int1d( const char *name, int* dim, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  function get_cparam_int1d( cname, dim, cerr )result(cval)bind(C,name="get_param_int1d")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ), intent(out) :: dim
    integer( c_int ), intent(out) :: cerr
    type( c_ptr ) :: cval
    character(:), allocatable :: fname
    integer :: ierr
    integer, allocatable :: fval(:)
    integer( c_int ), pointer :: i1ptr(:)
    allocate( fname, source=c2f_char(cname) )
    call get_param_int1d( fname, fval, ierr )
    cerr = int( ierr, c_int )
    allocate( i1ptr, source=int(fval, c_int) )
    dim = size(fval)
    cval = c_loc( i1ptr(1))
    deallocate( fname, fval )
  end function get_cparam_int1d



  !> @details
  !! wrapper to get_param_real. Visible to C as "get_param_real()"
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! double get_param_real( const char *name, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  !!
  function get_cparam_real( cname, cerr )result(cval)bind(C,name="get_param_real")
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
  !! wrapper to get_param_real2d. Cisible to C as "get_param_real2d()".
  !! Returns a 1D array that needs to be reshaped!
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! double * get_param_real2d( const char *name, int * dim1, int* dim2, int* cerr );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function get_cparam_real2d( cname, dim1, dim2, cerr )result(cval)bind(C,name="get_param_real2d")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ), intent(out) :: dim1, dim2
    integer( c_int ), intent(out) :: cerr
    type( c_ptr ) :: cval
    character(:), allocatable :: fname
    real(DP), allocatable :: fval(:,:)
    real( c_double ), pointer :: r2ptr(:,:)
    integer :: ierr
    allocate( fname, source=c2f_char(cname) )
    call get_param_real2d( fname, fval, ierr )
    cerr = int( ierr, c_int )
    allocate( r2ptr, source=fval )
    dim1 = size(fval, 1); dim2 = size(fval, 2)
    cval = c_loc( r2ptr(1,1) )
    deallocate( fname )
    deallocate( fval )
  end function get_cparam_real2d




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
  function get_cparam( cname, cval )result(cerr)bind(C,name="get_param")
    use, intrinsic :: iso_c_binding
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(:), allocatable :: fname, fstr
    integer :: ierr, dtype, drank
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

    !! get drank
    drank = get_param_drank( fname )
    write(*,*) "drank:", drank

    !! decide what to do based on dtype
    select case( dtype )
    case( ARTN_DTYPE_INT )

       select case( drank )
       case( 0 )
          call get_param_int( fname, fint, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( iptr, source=int(fint, c_int) )
          cval = c_loc( iptr )

       case( 1 )
          call get_param_int1d( fname, fint1d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( i1ptr, source=int(fint1d, c_int) )
          cval = c_loc( i1ptr(1) )

       case default
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for int")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select


    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call get_param_real( fname, freal, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( rptr, source=real(freal,c_double) )
          cval = c_loc( rptr )
       case( 2 )
          call get_param_real2d( fname, freal2d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( r2ptr, source = real(freal2d, c_double) )
          cval = c_loc( r2ptr(1,1) )
          deallocate( freal2d )

       case default
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for real")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select

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
       call get_param_str( fname, fstr, ierr )
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




  !! local functions
  !! calling size for unallocated stuff can give undefined (random) result, so wrap them
  !! to return size=0 for unallocated
  function lenstr_local( str )result(l)
    character(:), allocatable, intent(in) :: str
    integer :: l
    l = 0
    if( .not. allocated(str)) return
    l = len_trim( str )
  end function lenstr_local
  function size_i1d( i1d )result(l)
    integer, allocatable, intent(in) :: i1d(:)
    integer :: l
    l = 0
    if( .not. allocated(i1d)) return
    l = size( i1d )
  end function size_i1d
  function size_r1d( r1d )result(l)
    real(DP), allocatable, intent(in) :: r1d(:)
    integer :: l
    l = 0
    if( .not. allocated(r1d)) return
    l = size( r1d )
  end function size_r1d
  function size_r2d( r2d, ax )result(l)
    real(DP), allocatable, intent(in) :: r2d(:,:)
    integer, intent(in) :: ax
    integer :: l
    l = 0
    if( .not. allocated(r2d)) return
    l = size( r2d, ax )
  end function size_r2d


  subroutine artn_list_extract_param()bind(C,name="artn_list_extract_param")
    write(*,*) "List of parameters which can be extracted:"
    write(*,'(3x, "name                   :",3x,a8,3x,a4,3x,a)') "type", "rank", "size"
    write(*,*) repeat('=',80)
    write(*,'(3x, "alpha_mix_cr           :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "converge_property      :",3x,a8,3x,a4,3x,a)') "string", "0", "any"
    write(*,'(3x, "delr_thr               :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenfname             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigen_step_size        :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenvec_guess         :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigenvec_init          :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,nat); python [nat,3]"
    write(*,'(3x, "eigval_thr             :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "engine_units           :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "etot_diff_limit        :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "filout                 :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "filin                  :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "forc_thr               :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "initpfname             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "lanczos_always_random  :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lanczos_at_min         :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lanczos_disp           :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "lanczos_eval_conv_thr  :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "lanczos_max_size       :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "lanczos_min_size       :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "lmove_nextmin          :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lnperp_limitation      :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lpush_final            :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lrelax                 :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lrestart               :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "nevalf_max             :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "neigen                 :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "ninit                  :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nnewchance             :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nperp                  :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nperp_limitation       :",3x,a8,3x,a4,3x,a)') "integer", "1", "any"
    write(*,'(3x, "nrelax_print           :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nsmooth                :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "push_add_const         :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (4,nat); python [nat,4]"
    write(*,'(3x, "push_dist_thr          :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_guess             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "push_ids               :",3x,a8,3x,a4,3x,a)') "integer", "1", ".le. natoms"
    write(*,'(3x, "push_init              :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,nat); python [nat,3]"
    write(*,'(3x, "push_mode              :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 5"
    write(*,'(3x, "push_over              :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_step_size         :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_step_size_per_atom:",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "prefix_sad             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "prefix_min             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "restart_freq           :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "restartfname           :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "struc_format_out       :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 10"
    write(*,'(3x, "verbose                :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "zseed                  :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
  end subroutine artn_list_extract_param

end submodule get_params
