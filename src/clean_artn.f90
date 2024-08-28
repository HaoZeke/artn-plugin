submodule( m_setup_artn ) m_clean_artn
  use precision, only: DP
  implicit none

contains

  !> @brief
  !!   Clean and end the ARTn research to be ready for another or to stop.
  !!   The ARTn data remains allocated after this call.
  !
  !> @ingroup ARTn
  !> @snippet clean_artn.f90  clean_artn
  !! visible as "clean_artn()" from C.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void clean_artn();
  !!~~~~~~~~~~~~~~~~
  MODULE SUBROUTINE clean_artn()
    !
    !> [clean_artn]
    use artn_params, only :&
         lend, fpush_factor, artn_resume, lanczos_max_size, filout, &
         error_message, verbose, VOID, isearch, zseed
    use m_option, only: nperp_limitation_step
    use m_artn_report, only: write_fail_report, write_comment
    use m_artn_report, only: prev_push, prev_disp
    use m_block_lanczos, only: old_lanczos_vec, lowest_eigval
    implicit none

    integer :: ios, u0


    ! ...Fails if finished before it converged
    IF( .NOT.lend )then
       error_message = 'ARTn RESEARCH STOP BEFORE THE END'
       call write_fail_report( prev_disp, lowest_eigval )
    ENDIF

    ! ...Write in output log
    ! WRITE(*,'(5x,"!> CLEANING ARTn | Fail:",1x,i0)') ifails
    IF( verbose > 1 )THEN
       OPEN ( NEWUNIT = u0, FILE = filout, FORM = 'formatted', STATUS = 'old', POSITION = 'append', IOSTAT = ios )
       WRITE(u0,'(5x,"!> CLEANING ARTn | Fail:",1x,i0/5x,*(a))') ifails, repeat("-",50)
    ENDIF

    !! block flags
    call reset_blockflags()

    ! Internal param
    fpush_factor = 1
    prev_push = VOID
    !
    call local_counters_zero()

    !! reset zseed to zero, next exploration should be different by default
    zseed = 0

    ! ...Return the initial value of nperp
    call nperp_limitation_step( -1 )


    lowest_eigval = 0.0_DP
    artn_resume = ""

    if( allocated(old_lanczos_vec) )old_lanczos_vec = 0.0_DP

    nlanc = lanczos_max_size

    IF( verbose > 1 )THEN
       WRITE(u0,'(/)')
       CLOSE ( UNIT = u0, STATUS = 'KEEP')
    ENDIF

    ! reset the setup status
    isetup = 0

    ! increase isearch
    isearch = isearch + 1

  END SUBROUTINE clean_artn
  ! C-wrapper
  subroutine cclean_artn()bind(C,name="clean_artn")
    call clean_artn()
  end subroutine cclean_artn
  !> [clean_artn]



  module subroutine reset_runparams()
    use m_artn_report, only: reset_report_params
    use m_block_lanczos, only: reset_lanczos_params
    use m_error, only: reset_error

    ! block flags to initial values
    call reset_blockflags()

    ! all counters to zero, except isearch
    call local_counters_zero()
    inewchance = 0

    ! reset m_artn_report
    call reset_report_params()

    ! reset block lanczos
    call reset_lanczos_params()

    artn_resume = ""

    ! reset the error module
    call reset_error()

    ! reset the setup status
    call reset_setup()

  end subroutine reset_runparams



  !> @brief
  !!   set all counters used locally in single ARTn run to zero
  subroutine local_counters_zero()
    use m_block_lanczos, only: ilanc
    implicit none
    !! do not touch the counters of multiple explorations :: isearch, ifound, ifails
    iartn             = 0
    istep             = 0
    iinit             = 0
    iperp             = 0
    ilanc             = 0
    ieigen            = 0
    irelax            = 0
    iover             = 0
    ! inewchance        = 0  !! do inewchance manually, to keep it in memory after clean_artn()
    ismooth           = 0
  end subroutine local_counters_zero



  subroutine reset_blockflags()
    !! put block flags to initial values
    !! NOTE: set all except lend

    call flag_false()
    linit             = .true.
    lbasin            = .true.
    lbackward         = .true.
  end subroutine reset_blockflags



end submodule m_clean_artn
