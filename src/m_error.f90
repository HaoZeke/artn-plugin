module m_error


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
       ERR_VARNAME = -1


contains

  subroutine err_set( ierr, file, linenr, msg )
    !! set error value and strings
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



  subroutine err_write( caller_file, caller_line )
    !> @details print location of last error to std output
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

end module m_error
