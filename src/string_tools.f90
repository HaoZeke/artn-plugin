submodule( m_tools ) string_tools

  use, intrinsic :: iso_c_binding
  implicit none

contains

  !................................................................................
  !> @brief
  !!   Parse the instrg thank to the Field Separator FS and return
  !!   the list of string and the number of element in the list
  !
  !> @todo
  !!   HAVE TO BE ADAPTED FOR MULTIPLE FS
  !
  !> @param[in]   instrg   input string
  !> @param[in]   FS       Field Separator (one for the moment)
  !> @param[out]  args     arrays of string
  !> @return      nargs    number of string in output
  !
  module integer function parser( instrg, FS, args )result( nargs )
    implicit none

    ! -- ARGUMENT
    CHARACTER(len=*),              intent( in ) :: instrg
    character(len=1),              intent( in ) :: FS
    !CHARACTER(len=:), allocatable, intent( inout ) :: args(:)
    CHARACTER(len=:), allocatable, intent( out ) :: args(:)

    ! -- LOCAL VAR
    character(len=:), allocatable :: str
    character(len=:), allocatable :: ctmp(:)
    character(len=25) :: mot
    integer :: idx,leng

    ! +++ Copy in local variable the input_string
    allocate(str, source = adjustl(instrg))
    nargs = 0
    !
    ! +++ Repeat for each field
    do
    !   +++ Verification the length of sentence
        leng = len_TRIM( str )
        if( leng == 0 )exit

    !   +++ Find the Field Separator
        idx = SCAN( str, FS )

    !   +++ extract the word
        if( idx == 0 )then
          mot = trim(str)
        else
          mot = str( :idx-1 )
        endif

    !   +++ Add the word in args
        nargs = nargs + 1
        if( nargs == 1 )then
          args = [ mot ]
        else
          ctmp = args
          deallocate( args )
          args = [ ctmp, mot ]
        endif

    !   +++ cut the word
        if( idx == 0 )exit
        str = adjustl(str(idx+1:))
    !
    enddo
  end function parser

  ! .............................................................................
  !> @brief
  !!   Read a line, makes possible to use # for comment lines, skips empty lines,
  !!   is pretty much a copy from QE.
  !!
  !> @details  Quantum ESPRESSO routine
  !
  !> @param[in]   fd            file descriptor
  !! @param[out]  line          what it reads
  !! @param[out]  end_of_file   logical to signal the EOF
  !
  module subroutine read_line(fd, line, end_of_file)
    implicit none
    integer, intent(in) :: fd
    character(len=256), intent(out) :: line
    logical, optional, intent(out) :: end_of_file

    integer             :: ios
    logical :: tend

    !print*, "in read_line", fd

    tend = .false.
    101 read(unit=fd,fmt='(A256)',END=111, iostat=ios) line
    if (ios /= 0) then
       print*, " Reading Problem..."; stop; endif
    if(line == ' ' .or. line(1:1) == '#') go to 101
    go to 105
    111     tend = .true.
    !print*,"read_line", line
    go to 105
    105   continue

    if( present(end_of_file)) then
      end_of_file = tend
    endif
  end subroutine read_line


  !> @brief
  !!   Changes a string to lower case
  !
  !> @param[in]   str     input
  !> @returns     string  output
  module function to_lower( str )Result( string )
    Implicit None
    Character(*), Intent(IN) :: str
    Character(LEN(str))      :: string

    Integer :: ic, i

    Character(26), Parameter :: cap = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    Character(26), Parameter :: low = 'abcdefghijklmnopqrstuvwxyz'

    !   Capitalize each letter if it is lowecase
    string = str
    do i = 1, LEN_TRIM(str)
       ic = INDEX(cap, str(i:i))
       if( ic > 0 )then
          string(i:i) = low(ic:ic)
       else
          string(i:i) = string(i:i)
       endif
    end do
  END FUNCTION to_lower



  !! copy fortran string to c_ptr
  module function f2c_string( str ) result(ptr)
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

  ! copy null-terminated C string ptr to fortran string
  MODULE FUNCTION c2f_string(ptr) RESULT(f_string)

    INTERFACE
       !! standard c function (read from c_ptr)
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



  !! copy c char into fortran string
  module function c2f_char( cstring )result(fstring)
    interface
       !! standard c function (read from c_char)
       function c_strlen(str) bind(c, name='strlen')
         import :: c_ptr, c_size_t, c_char
         implicit none
         character(c_char), dimension(*), intent(in) :: str
         integer(c_size_t) :: c_strlen
       end function c_strlen
    end interface

    character(len=1,kind=c_char), intent(in) :: cstring(*)
    character(:), allocatable :: fstring

    integer(c_size_t) :: len
    integer :: i

    len = c_strlen( cstring )
    allocate( character(len=len) :: fstring )
    i = 1
    do while( cstring(i) .ne. c_null_char .and. (int(i,c_size_t) .le. len) )
       fstring(i:i) = cstring(i)
       i = i + 1
    end do
  end function c2f_char


  !! len() for integer
  pure module function len_int(int)result(len)
    integer, intent(in) :: int
    integer :: len
    character(len=16) :: tmp
    write(tmp,"(i0)") int
    len=len_trim(tmp)
  end function len_int

  !! add ability to concatenate string with integer using //
  pure module function concat_str_int( str, int )result(res)
    character(*), intent(in) :: str
    integer, intent(in) :: int
    character(len=len(str)+len_int(int)) :: res
    write(res,"(a,i0)") str,int
  end function concat_str_int


  !......................................................
  !> @brief
  !!   test if the string represent a number or not
  !
  !> @param[in]    string   input string
  !> @return       logical  
  !
  module elemental FUNCTION is_numeric(string)
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(IN) :: string
    LOGICAL :: is_numeric
    REAL :: x
    INTEGER :: e,n
    CHARACTER(len=12) :: fmt

    n = LEN_TRIM(string)
    WRITE(fmt,'("(F",I0,".0)")') n
    READ(string,fmt,IOSTAT=e) x
    is_numeric = (e == 0)
  END FUNCTION is_numeric

end submodule string_tools
