module artn_api2
  use, intrinsic :: iso_c_binding
  use precision, only: DP
  implicit none

contains

  function artn_create()result( ierr )bind(C, name = "artn_create" )
    use artn_params, only: called_from, filin, verbose
    use units, only: CALLER_IS_API, NAN_STR
    implicit none
    integer :: ierr

    ierr = 0

    !! set called_from
    called_from = CALLER_IS_API

    !! modify input filename to undefined str
    filin = NAN_STR

    !! modify verbose to zero
    verbose = 0

    write(*,*) "CF", called_from
  end function artn_create


  subroutine artn_destroy()bind(C, name = "artn_destroy" )
    !! deallocate params and data, unlink pointers, etc.
    !! Maybe not needed actually, there is nothing to do?
  end subroutine artn_destroy


  subroutine artn_merr( cfile, linenr )bind(C, name="artn_merr")
    use m_error, only: merr
    use m_tools, only: c2f_char
    use, intrinsic :: iso_fortran_env, only: stdout => output_unit
    implicit none
    character(len=1, kind=c_char), intent(in) :: cfile(*)
    integer, intent(in) :: linenr
    character(:), allocatable :: file

    allocate( file, source=c2f_char(cfile))
    write(stdout, *) repeat("=",40)
    write(stdout,"(a,1x,a,1x,a,1x,i0)") ">> API call to write_err called from:",trim(file),"line:",linenr
    deallocate( file )
    call merr( __FILE__, __LINE__, kill=.true.)
  end subroutine artn_merr


  !! already available routines in src
  ! function artn_get_param_datatype( cname, ierr )result(dtype)bind(C,name="artn_get_param_datatype")
  ! end function artn_get_param_datatype
  ! function artn_get_param_datarank( cname, ierr ) result( drank )bind(C,name="artn_get_param_datarank")
  ! end function artn_get_param_datarank
  ! subroutine artn_set_param()bind(C, name="artn_set_param" )
  ! end subroutine artn_set_param
  ! subroutine artn_get_param()bind(C, name="artn_get_param" )
  ! end subroutine artn_get_param


  !! dump_input

  !! serialize

  !! read_generated


  !! get_data things.

  !! get_mem things.



end module artn_api2
