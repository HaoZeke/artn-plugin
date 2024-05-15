submodule(m_artn_data)set_data_routines
  use precision
  use m_error
  implicit none

contains

  !! Setter functions for variables in m_artn_data, the generic name is `set_data`

  !! integer
  module function set_data_int( name, val )result(ierr)
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "natoms"      );  natoms      = val
    case( "nevalf"      );  nevalf      = val
    case( "nevalf_min1" );  nevalf_min1 = val
    case( "nevalf_min2" );  nevalf_min2 = val
    case( "nevalf_sad"  );  nevalf_sad  = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_data_int(): "//name )
    end select
  end function set_data_int

  !! real
  module function set_data_real( name, val )result(ierr)
    use units, only: convert_param
    character(*), intent(in) :: name
    real(DP), intent(in) :: val
    integer :: ierr
    real(DP) :: converted_val
    ierr = 0
    converted_val = convert_param( name, val, ierr )
    if( ierr /= 0 ) then
       !! error happens when units are not set
       call err_write(__FILE__,__LINE__)
       return
    end if
    select case( name )
    case( "etot_step"   ); etot_step    = converted_val
    case( "delr_step"   ); delr_step    = converted_val
    case( "eigval_step" ); eigval_step  = converted_val
    case( "etot_init"   ); etot_init    = converted_val
    case( "delr_init"   ); delr_init    = converted_val
    case( "etot_sad"    ); etot_sad     = converted_val
    case( "delr_sad"    ); delr_sad     = converted_val
    case( "eigval_sad"  ); eigval_sad   = converted_val
    case( "etot_min1"   ); etot_min1    = converted_val
    case( "delr_min1"   ); delr_min1    = converted_val
    case( "eigval_min1" ); eigval_min1  = converted_val
    case( "etot_min2"   ); etot_min2    = converted_val
    case( "delr_min2"   ); delr_min2    = converted_val
    case( "eigval_min2" ); eigval_min2  = converted_val
    case( "tau_min2"    ); tau_min2     = converted_val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_data_real(): "//name )
    end select
  end function set_data_real

  !! bool
  module function set_data_bool( name, val )result(ierr)
    character(*), intent(in) :: name
    logical, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "has_error" ); has_error = val
    case( "has_sad"   ); has_sad   = val
    case( "has_min1"  ); has_min1  = val
    case( "has_min2"  ); has_min2  = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_data_bool(): "//name )
    end select
  end function set_data_bool

  !! string
  module function set_data_str( name, val )result(ierr)
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
       ! case( "errmsg" )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknwon name in set_data_str(): "//name )
       associate( x => val ); end associate
    end select
  end function set_data_str

  !! integer 1D
  module function set_data_int1d( name, dim, val )result(ierr)
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    integer, intent(in) :: val(dim)
    integer :: ierr
    ierr = 0
    select case( name )
    case( "typ_step" )
       if(allocated( typ_step ) )deallocate( typ_step  )
       allocate( typ_step, source = val)
    case( "typ_init" )
       if(allocated( typ_init ) )deallocate( typ_init  )
       allocate( typ_init, source = val)
    case( "typ_min1" )
       if(allocated( typ_min1 ) )deallocate( typ_min1  )
       allocate( typ_min1, source = val)
    case( "typ_min2" )
       if(allocated( typ_min2 ) )deallocate( typ_min2  )
       allocate( typ_min2, source = val)
    case( "typ_sad"  )
       if(allocated( typ_sad  ) )deallocate( typ_sad   )
       allocate( typ_sad , source = val)
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknwon name in set_data_int1d(): "//name )
    end select
  end function set_data_int1d

  !! real 1D
  module function set_data_real1d( name, dim, val )result(ierr)
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    real(DP), intent(in) :: val(dim)
    integer :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_data_real1d(): "//name )
       associate( x=> val );end associate
    end select
  end function set_data_real1d

  !! real 2D
  module function set_data_real2d( name, dim1, dim2, val )result(ierr)
    character(*), intent(in) :: name
    integer, intent(in) :: dim1, dim2
    real(DP), intent(in) :: val(dim1, dim2)
    integer :: ierr
    ierr = 0
    select case( name )
    case( "lat"        )
       if( dim1 /= 3 .or. dim2 /= 3 ) then
          ierr = ERR_OTHER
          call err_set(ERR_OTHER, __FILE__, __LINE__,msg="lat requires dimesnions 3x3!")
          return
       end if
       lat(:,:) = val
    case( "tau_step"   )
       if( allocated( tau_step  ))deallocate( tau_step  )
       allocate( tau_step  , source = val)
    case( "force_step" )
       if( allocated( force_step))deallocate( force_step)
       allocate( force_step, source = val)
    case( "eigen_step" )
       if( allocated( eigen_step))deallocate( eigen_step)
       allocate( eigen_step, source = val)
    case( "tau_init"   )
       if( allocated( tau_init  ))deallocate( tau_init  )
       allocate( tau_init  , source = val)
    case( "push_init"  )
       if( allocated( push_init ))deallocate( push_init )
       allocate( push_init , source = val)
    case( "tau_sad"    )
       if( allocated( tau_sad   ))deallocate( tau_sad   )
       allocate( tau_sad   , source = val)
    case( "eigen_sad"  )
       if( allocated( eigen_sad ))deallocate( eigen_sad )
       allocate( eigen_sad , source = val)
    case( "tau_min1"   )
       if( allocated( tau_min1  ))deallocate( tau_min1  )
       allocate( tau_min1  , source = val)
    case( "tau_min2"   )
       if( allocated( tau_min2  ))deallocate( tau_min2  )
       allocate( tau_min2  , source = val)
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_data_real2d(): "//name )
    end select
  end function set_data_real2d



  !> @details
  !! general C setter for variables from `m_artn_data`
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_data( const char * const name, const int crank, const int* csize, const void *cval );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function set_cdata( cname, crank, csize, cval ) result(cerr)bind(C,name="set_data")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char, c2f_string
    use m_datainfo
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ), value :: crank
    integer( c_int ), dimension(crank) :: csize
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    ! integer( c_int ), pointer :: dsize(:)
    real( c_double ), pointer :: rptr, r2ptr(:)
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

    dtype = get_artn_dtype( fname )
    drank = get_artn_drank( fname )

    !! check if input rank and expected rank are equal
    if( int(crank) .ne. drank ) then
       write(msg, '(a,1x,i0,1x,a,1x,i0)') ". Expected:", drank, "Got:", int(crank)
       call err_set(ERR_DRANK, __FILE__, __LINE__, msg="Invalid data rank for name: "//fname//trim(msg) )
       call err_write(__FILE__,__LINE__ )
       cerr = int( ERR_DRANK, c_int )
       return
    end if

    !! the size can only be checked once artn main routine is called (need info of nat)

    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, iptr )
          ! write(*,*) iptr
          cerr = int( set_data_int( fname, int(iptr)), c_int )
       case( 1 )
          call c_f_pointer( cval, i1ptr, shape=[csize] )
          ! write(*,*) i1ptr
          cerr = int( set_data_int1d(fname, csize(1), int(i1ptr) ), c_int)
       case default
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__,__LINE__,msg="unsupported data rank for name: "//fname )
          return
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, rptr )
          ! write(*,*) rptr
          cerr = int( set_data_real(fname, real(rptr, DP) ), c_int)
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape=[csize] )
          ! write(*,*) r2ptr
          cerr = int( set_data_real2d( fname, csize(1), csize(2), real(r2ptr, DP) ), c_int )
       case default
          write(msg, "(i0)") drank
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__, __LINE__, msg="unsupported data rank for name: "//fname )
          return
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, bptr )
       ! write(*,*) bptr
       cerr = int( set_data_bool(fname, logical(bptr)), c_int)

    case( ARTN_DTYPE_STR )
       allocate(strval, source = c2f_string(cval) )
       ! write(*,*) strval
       cerr = int( set_data_str( fname, strval), c_int )

    case default
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="unknown variable name: "//fname )
       cerr = int( ERR_VARNAME, c_int )
       return
    end select

    deallocate( fname )
  end function set_cdata


end submodule set_data_routines
