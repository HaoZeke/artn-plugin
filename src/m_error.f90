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
  use m_artn_data, only: has_error
  implicit none

  !! location of last error
  character(:), allocatable, save :: errloc

  !! message of last error
  character(:), allocatable, save :: errmsg

  !! list of callers from error location to final write
  character(:), allocatable, save :: callers

  !! ierr value of last error
  integer, save :: last_ierr=0

  !! error value encoders
  integer, parameter :: &
       ERR_OTHER   = -99, &
       ERR_VARNAME = -1, &    !! wrong vriable name
       ERR_UNITS   = -2, &    !! error related to units (units not set?)
       ERR_DTYPE   = -3, &    !! wrong data type
       ERR_DRANK   = -4, &    !! wrong data rank
       ERR_FILE    = -5, &    !! error related to file in/out
       ERR_SIZE    = -6, &    !! wrong size
       ERR_DATA    = -7       !! data does not exist


contains

  !> @details
  !! Silently set error value encoder and strings into the
  !! module variables `ierr`, `errloc`, and `errmsg`, for later writing.
  !!
  !! This routine should be called at the point where error happens, to save the location and message.
  !! NOTE: any previous error message is overwritten. Thus if more than one error happens, only the last
  !!       location and message are saved.
  subroutine err_set( ierr, file, linenr, msg )
    implicit none
    integer,      intent(in) :: ierr           !! error value encoder
    character(*), intent(in) :: file           !! filename where the error happened
    integer,      intent(in) :: linenr         !! line number where the error happened
    character(*), intent(in), optional :: msg  !! error message
    character(len=256) :: loc

    last_ierr = ierr
    loc = ""
    write(loc,'(a,1x,a,1x,i0)') file,"line:", linenr
    write(*,*) "setting err:",loc
    !! delete previous
    if( allocated(errloc))deallocate( errloc )
    ! allocate( errloc, source=loc )
    errloc = loc

    if( present(msg)) then
       !! delete previous msg, overwrite with new
       if( allocated(errmsg))deallocate(errmsg)
       allocate(errmsg, source=msg)
    end if

    !! set logical in m_artn_data
    has_error = .true.

    !! set list of callers to none
    callers = ""
  end subroutine err_set


  !> @details
  !! add caller to list of callers in error message
  subroutine err_caller( file, linenr )
    implicit none
    character(*), intent(in) :: file
    integer, intent(in) :: linenr
    character(len=256) :: loc

    loc = ""
    write(loc,'(a,1x,a,1x,i0)') file,"line:", linenr
    if( len_trim(callers) < 1 ) then
       callers = "::>> Caller   : "//trim(loc)
    else
       callers = callers//achar(10)//"::>> Caller   : "//trim(loc)
    end if

  end subroutine err_caller



  !> @details
  !! Write the variables of this module to std output.
  !! Writes the information of last error to screen, does not stop the program execution.
  !!
  !! This routine should be called after some routine/function returned an error result.
  !! It will write information about the location where some routine/function has been called.
  subroutine err_write( caller_file, caller_line )
    use, intrinsic :: iso_fortran_env, only: stdout => output_unit
    implicit none
    character(*), intent(in) :: caller_file
    integer,      intent(in) :: caller_line

    character(len=256) :: loc, msg
    integer :: nlen
    !! there is no error saved
    ! if( last_ierr .eq. 0 ) return

    write( stdout, "(a)") repeat('=',60)
    write( stdout, "(a)") "::>> Output from err_write() subroutine:"
    write( stdout, "(a,1x,i0)") "::>> ERROR in pARTn, ierr value:",last_ierr

    !! saved error message
    msg = "Message unknown."
    if( allocated(errmsg)) then
       nlen = min(len(msg),len(errmsg))
       msg(1:nlen) = errmsg(1:nlen)
    end if
    write(stdout, '(a,1x,a)') "::>> Message  :", trim(msg)

    !! saved error location by err_set
    loc = "Source location unknown."
    if( allocated(errloc)) then
       nlen = min(len(msg),len(errloc))
       loc=""
       loc(1:nlen) = errloc(1:nlen)
    end if
    write(stdout, "(a,1x,a)") "::>> Source   :", trim(loc)

    !! write list of callers
    if( len_trim(callers) > 1 ) write(stdout, "(a)") trim(callers)

    !! this routine called by:
    write(stdout, "(a,1x,a,1x,a,1x,i0)") "::>> Last caller :",caller_file,"line:",caller_line

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


  !> @details
  !! reset the variables of this module
  subroutine reset_error()bind(C,name="reset_error")
    last_ierr = 0
    if( allocated( errloc))deallocate(errloc)
    if( allocated(errmsg))deallocate(errmsg)
    callers=""
    has_error = .false.
  end subroutine reset_error


  function get_error( msg )result(ierr)
    character(:), allocatable, intent(out) :: msg
    integer :: ierr

    ierr = last_ierr
    !! no error
    if( ierr == 0 ) return

    !! copy the message
    allocate(msg, source=errmsg)
  end function get_error
  !! C wrapper
  function get_cerror( cmsg ) result( cerr )bind(C,name="get_error")
    use, intrinsic :: iso_c_binding, only: c_ptr, c_int, c_null_ptr
    use m_tools, only: f2c_string
    type( c_ptr ) :: cmsg
    integer( c_int ) :: cerr
    character(:), allocatable :: fmsg
    cmsg = c_null_ptr
    cerr = int( get_error(fmsg), c_int )
    if( cerr /= 0_c_int ) cmsg = f2c_string(fmsg)
  end function get_cerror



  !! simple write file and line to stdout. Optionally kill the program.
  !! Should be used only for debug.
  subroutine merr( file, linenr, kill )
    use iso_fortran_env, only: stdout => output_unit
    character(*), intent(in) :: file
    integer, intent(in) :: linenr
    logical, intent(in), optional :: kill
    logical :: kkill
    write(stdout,*) repeat("=",80)
    write(stdout,"(1x,a,1x,a)") ":::>> ERROR IN:",trim(file)
    write(stdout,"(1x,a,1x,i0)") ":::>> LINE NUMBER:",linenr
    write(stdout,*) repeat("=",80)
    flush(stdout)
    kkill = .false.
    if( present(kill))kkill=kill
#ifdef DEBUG
    !! kill the program, don't care about corrupting the memory
    kkill = .true.
#endif
    if( kkill ) stop
  end subroutine merr


end module m_error



#ifdef DEBUG
#include "artn_debug.f90"
#endif
