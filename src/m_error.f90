module m_error


  !> @details
  !! Philosophy of the errors is that as soon as error value ierr is obtained anywhere in
  !! the code, the error should be set -> call err_set(...), which writes location and
  !! error message into variables of this module.
  !! The value ierr should then be propagated back to the caller, and the caller can then
  !! obtain values from this module by calling err_write().
  !! In this way, the error message contains information of error location, and who called it.
  !!
  use precision, only: DP
  implicit none

  !! location of last error
  character(:), allocatable, save :: errloc

  !! message of last error
  character(:), allocatable, save :: errmsg

  !! ierr value of last error
  integer, save :: last_ierr=0

  !! error value encoders
  integer, parameter :: &
       ERR_VARNAME = -1, &
       ERR_UNITS   = -2, &
       ERR_DTYPE   = -3


contains

  subroutine err_set( ierr, file, linenr, msg )
    !> @details set error value and strings
    integer,      intent(in) :: ierr
    character(*), intent(in) :: file
    integer,      intent(in) :: linenr
    character(*), intent(in), optional :: msg
    character(len=256) :: loc

    last_ierr = ierr
    loc = ""
    write(loc,'(a,1x,a,1x,a,1x,i0)') "file",file,"line number:", linenr
    !! delete previous
    if( allocated(errloc))deallocate( errloc )
    allocate( errloc, source=loc )

    if( present(msg)) then
       !! delete previous msg, overwrite with new
       if( allocated(errmsg))deallocate(errmsg)
       allocate(errmsg, source=msg)
    end if

  end subroutine err_set



  !> @details print location of last error to std output
  subroutine err_write( caller_file, caller_line )
    use, intrinsic :: iso_fortran_env, only: stdout => output_unit
    character(*), intent(in) :: caller_file
    integer,      intent(in) :: caller_line

    character(len=256) :: loc, msg
    !! there is no error saved
    if( last_ierr .eq. 0 ) return

    write( stdout, "(a)") repeat('=',60)
    write( stdout, "(a)") "::>> Output from err_write() subroutine:"
    write( stdout, "(a,1x,i0)") "::>> ERROR in pARTn, ierr value:",last_ierr

    !! saved error location
    loc = "Source location unknown."
    if( allocated(errloc)) then
       loc = errloc
    end if
    write(stdout, "(a,1x,a)") "::>> Source   :", trim(loc)

    !! saved error message
    msg = "Message unknown."
    if( allocated(errmsg)) then
       msg = errmsg
    end if
    write(stdout, '(a,1x,a)') "::>> Message  :", trim(msg)

    write(stdout, "(a,1x,a,1x,a,1x,i0)") "::>> Caller   :",caller_file,"line:",caller_line

    write( stdout, "(a)") repeat('=',60)
    flush(stdout)
  end subroutine err_write

  !> @details
  !! c wrapper to err_write.
  !! header:
  !!~~~~~~~~~~~~~~~~~~~{.c}
  !! void err_write( const char *file, const int line );
  !!~~~~~~~~~~~~~~~~~~~
  subroutine err_write_c( caller_file, caller_line )bind(C, name="err_write")
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), dimension(*), intent(in) :: caller_file
    integer( c_int ), value :: caller_line
    character(:), allocatable :: file
    allocate(file, source=c2f_char(caller_file))
    call err_write( file, int(caller_line) )
    deallocate( file )
  end subroutine err_write_c



  !! simple stdout write file, line to stdout. Optionally kill the program.
  subroutine merr( file, linenr )
    use iso_fortran_env, only: stdout => output_unit
    character(*), intent(in) :: file
    integer, intent(in) :: linenr
    write(stdout,*) repeat("=",80)
    write(stdout,"(1x,a,1x,a)") ":::>> ERROR IN:",trim(file)
    write(stdout,"(1x,a,1x,i0)") ":::>> LINE NUMBER:",linenr
    write(stdout,*) repeat("=",80)
    flush(stdout)
#ifdef DEBUG
    !! kill the program, don't care about corrupting the memory
    stop
#endif
  end subroutine merr


end module m_error
