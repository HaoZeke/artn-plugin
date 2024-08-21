submodule(m_artn_data)get_data_routines
  use precision
  use m_error
  use units
  use m_tools, only: c2f_char
  use m_datainfo
  implicit none

contains

  !! Getter routines for variables in m_artn_data, the generic routine name is `get_data`

  !! integer
  module subroutine get_data_int( name, val, ierr )
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "natoms"      ); val = natoms
    case( "nevalf"      ); val = nevalf
    case( "nevalf_min1" ); val = nevalf_min1
    case( "nevalf_min2" ); val = nevalf_min2
    case( "nevalf_sad"  ); val = nevalf_sad
    case default
       ierr = ERR_VARNAME
       call err_set(ierr, __FILE__,__LINE__,msg="unknown name in get_data_int(): "//name )
    end select
  end subroutine get_data_int

  !! real
  module subroutine get_data_real( name, val, ierr )
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer, intent(out) :: ierr
    real(DP) :: converted_val
    ierr = 0
    select case( name )
    case( "etot_step"   ); converted_val = etot_step
    case( "delr_step"   ); converted_val = delr_step
    case( "eigval_step" ); converted_val = eigval_step
    case( "etot_init"   ); converted_val = etot_init
    case( "delr_init"   ); converted_val = delr_init
    case( "etot_sad"    ); converted_val = etot_sad
    case( "delr_sad"    ); converted_val = delr_sad
    case( "eigval_sad"  ); converted_val = eigval_sad
    case( "etot_min1"   ); converted_val = etot_min1
    case( "delr_min1"   ); converted_val = delr_min1
    case( "eigval_min1" ); converted_val = eigval_min1
    case( "etot_min2"   ); converted_val = etot_min2
    case( "delr_min2"   ); converted_val = delr_min2
    case( "eigval_min2" ); converted_val = eigval_min2
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_data_real(): "//name )
       call err_write(__FILE__,__LINE__)
       val = NAN_REAL
       return
    end select
    !! unconvert
    ! write(*,*) "converted", converted_val
    val = unconvert_param( name, converted_val, ierr )
    if( ierr /= 0 ) then
       !! error when units are not set
       call err_write(__FILE__,__LINE__)
       return
    end if
    ! write(*,*) "unconverted", val
  end subroutine get_data_real

  !! bool
  module subroutine get_data_bool( name, val, ierr )
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "has_error" ); val = has_error
    case( "has_sad"   ); val = has_sad
    case( "has_min1"  ); val = has_min1
    case( "has_min2"  ); val = has_min2
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_data_bool(): "//name )
    end select
  end subroutine get_data_bool

  !! string
  module subroutine get_data_str( name, val, ierr )
    use artn_params, only: error_message
    use m_error, only: errmsg
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
       !! the error messages are not stored in data,
       !! techincally one should call get_runparam for them ...
    case( "error_message" ); allocate( val, source=trim(error_message) )
    case( "errmsg" ); allocate( val, source=errmsg )
    case( "fname_sad" ); allocate( val, source=trim(fname_sad) )
    case( "fname_min1" ); allocate( val, source=trim(fname_min1) )
    case( "fname_min2" ); allocate( val, source=trim(fname_min2) )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_data_str(): "//name )
       allocate( val, source="n/a" )
    end select
  end subroutine get_data_str

  !! integer 1D
  module subroutine get_data_int1d( name, val, ierr )
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: val(:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "typ_step" ); ierr = assign_val1d( val, typ_step )
    case( "typ_init" ); ierr = assign_val1d( val, typ_init )
    case( "typ_min1" ); ierr = assign_val1d( val, typ_min1 )
    case( "typ_min2" ); ierr = assign_val1d( val, typ_min2 )
    case( "typ_sad"  ); ierr = assign_val1d( val, typ_sad )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_data_int1d(): "//name )
    end select
    if( ierr == ERR_DATA ) call err_set(ierr,__FILE__,__LINE__, msg="data does not exist: "//name)
  end subroutine get_data_int1d

  !! real 2D
  module subroutine get_data_real2d( name, val, ierr )
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:,:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "lat"        ); allocate( val, source = lat ) !! lat is not allocatable but dimension(3,3)
    case( "tau_step"   ); ierr = assign_val2d( val, tau_step )
    case( "force_step" ); ierr = assign_val2d( val, force_step)
    case( "eigen_step" ); ierr = assign_val2d( val, eigen_step)
    case( "tau_init"   ); ierr = assign_val2d( val, tau_init )
    case( "push_init"  ); ierr = assign_val2d( val, push_init)
    case( "tau_sad"    ); ierr = assign_val2d( val, tau_sad  )
    case( "eigen_sad"  ); ierr = assign_val2d( val, eigen_sad)
    case( "tau_min1"   ); ierr = assign_val2d( val, tau_min1 )
    case( "tau_min2"   ); ierr = assign_val2d( val, tau_min2 )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_data_real2d(): "//name )
    end select
    if( ierr == ERR_DATA ) call err_set(ierr,__FILE__,__LINE__, msg="data does not exist: "//name)
  end subroutine get_data_real2d



  !! data is not guaranteed to exist always, so these functions check
  !! if src is unallocated, return ierr and don't allocate val
  !! if src is allocated, allocate val with source=src
  function assign_val1d( val, src )result(ierr)
    use m_error, only: ERR_DATA
    implicit none
    integer, allocatable, intent(out) :: val(:)
    integer, allocatable, intent(in) :: src(:)
    integer :: ierr
    ierr = ERR_DATA
    if( .not. allocated(src) ) return
    allocate( val, source=src ); ierr = 0
  end function assign_val1d
  function assign_val2d( val, src )result(ierr)
    use m_error, only: ERR_DATA
    implicit none
    real(DP), allocatable, intent(out) :: val(:,:)
    real(DP), allocatable, intent(in) :: src(:,:)
    integer :: ierr
    ierr = ERR_DATA
    if( .not. allocated(src) ) return
    allocate( val, source=src ); ierr = 0
  end function assign_val2d




  !> @details
  !! general get_cdata for all types of variables in m_artn_data
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_data ( const char *name, void* cval );
  !!~~~~~~~~~~~~~~~~
  !!
  !! To cast the value, i.e. into double:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void *c_val;
  !! int cerr;
  !!
  !! if( !get_data( "eigval_sad", &c_val) ){
  !!    /* there is error */
  !!    err_write( __FILE__, __LINE__ );
  !! }
  !! /* read the double value from void* */
  !! double eigval_sad = *(double *) c_val;
  !! printf( "eigenvalue at saddle value: %f\n", eigval_sad );
  !!~~~~~~~~~~~~~~~~
  !!
  module function get_cdata( cname, cval )result(cerr)bind(C,name="get_data")
    use, intrinsic :: iso_c_binding
    use m_tools, only: f2c_string, c_malloc
    use m_datainfo
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
    dtype = get_artn_dtype( fname )
    ! write(*,*) "dtype:",dtype

    !! unknown dtype at this point is an error due to unknown variable
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       cerr = int( ERR_VARNAME, c_int )
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="Unknown variable name: "//fname )
       call err_write( __FILE__, __LINE__)
       return
    end if

    !! get drank
    drank = get_artn_drank( fname )
    ! write(*,*) "drank:", drank

    !! get dsize
    ierr = get_artn_dsize( fname, dsize )
    if( ierr /= 0 ) then
       cerr = int(ierr, c_int)
       call err_write( __FILE__, __LINE__)
       return
    end if
    ! write(*,*) "dsize", dsize

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
             call err_write(__FILE__,__LINE__)
             return
          end if
          iptr = int( fint, c_int )

       case( 1 )
          cval = c_malloc( c_sizeof(1_c_int)*int(dsize(1), c_size_t) )
          call c_f_pointer( cval, i1ptr, shape=[dsize(1)] )
          call get_data_int1d( fname, fint1d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call err_write(__FILE__,__LINE__)
             return
          end if
          i1ptr = int( fint1d, c_int )

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
             call err_write(__FILE__,__LINE__)
             return
          end if
          rptr = real(freal, c_double)

       case( 2 )
          cval = c_malloc( c_sizeof(1.0_c_double)*int(dsize(1)*dsize(2), c_size_t) )
          call c_f_pointer( cval, r2ptr, shape=[dsize(1), dsize(2)])
          call get_data_real2d( fname, freal2d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call err_write(__FILE__,__LINE__)
             return
          end if
          r2ptr = real( freal2d, c_double )

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
          call err_write(__FILE__,__LINE__)
          return
       end if
       bptr = logical(fbool, c_bool)

    case( ARTN_DTYPE_STR )
       call get_data_str( fname, fstr, ierr )
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
       cerr = int(ierr, c_int )
       return
    end select

    cerr = 0_c_int
    deallocate( fname )
    deallocate( dsize )
  end function get_cdata



  module subroutine artn_list_extract( )bind(C,name="artn_list_extract")
    !! write all variables that can be extracted from t_artn_data

    write(*,*) "List of variables which can be extracted from m_artn_data:"
    write(*,*) repeat('=',80)
    write(*,'(3x, "name              :",3x,a8,3x,a4,3x,a)') "type", "rank", "size"
    write(*,*) repeat('=',80)

    write(*, '(3x, "Information about the current run:")')
    write(*, '(3x,"has_error         :",3x,a8,3x,a4,3x,a )') "logical", "0","0"
    write(*, '(3x,"nevalf            :",3x,a8,3x,a4,3x,a )') "integer","0","0"
    write(*,*)
    write(*, '(3x,"Initial structure:")')
    write(*, '(3x,"natoms            :",3x,a8,3x,a4,3x,a )') "integer","0","0"
    write(*, '(3x,"lat               :",3x,a8,3x,a4,3x,a )') "real", "2","(3,3)"
    write(*, '(3x,"etot_init         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"typ_init          :",3x,a8,3x,a4,3x,a )') "integer","1","natoms"
    write(*, '(3x,"tau_init          :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"push_init         :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*,*)
    write(*, '(3x,"Saddle structure:")')
    write(*, '(3x,"has_sad           :",3x,a8,3x,a4,3x,a )') "logical", "0","0"
    write(*, '(3x,"etot_sad          :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"delr_sad          :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"eigval_sad        :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"typ_sad           :",3x,a8,3x,a4,3x,a )') "integer","1","natoms"
    write(*, '(3x,"tau_sad           :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"eigen_sad         :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"nevalf_sad        :",3x,a8,3x,a4,3x,a )') "integer","0","0"
    write(*, '(3x,"fname_sad         :",3x,a8,3x,a4,3x,a )') "char","0",":"
    write(*,*)
    write(*, '(3x,"Minimum1 structure:")')
    write(*, '(3x,"has_min1          :",3x,a8,3x,a4,3x,a )') "logical", "0","0"
    write(*, '(3x,"etot_min1         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"delr_min1         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"eigval_min1       :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"typ_min1          :",3x,a8,3x,a4,3x,a )') "integer","1","natoms"
    write(*, '(3x,"tau_min1          :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"eigen_min1        :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"nevalf_min1       :",3x,a8,3x,a4,3x,a )') "integer","0","0"
    write(*, '(3x,"fname_min1        :",3x,a8,3x,a4,3x,a )') "char","0",":"
    write(*,*)
    write(*, '(3x,"Minimum2 structure:")')
    write(*, '(3x,"has_min2          :",3x,a8,3x,a4,3x,a )') "logical", "0","0"
    write(*, '(3x,"etot_min2         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"delr_min2         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"eigval_min2       :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"typ_min2          :",3x,a8,3x,a4,3x,a )') "integer","1","natoms"
    write(*, '(3x,"tau_min2          :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"eigen_min2        :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"nevalf_min2       :",3x,a8,3x,a4,3x,a )') "integer","0","0"
    write(*, '(3x,"fname_min2        :",3x,a8,3x,a4,3x,a )') "char","0",":"
    write(*,*)
    write(*, '(3x,"Current step:")')
    write(*, '(3x,"etot_step         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"delr_step         :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"eigval_step       :",3x,a8,3x,a4,3x,a )') "real","0","0"
    write(*, '(3x,"typ_step          :",3x,a8,3x,a4,3x,a )') "integer","1","natoms"
    write(*, '(3x,"tau_step          :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"force_step        :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
    write(*, '(3x,"eigen_step        :",3x,a8,3x,a4,3x,a )') "real", "2","fortran (3,natoms); python [natoms,3]"
  end subroutine artn_list_extract


end submodule get_data_routines
