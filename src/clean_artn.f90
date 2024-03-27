submodule( m_setup_artn ) m_clean_artn
  use precision, only: DP
  implicit none

contains

  !> @brief
  !!   Clean and end the ARTn research to be ready for another or to stop
  !
  !> @ingroup ARTn
  !> @snippet clean_artn.f90  clean_artn
  !! visible as "clean_artn()" from C.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void clean_artn();
  !!~~~~~~~~~~~~~~~~
  MODULE SUBROUTINE clean_artn()bind(C,name="clean_artn")
    !
    !> [clean_artn]
    use artn_params, only : lrelax, linit, lbasin, lperp,                 &
         llanczos, leigen, lpush_over, lbackward, lend,               &
         iartn, istep, iinit, iperp, ieigen, nlanc, ifails,    &
         irelax, iover, istep, ismooth, fpush_factor, &
         artn_resume, lanczos_max_size,     &
         filout, &
         error_message, verbose, inewchance, in_lanczos_at_min, &
         VOID, isearch
    use m_option, only: nperp_limitation_step
    use m_artn_report, only: write_fail_report, write_comment
    use m_artn_report, only: prev_push, prev_disp
    use m_block_lanczos, only: ilanc, old_lanczos_vec, a1, lowest_eigval
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

    lrelax = .false.
    linit = .true.
    lbasin = .true.
    lperp = .false.
    llanczos = .false.
    leigen = .false.
    lpush_over = .false.

    ! Internal param
    lbackward = .true.
    in_lanczos_at_min = .false.
    fpush_factor = 1
    prev_push = VOID
    ! lend = .false.
    !
    iartn = 0
    istep = 0
    iinit = 0
    iperp = 0
    ilanc = 0
    ieigen = 0
    irelax = 0
    iover = 0
    inewchance = 0
    ismooth = 0

    ! ...Return the initial value of nperp
    call nperp_limitation_step( -1 )


    lowest_eigval = 0.0_DP
    artn_resume = ""

    if( allocated(old_lanczos_vec) )old_lanczos_vec = 0.0_DP

    ! read the ARTn input file
    !OPEN( UNIT = iunartin, FILE = filin, FORM = 'formatted', STATUS = 'unknown', IOSTAT = ios)
    !READ( NML = artn_parameters, UNIT = iunartin)
    !CLOSE ( UNIT = iunartin, STATUS = 'KEEP')

    nlanc = lanczos_max_size

    ! H = 0.0_DP
    ! Vmat = 0.0_DP

    IF( verbose > 1 )THEN
       WRITE(u0,'(/)')
       CLOSE ( UNIT = u0, STATUS = 'KEEP')
    ENDIF

    ! reset the setup status
    isetup = 0

    ! increase isearch
    isearch = isearch + 1

  END SUBROUTINE clean_artn
  !> [clean_artn]



end submodule m_clean_artn
