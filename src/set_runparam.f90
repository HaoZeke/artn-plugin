submodule( artn_params )set_runparam_routines
  use precision
  use m_error
  implicit none

contains


  module function set_runparam_int( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "iartn"        ); iartn        = val
    case( "istep"        ); istep        = val
    case( "iinit"        ); iinit        = val
    case( "iperp"        ); iperp        = val
    case( "ieigen"       ); ieigen       = val
    case( "irelax"       ); irelax       = val
    case( "iover"        ); iover        = val
    case( "nnewchance"   ); nnewchance   = val
    case( "ismooth"      ); ismooth      = val
    case( "nlanc"        ); nlanc        = val
    case( "ifound"       ); ifound       = val
    case( "isearch"      ); isearch      = val
    case( "ifails"       ); ifails       = val
    case( "nperp_step"   ); nperp_step   = val
    case( "nmin"         ); nmin         = val
    case( "nsaddle"      ); nsaddle      = val
    case( "fpush_factor" ); fpush_factor = val
    case( "called_from"  ); called_from  = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_int(): "//name )
    end select
  end function set_runparam_int
  ! module function set_runparam_real( name, val )result(ierr)
  !   implicit none
  !   character(*), intent(in) :: name
  !   real(DP), intent(in) :: val
  !   integer :: ierr
  !   ierr = 0
  !   select case( name )
  !   case default
  !      ierr = ERR_VARNAME
  !      call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_real(): "//name )
  !   end select
  ! end function set_runparam_real
  module function set_runparam_bool( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    logical, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "linit"                 ); linit             = val
    case( "lperp"                 ); lperp             = val
    case( "leigen"                ); leigen            = val
    case( "llanczos"              ); llanczos          = val
    case( "lbasin"                ); lbasin            = val
    case( "lpush_over"            ); lpush_over        = val
    case( "lrelax"                ); lrelax            = val
    case( "in_lanczos_at_min"     ); in_lanczos_at_min = val
    case( "lbackward"             ); lbackward         = val
    case( "lend"                  ); lend              = val
    case( "luser_choose_per_atom" ); luser_choose_per_atom = val
    case( "lserialize_input"      ); lserialize_input  = val
    case( "lserialize_output"     ); lserialize_output = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_bool(): "//name )
    end select
  end function set_runparam_bool
  module function set_runparam_str( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "artn_resume" ); artn_resume = val
    case( "error_message" ); error_message = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_str(): "//name )
    end select
  end function set_runparam_str
  ! module function set_runparam_int1d( name, dim, val )result(ierr)
  !   implicit none
  !   character(*), intent(in) :: name
  !   integer, intent(in) :: dim
  !   integer, intent(in) :: val(dim)
  !   integer :: ierr
  !   ierr = 0
  !   select case( name )
  !   case default
  !      ierr = ERR_VARNAME
  !      call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_int1d(): "//name )
  !   end select
  ! end function set_runparam_int1d
  module function set_runparam_real1d( name, dim, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    real(DP), intent(in) :: val(dim)
    integer :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_int1d(): "//name )
    end select
  end function set_runparam_real1d
  module function set_runparam_real2d( name, dim1, dim2, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: dim1, dim2
    real(DP), intent(in) :: val(dim1, dim2)
    integer :: ierr
    ierr = 0
    select case( name )
    case( "push" )
       if( .not. allocated(push) ) allocate(push, source=val)
       if( dim1 .ne. size(push,1) .or. dim2 .ne. size(push,2) ) then
          !! error wrong size of array val
          ierr = ERR_SIZE
          call err_set( ierr, __FILE__, __LINE__, msg="wrong size for array: "//name)
          return
       end if
       push(:,:) = val(:,:)
    case( "eigenvec" )
       if( .not. allocated(eigenvec) )allocate( eigenvec, source=val)
       if( dim1 .ne. size(eigenvec,1) .or. dim2 .ne. size(eigenvec,2) ) then
          !! error wrong size of array val
          ierr = ERR_SIZE
          call err_set( ierr, __FILE__, __LINE__, msg="wrong size for array: "//name)
          return
       end if
       eigenvec(:,:) = val(:,:)
    case( "push_initial_vector" )
       if( .not. allocated(push_initial_vector) )allocate( push_initial_vector, source=val)
       if( dim1 .ne. size(push_initial_vector,1) .or. dim2 .ne. size(push_initial_vector,2) ) then
          !! error wrong size of array val
          ierr = ERR_SIZE
          call err_set( ierr, __FILE__, __LINE__, msg="wrong size for array: "//name)
          return
       end if
       push_initial_vector(:,:) = val(:,:)
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_real2d(): "//name )
    end select
  end function set_runparam_real2d



  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_runparam( const char * const name, const int crank, const int* csize, const void *cval );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function set_crunparam( cname, crank, csize, cval ) result(cerr)bind(C,name="set_runparam")
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
          cerr = int( set_runparam_int( fname, int(iptr)), c_int )
       ! case( 1 )
       !    call c_f_pointer( cval, i1ptr, shape=[csize] )
       !    write(*,*) i1ptr
       !    cerr = int( set_param_int1d(fname, csize(1), int(i1ptr) ), c_int)
       case default
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__,__LINE__,msg="unsupported data rank for name: "//fname )
          return
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       ! case( 0 )
       !    call c_f_pointer( cval, rptr )
       !    write(*,*) rptr
       !    cerr = int( set_param_real(fname, real(rptr, DP) ), c_int)
       case( 1 )
          call c_f_pointer( cval, r1ptr, shape=[csize] )
          ! write(*,*) r1ptr
          cerr = int( set_runparam_real1d( fname, csize(1), real(r1ptr, DP) ), c_int )
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape=[csize] )
          ! write(*,*) r2ptr
          cerr = int( set_runparam_real2d( fname, csize(1), csize(2), real(r2ptr, DP) ), c_int )
       case default
          write(msg, "(i0)") drank
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__, __LINE__, msg="unsupported data rank for name: "//fname )
          return
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, bptr )
       ! write(*,*) bptr
       cerr = int( set_runparam_bool(fname, logical(bptr)), c_int)

    case( ARTN_DTYPE_STR )
       allocate(strval, source = c2f_string(cval) )
       ! write(*,*) strval
       cerr = int( set_runparam_str( fname, strval), c_int )

    case default
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="unknown variable name: "//fname )
       cerr = int( ERR_VARNAME, c_int )
       return
    end select

    deallocate( fname )
  end function set_crunparam



end submodule set_runparam_routines
