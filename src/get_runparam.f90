submodule( artn_params ) get_runparam_routines
  use precision
  use m_error
  implicit none

contains

  !! the runparams have good value only during the run, not before or after clean()

  module subroutine get_runparam_int( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "VOID" ); val = VOID
    case( "INIT" ); val = INIT
    case( "PERP" ); val = PERP
    case( "EIGN" ); val = EIGN
    case( "LANC" ); val = LANC
    case( "RELX" ); val = RELX
    case( "OVER" ); val = OVER
    case( "SMTH" ); val = SMTH
    case( "iartn"      ); val = iartn
    case( "istep"      ); val = istep
    case( "iinit"      ); val = iinit
    case( "iperp"      ); val = iperp
    case( "ieigen"     ); val = ieigen
    case( "irelax"     ); val = irelax
    case( "iover"      ); val = iover
    case( "inewchance" ); val = inewchance
    case( "ismooth"    ); val = ismooth
    case( "nlanc"      ); val = nlanc
    case( "ifound"     ); val = ifound
    case( "isearch"    ); val = isearch
    case( "ifails"     ); val = ifails
    case( "nperp_step" ); val = nperp_step
    case( "nmin"       ); val = nmin
    case( "nsaddle"    ); val = nsaddle
    case( "fpush_factor" ); val = fpush_factor
    case( "called_from"  ); val = called_from
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_int(): "//name )
    end select
  end subroutine get_runparam_int
  module subroutine get_runparam_real( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_real(): "//name )
    end select
  end subroutine get_runparam_real
  module subroutine get_runparam_bool( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "linit"            ); val = linit
    case( "lperp"            ); val = lperp
    case( "leigen"           ); val = leigen
    case( "llanczos"         ); val = llanczos
    case( "lbasin"           ); val = lbasin
    case( "lpush_over"       ); val = lpush_over
    case( "lrelax"           ); val = lrelax
    case( "in_lanczos_at_min"); val = in_lanczos_at_min
    case( "lbackward"        ); val = lbackward
    case( "lend"             ); val = lend
    case( "luser_choose_per_atom" ); val = luser_choose_per_atom
    case( "lserialize_input"  ); val = lserialize_input
    case( "lserialize_output" ); val = lserialize_output
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_bool(): "//name )
    end select
  end subroutine get_runparam_bool
  module subroutine get_runparam_str( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "error_message" ); allocate( val, source=trim(error_message) )
    case( "errmsg" ); allocate( val, source=errmsg )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_str(): "//name )
    end select
  end subroutine get_runparam_str
  module subroutine get_runparam_real1d( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_real1d(): "//name )
    end select
  end subroutine get_runparam_real1d
  module subroutine get_runparam_real2d( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:,:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "push"                ); allocate( val, source=push )
    case( "eigenvec"            ); allocate( val, source=eigenvec )
    case( "push_initial_vector" ); allocate( val, source=push_initial_vector )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_real2d(): "//name )
    end select
  end subroutine get_runparam_real2d



  !> @details
  !! generalize get_cparam
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! int get_runparam ( const char *name, void* cval );
  !!~~~~~~~~~~~~~~~~
  !!
  function get_crunparam( cname, cval )result(cerr)bind(C,name="get_runparam")
    use, intrinsic :: iso_c_binding
    use m_datainfo
    use m_tools, only: c2f_char, f2c_string
    character(len=1, kind=c_char), dimension(*), intent(in) :: cname
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(:), allocatable :: fname, fstr
    integer :: ierr, dtype, drank
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

    !! decide what to do based on dtype
    select case( dtype )
    case( ARTN_DTYPE_INT )

       select case( drank )
       case( 0 )
          call get_runparam_int( fname, fint, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr, c_int)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( iptr, source=int(fint, c_int) )
          ! write(*,*) "iptr",iptr
          cval = c_loc( iptr )

       case default
          call err_set(ERR_DRANK, __FILE__,__LINE__,msg="unsupported rank for int")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end select


    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call get_runparam_real( fname, freal, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( rptr, source = real(freal, c_double) )
          cval = c_loc( rptr )
       case( 1 )
          call get_runparam_real1d( fname, freal1d, ierr )
          if( ierr /= 0 ) then
             cerr = int(ierr)
             call err_write(__FILE__,__LINE__)
             return
          end if
          allocate( r1ptr, source = real(freal1d, c_double) )
          cval = c_loc( r1ptr(1) )
          deallocate( freal1d )
       case( 2 )
          call get_runparam_real2d( fname, freal2d, ierr )
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
       call get_runparam_bool( fname, fbool, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
          return
       end if
       allocate( bptr, source=logical(fbool, c_bool) )
       cval = c_loc( bptr )

    case( ARTN_DTYPE_STR )
       call get_runparam_str( fname, fstr, ierr )
       if( ierr /= 0 ) then
          cerr = int(ierr)
          call err_write(__FILE__,__LINE__)
          return
       end if
       cval = f2c_string( fstr )

    case default
       cerr = int( ERR_DTYPE )
       write(msg, "(a,1x,i0)") "unknwon dtpe value:",dtype
       call err_set(ERR_DTYPE, __FILE__, __LINE__, msg=msg )
       call err_write( __FILE__,__LINE__)
       return
    end select

    cerr = 0_c_int
    deallocate( fname )
  end function get_crunparam


end submodule get_runparam_routines
