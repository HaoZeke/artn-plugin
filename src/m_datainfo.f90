module m_datainfo

  !! contains information about params and data (type, rank, size)
  use artn_params
  use m_artn_data
  use precision
  use m_error
  implicit none

  private
  public :: get_artn_dtype, get_artn_drank, get_artn_dsize
  public :: get_dtype_val, get_dtype_str

  public :: &
       ARTN_DTYPE_UNKNOWN, &
       ARTN_DTYPE_INT, &
       ARTN_DTYPE_REAL, &
       ARTN_DTYPE_BOOL, &
       ARTN_DTYPE_STR




  !! artn data type encoders
  integer, parameter :: &
       ARTN_DTYPE_UNKNOWN = -1, &
       ARTN_DTYPE_INT     = 1, &
       ARTN_DTYPE_REAL    = 2, &
       ARTN_DTYPE_BOOL    = 3, &
       ARTN_DTYPE_STR     = 4


  !!===========================================
  !! private namelists used to group variables by type and rank,
  !! for easier handling
  !!
  !!
  !! -- variables grouped by datatype::
  !! all integers
  namelist/nml_dtype_int/&
                                !! input params
       verbose, zseed, nperp, nevalf_max, ninit, neigen, lanczos_max_size, lanczos_min_size, &
       nsmooth, nnewchance, nrelax_print, restart_freq, nperp_limitation, push_ids, &

                                !! runtime params
       iartn, istep, iinit, iperp, ieigen, irelax, iover, inewchance, ismooth, nlanc, &
       ifound, isearch, ifails, nperp_step, nmin, nsaddle, fpush_factor, called_from, &

                                !! m_artn_data
       natoms, nevalf, nevalf_min1, nevalf_min2, nevalf_sad, typ_step, typ_init, typ_min1, &
       typ_min2, typ_sad


  !! all real
  namelist/nml_dtype_real/&
                                !! input params
       push_dist_thr, forc_thr, eigval_thr, delr_thr, lanczos_eval_conv_thr, push_step_size, push_over, &
       push_step_size_per_atom, lanczos_disp, eigen_step_size, etot_diff_limit, alpha_mix_cr, push_add_const, &

                                !! runtime params
       delr_vec, push, eigenvec, force_old, push_initial_vector, debrief, &

                                !! m_artn_data
       lat, tau_step, force_step, eigen_step, etot_step, delr_step, eigval_step, tau_init, &
       push_init, etot_init, delr_init, etot_sad, delr_sad, eigval_sad, tau_sad, eigen_sad, &
       etot_min1, delr_min1, eigval_min1, tau_min1, etot_min2, delr_min2, eigval_min2, tau_min2

  !! all bool
  namelist/nml_dtype_bool/&
                                !! input params
       lpush_final, lrestart, lrelax, lmove_nextmin, lserialize_output, lanczos_at_min, &
       lanczos_always_random, lnperp_limitation, &

                                !! runtime params
       linit, lperp, leigen, llanczos, lbasin, lpush_over, lrelax, in_lanczos_at_min, lbackward, &
       lend, luser_choose_per_atom, lserialize_input, lserialize_output, &

                                !! m_artn_data
       has_error, has_sad, has_min1, has_min2

  !! all strings
  namelist/nml_dtype_str/&
                                !! input params
       engine_units, push_mode, converge_property, push_guess, eigenvec_guess, filin, filout, &
       initpfname, eigenfname, restartfname, struc_format_out, prefix_min, prefix_sad,        &

                                !! runtime params
       elements, error_message, words, &
       errmsg  !! from m_error

                                !! m_artn_data

  !! -- variables grouped by rank (if rank>0)
  !! drank=1
  namelist/nml_drank_1/&
                                !! input params
       nperp_limitation, push_ids, &

                                !! runtime params
       elements, &

                                !! m_artn_data
       typ_step, typ_init, typ_min1, typ_min2, typ_sad


  !! drank=2
  namelist/nml_drank_2/&
                                !! input params
       push_add_const, &
                                !! runtime params
       delr_vec, push, eigenvec, force_old, push_initial_vector, &

                                !! m_artn_data
       lat, tau_step, force_step, eigen_step, tau_init, push_init, tau_sad, eigen_sad, tau_min1, tau_min2

  !! end of helper namelists
  !!===========================================

contains


  !> @details return the values for dtype encoders
  !! This is to avoid manual copying in interfaces.
  function get_dtype_val( name )result( val )
    character(*), intent(in) :: name
    integer :: val
    val=-999
    select case( name )
    case( "ARTN_DTYPE_UNKNOWN" ); val= ARTN_DTYPE_UNKNOWN
    case( "ARTN_DTYPE_INT"  ); val = ARTN_DTYPE_INT
    case( "ARTN_DTYPE_REAL" ); val = ARTN_DTYPE_REAL
    case( "ARTN_DTYPE_BOOL" ); val = ARTN_DTYPE_BOOL
    case( "ARTN_DTYPE_STR"  ); val = ARTN_DTYPE_STR
    end select
  end function get_dtype_val
  !! C wrapper
  function get_dtype_cval( cname )result(cval)bind(C,name="get_dtype_val")
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    use m_tools, only: c2f_char
    character(len=1,kind=c_char), intent(in) :: cname(*)
    integer( c_int ) :: cval
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    cval = int( get_dtype_val(fname), kind=c_int )
    deallocate( fname )
  end function get_dtype_cval


  !> @details return the string corresponding to dtype encoder value
  function get_dtype_str( val )result(str)
    implicit none
    integer, intent(in) :: val
    character(len=10) :: str
    select case( val )
    case( ARTN_DTYPE_UNKNOWN ); str="unknown"
    case( ARTN_DTYPE_INT     ); str="int"
    case( ARTN_DTYPE_REAL    ); str="real"
    case( ARTN_DTYPE_BOOL    ); str="bool"
    case( ARTN_DTYPE_STR     ); str="str"
    case default;               str="invalid"
    end select
  end function get_dtype_str
  !! C wrapper
  function get_dtype_cstr( cval )result( cstr )bind(C,name="get_dtype_str")
    use, intrinsic :: iso_c_binding, only: c_int, c_ptr
    use m_tools, only: f2c_string
    integer( c_int ), value, intent(in) :: cval
    type( c_ptr ) :: cstr
    character(len=10) :: fstr
    fstr = get_dtype_str( int(cval) )
    cstr = f2c_string(trim(fstr))
  end function get_dtype_cstr




  !> @details
  !! return value of expected data type of variable <name>, even if variable is not set.
  !! If variable <name> is unknown, dtype has a negative value.
  function get_artn_dtype( name ) result( dtype )
    implicit none
    character(*), intent(in) :: name
    integer :: dtype

    character(len=64) :: tmpstr
    integer :: ios

    select case( name )
       !! some special case, since VOID etc cannot be put into nml because they are PARAMETER
    case("VOID", "INIT", "PERP", "EIGN", "LANC", "RELX", "OVER", "SMTH"); dtype = ARTN_DTYPE_INT

    case default

       !! test int
       tmpstr = "&nml_dtype_int "//name//" /"
       dtype = ARTN_DTYPE_INT
       read( tmpstr, nml=nml_dtype_int, iostat=ios )
       if( ios == 0 ) return

       !! test real
       tmpstr = "&nml_dtype_real "//name//" /"
       dtype = ARTN_DTYPE_REAL
       read( tmpstr, nml=nml_dtype_real, iostat=ios )
       if( ios == 0 ) return

       !! test bool
       tmpstr = "&nml_dtype_bool "//name//" /"
       dtype = ARTN_DTYPE_BOOL
       read( tmpstr, nml=nml_dtype_bool, iostat=ios )
       if( ios == 0 ) return

       !! test str
       tmpstr = "&nml_dtype_str "//name//" /"
       dtype = ARTN_DTYPE_STR
       read( tmpstr, nml=nml_dtype_str, iostat=ios )
       if( ios == 0 ) return

       !! dtype is not known
       dtype = ARTN_DTYPE_UNKNOWN
    end select

  end function get_artn_dtype
  !> @details
  !! C-wrapper for get_artn_dtype
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_artn_dtype( const char *name );
  !!~~~~~~~~~~~~~~~~
  function get_artn_ctype( cname )result( ctype )bind(C, name="get_artn_dtype")
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ) :: ctype
    ctype = int( get_artn_dtype( c2f_char(cname)), c_int )
  end function get_artn_ctype



  !> @details
  !! Return value of expected rank of variable <name>, even if variable is not set/allocated.
  !! If variable is unknown, this will return drank=0
  function get_artn_drank( name ) result( drank )
    implicit none
    character(*), intent(in) :: name
    integer :: drank

    character(len=64) :: tmpstr
    integer :: ios

    !! test rank 1
    tmpstr = "&nml_drank_1 "//name//" /"
    drank = 1
    read( tmpstr, nml=nml_drank_1, iostat=ios )
    if( ios == 0 ) return

    !! test rank 2
    tmpstr = "&nml_drank_2 "//name//" /"
    drank = 2
    read( tmpstr, nml=nml_drank_2, iostat=ios )
    if( ios == 0 ) return

    !! variable unknown, or rank is 0
    drank = 0
  end function get_artn_drank
  !> @details
  !! C wrapper for get_artn_drank
  !!~~~~~~~~~~~~~~{.c}
  !! int get_artn_drank( const char *name );
  !!~~~~~~~~~~~~~~
  function get_artn_crank( cname )result( crank )bind(C, name="get_artn_drank")
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    integer( c_int ) :: crank
    crank = int( get_artn_drank( c2f_char(cname)), c_int )
  end function get_artn_crank




  !> @details
  !! return actual size of variable <name>, if varibale not allocated return negative ierr.
  function get_artn_dsize( name, dsize )result(ierr)
    use units, only: size_i1d, size_r2d
    implicit none
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: dsize(:)
    integer :: ierr
    integer :: drank
    if( get_artn_dtype(name) < 0 ) then
       ierr = -1
       call err_set( ierr, __FILE__,__LINE__,msg="unknwon variable in get_artn_dsize: "//name)
       call err_write(__FILE__,__LINE__)
       return
    end if
    drank = get_artn_drank( name )
    allocate( dsize(1:drank),source=0)
    ierr = 0
    if( drank == 0 ) return

    select case( name )

       !! -- input params
       !! rank=1
    case( "push_ids"         ); dsize(1) = size_i1d( push_ids )
    case( "nperp_limitation" ); dsize(1) = size_i1d( nperp_limitation )
       !! rank=2
    case( "push_add_const" )
       dsize(1) = size_r2d( push_add_const, 1 )
       dsize(2) = size_r2d( push_add_const, 2 )
    ! case( "push_init" )
    !    dsize(1) = size_r2d(push_init, 1)
    !    dsize(2) = size_r2d(push_init, 2)
    ! case( "eigenvec_init" )
    !    dsize(1) = size_r2d(eigenvec_init, 1)
    !    dsize(2) = size_r2d(eigenvec_init, 2)

       !! -- runtime params
       !! rank=1
    ! case( "elements" ); dsize(1) =
       !! rank=2
    case( "delr_vec"  ); dsize(1) = size_r2d( delr_vec ,1); dsize(2) = size_r2d( delr_vec ,2)
    case( "push"      ); dsize(1) = size_r2d( push     ,1); dsize(2) = size_r2d( push     ,2)
    case( "eigenvec"  ); dsize(1) = size_r2d( eigenvec ,1); dsize(2) = size_r2d( eigenvec ,2)
    case( "force_old" ); dsize(1) = size_r2d( force_old,1); dsize(2) = size_r2d( force_old,2)
    case( "push_initial_vector" )
       dsize(1) = size_r2d( push_initial_vector,1)
       dsize(2) = size_r2d( push_initial_vector,2)

       !! -- m_artn_data
       !! rank=1
    case("typ_step"); dsize(1) = size_i1d( typ_step )
    case("typ_init"); dsize(1) = size_i1d( typ_step )
    case("typ_min1"); dsize(1) = size_i1d( typ_step )
    case("typ_min2"); dsize(1) = size_i1d( typ_step )
    case("typ_sad" ); dsize(1) = size_i1d( typ_step )
       !! rank=2
    case("lat"       ); dsize(1) = 3; dsize(2) = 3
    case("tau_step"  ); dsize(1) = size_r2d( tau_step  , 1); dsize(2) = size_r2d( tau_step  , 2)
    case("force_step"); dsize(1) = size_r2d( force_step, 1); dsize(2) = size_r2d( force_step, 2)
    case("eigen_step"); dsize(1) = size_r2d( eigen_step, 1); dsize(2) = size_r2d( eigen_step, 2)
    case("tau_init"  ); dsize(1) = size_r2d( tau_init  , 1); dsize(2) = size_r2d( tau_init  , 2)
    case("push_init" ); dsize(1) = size_r2d( push_init , 1); dsize(2) = size_r2d( push_init , 2)
    case("tau_sad"   ); dsize(1) = size_r2d( tau_sad   , 1); dsize(2) = size_r2d( tau_sad   , 2)
    case("eigen_sad" ); dsize(1) = size_r2d( eigen_sad , 1); dsize(2) = size_r2d( eigen_sad , 2)
    case("tau_min1"  ); dsize(1) = size_r2d( tau_min1  , 1); dsize(2) = size_r2d( tau_min1  , 2)
    case("tau_min2"  ); dsize(1) = size_r2d( tau_min2  , 1); dsize(2) = size_r2d( tau_min2  , 2)
    case default
       ierr = ERR_OTHER
       call err_set(ierr, __FILE__,__LINE__,msg="unknown error in get_artn_dsize for name: "//name )
       return
    end select
  end function get_artn_dsize
  !> @details
  !! C-wrapper to get_artn_dsize
  !!~~~~~~~~~~~~~~{.c}
  !! int get_artn_dsize( const char *name, int **csize );
  !!~~~~~~~~~~~~~~
  function get_artn_csize( cname, csize )result( cerr )bind(C, name="get_artn_dsize")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(inout) :: csize
    integer( c_int ) :: cerr
    integer, allocatable :: fsize(:)
    integer(c_int), pointer :: i1d(:)
    csize = c_null_ptr
    cerr = int( get_artn_dsize( c2f_char(cname), fsize ), c_int )
    if( cerr /= 0_c_int ) then
       call err_write(__FILE__, __LINE__)
       return
    end if
    allocate( i1d, source=int(fsize, c_int))
    csize = c_loc( i1d(1) )
  end function get_artn_csize

end module m_datainfo
