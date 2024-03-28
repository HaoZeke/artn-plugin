module f_partn

  use iso_c_binding
  implicit none

  private
  public :: t_partn, assignment(=)


  !! type definition
  type t_partn
     type( c_ptr ) :: handle
   contains
     procedure :: close => t_partn_destroy
     procedure :: dump_input => t_partn_dump_input
     procedure :: extract => t_partn_extract_data
     procedure, private :: t_partn_set_int, t_partn_set_real, t_partn_set_int_1d, &
          t_partn_set_real_1d, t_partn_set_real_2d, t_partn_set_bool, t_partn_set_string
     generic :: set => t_partn_set_int, t_partn_set_real, t_partn_set_int_1d, &
          t_partn_set_real_1d, t_partn_set_real_2d, t_partn_set_bool, t_partn_set_string
  end type t_partn

  !! overload name with init function
  interface t_partn
     module procedure t_partn_create
  end interface t_partn

  !! datatype encoders,
  !! must be identical copy from artn_data.f90
  integer, parameter, public :: &
       ARTN_DTYPE_UNKNOWN = -1, &
       ARTN_DTYPE_INT     = 0, &
       ARTN_DTYPE_REAL    = 1, &
       ARTN_DTYPE_BOOL    = 2, &
       ARTN_DTYPE_STR     = 3

  !! type to hold data during extract
  type t_data
     integer :: dtype = -1
     integer( c_int ), pointer :: integer => null()
     integer( c_int ), pointer :: int1d(:) => null()
     integer( c_int ), pointer :: int2d(:,:) => null()
     real( c_double ), pointer :: real => null()
     real( c_double ), pointer :: real1d(:) => null()
     real( c_double ), pointer :: real2d(:,:) => null()
     character(:), allocatable :: string
     logical( c_bool ), pointer :: bool
  end type t_data

  !! overload assignment for t_data
  interface assignment(=)
     module procedure &
          assign_int_data, &
          assign_int1d_data, &
          assign_real_data, &
          assign_real2d_data, &
          assign_bool_data, &
          assign_str_data
  end interface assignment(=)

  !! interface to C functions
  interface
     subroutine c_free(ptr)bind(C, name="free")
       import :: c_ptr
       type( c_ptr ), value :: ptr
     end subroutine c_free
  end interface

  !! interface to api functions
  interface
     function artn_create()result(this) bind(C, name = "artn_create" )
       import :: c_ptr
       type( c_ptr ) :: this
     end function artn_create

     subroutine artn_destroy( cptr ) bind(C, name="artn_destroy" )
       import :: c_ptr
       type( c_ptr ), value :: cptr
     end subroutine artn_destroy

     function artn_get_datatype( cptr, cname, cerr ) result(ctyp)bind(C, name="artn_get_datatype")
       import :: c_ptr, c_int
       type( c_ptr ), value :: cptr
       type( c_ptr ), value :: cname
       integer( c_int ), intent(out) :: cerr
       integer( c_int ) :: ctyp
     end function artn_get_datatype

     function artn_get_datarank( cptr, cname, cerr ) result( crank )bind(C, name="artn_get_datarank" )
       import :: c_ptr, c_int
       type( c_ptr ), value :: cptr
       type( c_ptr ), value :: cname
       integer( c_int ), intent(out) :: cerr
       integer( c_int ) :: crank
     end function artn_get_datarank

     subroutine artn_set( cptr, cname, ctyp, crank, csize, cval, cerr ) bind(C, name= "artn_set")
       import :: c_ptr, c_int
       type( c_ptr ), value :: cptr
       type( c_ptr ), value :: cname
       integer( c_int ), value, intent(in) :: ctyp
       integer( c_int ), value, intent(in) :: crank
       type( c_ptr ) :: csize
       type( c_ptr ) :: cval
       integer( c_int ) :: cerr
     end subroutine artn_set

     function artn_extract( cptr, cname, ctyp, crank, csize, cval )result( cerr )bind(C, name="artn_extract")
       import :: c_ptr, c_int
       type( c_ptr ), value :: cptr
       type( c_ptr ), value :: cname
       integer( c_int ), intent(out) :: ctyp
       integer( c_int ), intent(out) :: crank
       type( c_ptr ), intent(out) :: csize
       type( c_ptr ), intent(out) :: cval
       integer( c_int ) :: cerr
     end function artn_extract

     function artn_dump_input( cptr, filename )result( cerr ) bind(C, name="artn_dump_input" )
       import :: c_ptr, c_int
       type( c_ptr ), value :: cptr
       type( c_ptr ), value :: filename
       integer( c_int ) :: cerr
     end function artn_dump_input
  end interface

contains

  function t_partn_create()result( self )
    type( t_partn ) :: self

    self% handle = artn_create()
   ! write(*,*) "Iam artn"

  end function t_partn_create

  subroutine t_partn_destroy( self )
    class( t_partn ), intent(inout) :: self

    call artn_destroy( self% handle )
  end subroutine t_partn_destroy


  subroutine t_partn_dump_input( self, filename )
    implicit none
    class( t_partn ), intent(in) :: self
    character(*), intent(in), optional :: filename

    type( c_ptr ) :: c_fname
    integer( c_int ) :: cerr

    c_fname = c_null_ptr
    if( present(filename) ) then
       c_fname = f2c_string(filename)
       cerr = artn_dump_input( self% handle, c_fname )
       call c_free( c_fname )
    else
       cerr = artn_dump_input( self% handle, c_fname )
    end if
    if( cerr .ne. 0_c_int ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR in artn_dump_input"
       write(*,*) repeat("%",30)
       stop
    end if
  end subroutine t_partn_dump_input


  function t_partn_extract_data( self, fname, ierr )result( recv_data )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    integer, intent(out), optional :: ierr
    type( t_data ) :: recv_data

    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    integer :: frank
    integer( c_int ), pointer :: fsize(:)

    cname = f2c_string( fname )

    !! get data ptr
    cerr = artn_extract( self% handle, cname, ctyp, crank, csize, cval )
    if (present(ierr))  ierr = INT( cerr )
    if( cerr .ne. 0_c_int ) then 
       write(*,*) "error in extract, stopping"
       stop
    end if

    recv_data% dtype = int(ctyp)

    frank = int(crank)
    call c_f_pointer( csize, fsize, shape=[frank] )

    !! convert ptr to proper type, rank, size
    select case( recv_data% dtype )
    case( ARTN_DTYPE_INT )
       select case( crank )
       case( 0_c_int )
          call c_f_pointer( cval, recv_data% integer )
       case( 1_c_int )
          call c_f_pointer( cval, recv_data% int1d, shape=[fsize] )
       ! case( 2_c_int )
       !    call c_f_pointer( cval, recv_data% int2d, shape=[fsize] )
       end select

    case( ARTN_DTYPE_REAL )
       select case( crank )
       case( 0_c_int )
          call c_f_pointer( cval, recv_data% real )
       ! case( 1_c_int )
       !    call c_f_pointer( cval, recv_data% real1d, shape=[fsize] )
       case( 2_c_int )
          call c_f_pointer( cval, recv_data% real2d, shape=[fsize] )
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, recv_data% bool )

    case( ARTN_DTYPE_STR )
       recv_data% string = c2f_string( cval )

    end select

    call c_free( cname )
    deallocate( fsize )
  end function t_partn_extract_data

  subroutine t_partn_set_int( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    integer, intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    integer( c_int ), pointer :: fptr

    cname = c_null_ptr
    cval = c_null_ptr

    !! convert fortran input into C
    cname = f2c_string( fname )
    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    !! check if correct datatype
    if( int(ctyp) .ne. ARTN_DTYPE_INT ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","integer"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",0
       write(*,*) repeat("%",30)
       stop
    end if

    allocate( fptr, source=int(fval, c_int))
    cval = c_loc( fptr )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
    nullify(fptr)
  end subroutine t_partn_set_int
  subroutine t_partn_set_int_1d( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    integer, dimension(:), intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    integer( c_int ), pointer :: fptr(:)
    integer( c_int ), pointer :: dsize

    cname = c_null_ptr
    cval = c_null_ptr
    csize = c_null_ptr

    !! convert fortran input into C
    cname = f2c_string( fname )

    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    if( int(ctyp) .ne. ARTN_DTYPE_INT ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","integer"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 1 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",1
       write(*,*) repeat("%",30)
       stop
    end if

    allocate( dsize, source = int(size(fval),c_int) )
    csize = c_loc( dsize )

    allocate( fptr, source=int(fval, c_int))
    cval = c_loc( fptr(1) )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
    call c_free(csize)
    nullify(fptr)
  end subroutine t_partn_set_int_1d
  subroutine t_partn_set_real( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    real, intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    real( c_double ), pointer :: fptr

    cname = c_null_ptr
    cval = c_null_ptr

    cname = f2c_string( fname )
    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    if( int(ctyp) .ne. ARTN_DTYPE_REAL ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","real"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",0
       write(*,*) repeat("%",30)
       stop
    end if

    allocate( fptr, source=real(fval, c_double))
    cval = c_loc( fptr )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
    nullify(fptr)

  end subroutine t_partn_set_real
  subroutine t_partn_set_real_1d( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    real, dimension(:), intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    real( c_double ), pointer :: fptr(:)
    integer( c_int ), pointer :: dsize

    cname = c_null_ptr
    cval = c_null_ptr
    csize = c_null_ptr

    cname = f2c_string( fname )
    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    if( int(ctyp) .ne. ARTN_DTYPE_REAL ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","real"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 1 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",1
       write(*,*) repeat("%",30)
       stop
    end if

    allocate( dsize, source = int( size(fval),c_int) )
    csize = c_loc(dsize)

    allocate( fptr, source=real(fval, c_double))
    cval = c_loc( fptr(1) )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
    call c_free( csize )
    nullify(fptr)

  end subroutine t_partn_set_real_1d
  subroutine t_partn_set_real_2d( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    real, dimension(:,:), intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    real( c_double ), pointer :: fptr(:,:)
    integer( c_int ), pointer :: dsize(:)
    integer, dimension(2) :: fsize

    cname = c_null_ptr
    cval = c_null_ptr
    csize = c_null_ptr

    cname = f2c_string( fname )
    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    if( int(ctyp) .ne. ARTN_DTYPE_REAL ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","real"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 2 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",2
       write(*,*) repeat("%",30)
       stop
    end if

    fsize(1) = size(fval, 1); fsize(2) = size(fval, 2)
    allocate( dsize, source = int(fsize, c_int) )
    csize = c_loc(dsize(1))

    allocate( fptr, source=real(fval, c_double))
    cval = c_loc( fptr(1,1) )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
    call c_free( csize )
    nullify(fptr)

  end subroutine t_partn_set_real_2d
  subroutine t_partn_set_bool( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    logical, intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr
    logical( c_bool ), pointer :: fptr

    cname = c_null_ptr
    cval = c_null_ptr

    cname = f2c_string( fname )
    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    if( int(ctyp) .ne. ARTN_DTYPE_BOOL ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","logical"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",0
       write(*,*) repeat("%",30)
       stop
    end if

    allocate( fptr, source=logical(fval, c_bool))
    cval = c_loc( fptr )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
    nullify(fptr)
  end subroutine t_partn_set_bool
  subroutine t_partn_set_string( self, fname, fval )
    implicit none
    class( t_partn ), intent(inout) :: self
    character(*), intent(in) :: fname
    character(*), intent(in) :: fval

    integer :: ierr
    type( c_ptr ) :: cname, csize, cval
    integer( c_int ) :: ctyp, crank, cerr

    cname = c_null_ptr
    cval = c_null_ptr

    cname = f2c_string( fname )
    ctyp = artn_get_datatype( self% handle, cname, cerr )
    !! check if error (possible wrong name)
    if( int(cerr) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: unknown variable:", fname
       write(*,*) repeat("%",30)
       stop
    end if

    if( int(ctyp) .ne. ARTN_DTYPE_STR ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong datatype for variable:", fname
       write(*,"(3x,a,1x,a,3x,a,1x,a)") "Expected:", string_dtyp( int(ctyp) ), "got:","string"
       write(*,*) repeat("%",30)
       stop
    end if

    crank = artn_get_datarank( self% handle, cname, cerr )
    if( int(crank) .ne. 0 ) then
       write(*,*) repeat("%",30)
       write(*,"(3x,a,1x,a)") "ERROR: wrong rank for variable:", fname
       write(*,"(3x,a,1x,i0,3x,a,1x,i0)") "Expected:",int(crank), "got:",0
       write(*,*) repeat("%",30)
       stop
    end if

    cval = f2c_string( fval )

    call artn_set( self% handle, cname, ctyp, crank, csize, cval, cerr )
    ierr = int( cerr )
    if( ierr .ne. 0 ) then
       write(*,*) "error from artn_set:",ierr
       stop
    end if

    call c_free(cname)
    call c_free( cval )
  end subroutine t_partn_set_string



  !! ================================
  !! overload assignment from type( t_data ) to whatever is needed
  subroutine assign_int_data( lhs, rhs )
    integer, intent(out) :: lhs
    class( t_data ), intent(in) :: rhs
    if( rhs% dtype == ARTN_DTYPE_INT ) then
       lhs = rhs% integer
    else
       !error
       call assign_error( "integer", string_dtyp( rhs% dtype) )
       stop
    end if
  end subroutine assign_int_data
  subroutine assign_int1d_data( lhs, rhs )
    integer, allocatable, intent(out) :: lhs(:)
    class( t_data ), intent(in) :: rhs
    if( rhs% dtype == ARTN_DTYPE_INT ) then
       allocate( lhs, source = rhs% int1d )
    else
       !error
       call assign_error( "integer1d", string_dtyp( rhs% dtype) )
       stop
    end if
  end subroutine assign_int1d_data
  subroutine assign_real_data( lhs, rhs )
    real, intent(out) :: lhs
    class( t_data ), intent(in) :: rhs
    if( rhs% dtype == ARTN_DTYPE_REAL ) then
       lhs = real( rhs% real )
    else
       !error
       call assign_error( "real", string_dtyp( rhs% dtype) )
       stop
    end if
  end subroutine assign_real_data
  subroutine assign_real2d_data( lhs, rhs )
    real, allocatable, intent(out) :: lhs(:,:)
    class( t_data ), intent(in) :: rhs
    if( rhs% dtype == ARTN_DTYPE_REAL ) then
       allocate( lhs, source = real( rhs% real2d ) )
    else
       !error
       call assign_error( "real2d", string_dtyp( rhs% dtype) )
       stop
    end if
  end subroutine assign_real2d_data
  subroutine assign_bool_data( lhs, rhs )
    logical, intent(out) :: lhs
    class( t_data ), intent(in) :: rhs
    if( rhs% dtype == ARTN_DTYPE_BOOL ) then
       lhs = logical( rhs% bool )
    else
       !error
       call assign_error( "bool", string_dtyp( rhs% dtype) )
       stop
    end if
  end subroutine assign_bool_data
  subroutine assign_str_data( lhs, rhs )
    character(:), allocatable, intent(out) :: lhs
    class( t_data ), intent(in) :: rhs
    if( rhs% dtype == ARTN_DTYPE_STR ) then
       allocate( lhs, source=rhs% string )
    else
       !error
       call assign_error( "string", string_dtyp( rhs% dtype) )
       stop
    end if
  end subroutine assign_str_data

  subroutine assign_error( dtype_lhs, dtype_rhs )
    character(*), intent(in) :: dtype_lhs
    character(*), intent(in) :: dtype_rhs
    write(*,*) repeat("=", 40 )
    write(*,"(3x,a,3(1x,a))" ) "WARNING: cannot assign rhs type", dtype_rhs, "to lhs type", dtype_lhs
    write(*,*) repeat("=", 40 )
  end subroutine assign_error



  !! ================================
  !! local functions
  function string_dtyp( val ) result( str )
    implicit none
    integer, intent(in) :: val
    character(:), allocatable :: str
    select case( val )
    case( ARTN_DTYPE_UNKNOWN ); str = "unknown"
    case( ARTN_DTYPE_INT ); str = "integer"
    case( ARTN_DTYPE_REAL ); str = "real"
    case( ARTN_DTYPE_BOOL ); str = "logical"
    case( ARTN_DTYPE_STR ); str = "string"
    end select
  end function string_dtyp

  function f2c_string( str ) result(ptr)
    use iso_c_binding, only: c_char, c_null_char, c_ptr, c_loc
    implicit none
    character(*), intent(in) :: str
    type( c_ptr ) :: ptr
    character(len=1, kind=c_char), pointer :: sptr(:)
    integer :: i, n
    n = len( str )
    allocate(sptr(1:n+1) )
    do i = 1, n
       sptr(i) = str(i:i)
    end do
    sptr(n+1) = c_null_char
    ptr = c_loc(sptr)
  end function f2c_string
  FUNCTION c2f_string(ptr) RESULT(f_string)
    use iso_c_binding
    INTERFACE
       !! standard c function
       FUNCTION c_strlen(str) BIND(C, name='strlen')
         IMPORT :: c_ptr, c_size_t
         IMPLICIT NONE
         TYPE(c_ptr), INTENT(IN), VALUE :: str
         INTEGER(c_size_t) :: c_strlen
       END FUNCTION c_strlen
    END INTERFACE
    TYPE(c_ptr), INTENT(IN) :: ptr
    CHARACTER(LEN=:), ALLOCATABLE :: f_string
    CHARACTER(LEN=1, KIND=c_char), DIMENSION(:), POINTER :: c_string
    INTEGER :: n, i

    IF (.NOT. C_ASSOCIATED(ptr)) THEN
       f_string = ' '
    ELSE
       n = INT(c_strlen(ptr), KIND=KIND(n))
       CALL C_F_POINTER(ptr, c_string, [n+1])
       allocate( CHARACTER(LEN=n)::f_string)
       do i = 1, n
          f_string(i:i) = c_string(i)
       end do
    END IF
  END FUNCTION c2f_string

end module f_partn
