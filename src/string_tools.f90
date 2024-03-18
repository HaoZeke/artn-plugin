submodule( tools ) string_tools
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
    CHARACTER(len=:), allocatable, intent( inout ) :: args(:)

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



end submodule string_tools
