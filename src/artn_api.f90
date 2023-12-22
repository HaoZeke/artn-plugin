module artn_api

  use iso_c_binding
  use artn_data


  ! type :: op_ptr
  !    type( t_artn_data ) :: artn_data_s
  ! end type op_ptr

contains

  function artn_create()result( this ) bind(C, name= "artn_create" )
    use artn_data, only: t_artn_data
    use artn_params, only: artn_data_ptr
    implicit none
    type( c_ptr ) :: this

    !! allocate new pointer of type t_artn_data,
    !! the pointer is stored in artn_params_mod
    artn_data_ptr => t_artn_data()

    !! return c_ptr to the new memory
    this = c_loc( artn_data_ptr )

  end function artn_create

  subroutine artn_destroy( cptr )bind(C, name="artn_destroy" )
    !! destory artn_data_ptr and the connection
    use artn_data
    use artn_params
    implicit none
    type( c_ptr ), value :: cptr
    type( t_artn_data ), pointer :: fptr
    ! write(*,*) "in destroy"
    call c_f_pointer( cptr, fptr )
    deallocate( artn_data_ptr )
    nullify( artn_data_ptr )
    ! write(*,*) associated( artn_data_ptr )
  end subroutine artn_destroy

  function artn_get_datatype( cptr, cname, cerr ) result( ctyp )bind(C, name="artn_get_datatype" )
    !! return the datatype code value for variable given by cname
    use artn_data
    implicit none
    type( c_ptr ), value :: cptr
    type( c_ptr ), value :: cname
    integer( c_int ), intent(out) :: cerr
    integer( c_int ) :: ctyp

    character(:), allocatable :: fname
    type( t_artn_data ), pointer :: fptr

    cerr = 0_c_int
    nullify( fptr )
    call c_f_pointer( cptr, fptr )

    allocate( fname, source= c2f_string(cname) )
    ctyp = int( fptr% get_datatype( fname ), c_int )
    if( ctyp < 0_c_int ) then
       cerr = -1_c_int
       return
    end if
    deallocate( fname )
  end function artn_get_datatype

  function artn_get_datarank( cptr, cname, cerr ) result( crank )bind(C, name="artn_get_datarank" )
    !! return the rank of variable given by cname
    use artn_data
    implicit none
    type( c_ptr ), value :: cptr
    type( c_ptr ), value :: cname
    integer( c_int ), intent(out) :: cerr
    integer( c_int ) :: crank

    character(:), allocatable :: fname
    type( t_artn_data ), pointer :: fptr

    cerr = 0_c_int
    nullify( fptr )
    call c_f_pointer( cptr, fptr )

    allocate( fname, source= c2f_string(cname) )
    crank = int( fptr% get_datarank( fname ), c_int )
    if( crank < 0_c_int ) then
       cerr = -1_c_int
       return
    end if
    deallocate( fname )
  end function artn_get_datarank


  subroutine artn_set( cptr, cname, ctyp, crank, csize, cval, cerr ) bind(C, name= "artn_set")
    !! set data from input ctyp, crank, csize, cval into artn_data_ptr variable with cname
    use artn_data
    implicit none
    type( c_ptr ), value :: cptr
    type( c_ptr ), value :: cname
    integer( c_int ), value, intent(in) :: ctyp
    integer( c_int ), value, intent(in) :: crank
    type( c_ptr ) :: csize
    type( c_ptr ) :: cval
    integer( c_int ) :: cerr

    type( t_artn_data ), pointer :: fptr
    character(:), allocatable :: fname, fval
    integer :: dtyp, drank
    integer, allocatable :: dsize(:)
    integer :: exp_dtyp, exp_rank
    integer( c_int ), pointer :: isize(:)
    character(*), parameter :: here="artn_api.f90::artn_set()"
    integer( c_int ), pointer :: iptr, i1ptr(:) !, i2ptr(:,:)
    real( c_double ), pointer :: rptr, r1ptr(:), r2ptr(:,:)
    logical( c_bool ), pointer :: bptr

    ! write(*,*) "in artn_set"
    nullify( fptr )
    call c_f_pointer( cptr, fptr )

    allocate( fname, source = c2f_string( cname ) )
    ! write(*,*) "fname in art_set:",fname

    dtyp = int( ctyp )
    drank = int( crank )
    ! write(*,*) "got dtyp",dtyp
    ! write(*,*) "got drank", drank

    !! check if input dtyp is the same as expected dtyp
    exp_dtyp = fptr% get_datatype( fname )
    if( exp_dtyp /= dtyp ) then
       call artn_api_warning( routine=here, &
            msg1="wrong datatype in input!", &
            msg2="possibly nonexistent variable: "//fname )
       cerr = -1_c_int
       return
    end if

    !! check if input rank is same as expected rank
    exp_rank = fptr% get_datarank( fname )
    if( exp_rank /= drank ) then
       call artn_api_warning( routine=here, msg1="wrong datarank in input! "//fname )
       cerr = -1_c_int
       return
    end if

    call c_f_pointer( csize, isize, shape=[drank] )
    allocate( dsize, source=int(isize) )
    ! write(*,*) "got dsize:",dsize


    select case( dtyp )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, iptr )
          cerr = int( fptr% set_data( fname, int(iptr) ), c_int )
       case( 1 )
          call c_f_pointer( cval, i1ptr, shape = dsize )
          cerr = int( fptr% set_data( fname, dsize(1), int(i1ptr) ), c_int )
       ! case( 2 )
       !    call c_f_pointer( cval, i2ptr, shape = dsize )
       !    cerr = int( fptr% set_data( fname, dsize(1), dsize(2), int(i2ptr) ), c_int )
       case default; cerr = -2_c_int
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, rptr )
          cerr = int( fptr% set_data( fname, real(rptr) ), c_int )
       case( 1 )
          call c_f_pointer( cval, r1ptr, shape = dsize )
          cerr = int( fptr% set_data( fname, dsize(1), real(r1ptr) ), c_int )
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape = dsize )
          cerr = int( fptr% set_data( fname, dsize(1), dsize(2), real(r2ptr) ), c_int)
       case default; cerr = -3_c_int
       end select

    case( ARTN_DTYPE_BOOL )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, bptr )
          cerr = int( fptr% set_data(fname, logical(bptr)), c_int )
       case default; cerr = -4_c_int
       end select

    case( ARTN_DTYPE_STR )
       select case( drank )
       case( 0 )
          allocate(fval, source = c2f_string( cval ) )
          ! write(*,*) "setting string:",fval
          cerr = int( fptr% set_data( fname, fval), c_int )
          deallocate( fval )
       case default; cerr = -5_c_int
       end select

    end select

    ! write(*,*) "got cerr",cerr
    if( cerr /= 0_c_int ) then
       call artn_api_warning( routine=here, &
            msg1="error in fptr% set_data, variable name unknown?" )
       write(*,*) "cerr value:",cerr
    end if

    deallocate( fname )
    deallocate( dsize )
  end subroutine artn_set

  function artn_extract( cptr, cname, ctyp, crank, csize, cval )result( cerr )bind(C, name="artn_extract")
    !! return value from artn_data_ptr given by cname, return ctyp, crank, csize, and cval
    use artn_data, only: t_artn_data
    implicit none
    interface
       function c_malloc(size) bind(C, name="malloc")
         import c_ptr, c_size_t
         integer(c_size_t), intent(in), value :: size
         type(c_ptr) :: c_malloc
       end function c_malloc
    end interface

    type( c_ptr ), value :: cptr
    type( c_ptr ), value :: cname
    integer( c_int ), intent(out) :: ctyp
    integer( c_int ), intent(out) :: crank
    type( c_ptr ), intent(out) :: csize
    type( c_ptr ), intent(out) :: cval
    integer( c_int ) :: cerr

    character(*), parameter :: here="artn_api.f90::artn_extract()"
    type( t_artn_data ), pointer :: fptr
    integer, allocatable :: dsize(:)
    character(:), allocatable :: fname
    integer, dimension(:), pointer :: pp

    cerr = -1_c_int

    nullify( fptr )
    call c_f_pointer( cptr, fptr )

    allocate( fname, source = c2f_string(cname) )

    !! get datatype
    ctyp = int( fptr% get_datatype( fname ), c_int )
    if( ctyp < 0_c_int ) then
       call artn_api_warning( routine=here, &
            msg1="error value datatype", &
            msg2="possibly nonexistent variable name: "//fname )
       return
    end if

    !! get datarank
    crank = int( fptr% get_datarank( fname ), c_int )
    if( crank < 0_c_int ) then
       call artn_api_warning( routine=here, &
            msg1 = "error value datarank "//fname )
       return
    end if


    ! write(*,*) "in artn_extract, got:"
    ! write(*,*) "fname:",fname
    ! write(*,*) "ctyp:",ctyp
    ! write(*,*) "crank:",crank

    !! get datasize
    cerr = int( fptr% get_datasize(fname, dsize), c_int )
    if( cerr /= 0_c_int ) then
       call artn_api_warning( routine=here, &
            msg1="error in datasize" )
       return
    end if
    csize = c_malloc( crank*c_sizeof(1_c_int) )
    call c_f_pointer( csize, pp, shape=[crank] )
    pp(1:crank) = dsize(:)

    cval = fptr% get_data( fname )
    if( .not. c_associated(cval) ) then
       cerr = -3
       call artn_api_warning( routine=here, &
            msg1="error in get_data")
       return
    end if


    deallocate( fname )
    deallocate( dsize )
  end function artn_extract

  function artn_dump_input( cptr, filename )result( cerr ) bind(C, name="artn_dump_input" )
    !! dump the defined values inside artn_data_ptr into a file that can be used as regular artn.in input
    use artn_data
    implicit none
    type( c_ptr ), value :: cptr
    type( c_ptr ), optional :: filename
    integer( c_int ) :: cerr

    type( t_artn_data ), pointer :: fptr
    character(:), allocatable :: fname

    ! write(*,*) "in artn_dump_input",present(filename)
    cerr = 0_c_int
    call c_f_pointer( cptr, fptr )

    if( present(filename) ) then
       allocate(fname, source = c2f_string(filename) )
    else
       allocate( fname, source = "default_filename" )
    end if

    cerr = int( fptr% dump_input(fname), c_int )

    deallocate( fname )
  end function artn_dump_input

  subroutine artn_list_set( )bind(C, name="artn_list_set" )
    use artn_params, only: artn_data_ptr
    implicit none
    call artn_data_ptr% list_set()
  end subroutine artn_list_set

  subroutine artn_list_extract()bind(C,name="artn_list_extract")
    use artn_params, only: artn_data_ptr
    implicit none
    call artn_data_ptr% list_extract()
  end subroutine artn_list_extract


  subroutine tt( cptr )bind(C,name="tt")
    use artn_data
    use artn_params
    implicit none
    type( c_ptr ), value :: cptr
    type( t_artn_data ), pointer :: fptr
    !! can act directly on art_data
    write(*,*) "print params% adat", associated( artn_data_ptr )
    ! write(*,*) artn_data_ptr% p
    ! write(*,*) artn_data_ptr% msize

    !! can also connect to exat cptr, which is pointing to artn_data
    call c_f_pointer( cptr, fptr )
    ! write(*,*) fptr% p, fptr% msize
  end subroutine tt




  !!
  !! local functions
  !!
  subroutine artn_api_warning( routine, msg1, msg2 )
    !! print a warning message from the api
    implicit none
    character(*), intent(in), optional :: routine
    character(*), intent(in), optional :: msg1
    character(*), intent(in), optional :: msg2
    write(*,*) repeat('%',30)
    write(*,'(5x,a)') "ARTN_API_WARNING::"
    if( present(routine) ) write(*,'(5x,a,1x,a)') "In routine::", routine
    if( present(msg1) ) write(*,'(5x,a,1x,a)') "Msg 1:", msg1
    if( present(msg2) ) write(*,'(5x,a,1x,a)') "Msg 2:", msg2
    write(*,*) repeat('%',30)
  end subroutine artn_api_warning

  ! copy null-terminated C string to fortran string
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

end module artn_api
