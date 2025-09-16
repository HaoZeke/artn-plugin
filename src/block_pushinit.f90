submodule( m_artn )push_init_routine
  implicit none
contains


  module function block_pushinit( disp_code, displ_vec )result( ierr )
    use d_artn_params, only: linit, llanczos, lperp
    use d_artn_params, only: istep, ninit, iinit
    use d_artn_params, only: INIT
    use d_artn_params, only: push
    use d_artn_data, only: natoms
    use m_artn_report, only: prev_push
    use m_block_lanczos, only: ilanc
    implicit none
    integer, intent( out ) :: disp_code
    real(DP), intent( out ) :: displ_vec(3,natoms)
    integer :: ierr

    !character(*), parameter :: here = "block_pushinit"
    !write(*,*) here,"> ", push

    ierr = 0
    !
    !=============================
    ! Send a push with initial push vector and decide what to do next: perp_relax, or lanczos
    !=============================
    ! linit flag is touched by:
    !   - initialize_artn(),
    !   - check_force_convergence()
    !   - here
    !.............................

    linit = .false.
    !
    IF ( istep == 0 .AND. ninit== 0 ) THEN
       !
       ! ...no init push to be done, pass directly to Lanczos
       llanczos = .true.
       lperp    = .false.
       !
    ELSE
       !
       ! Do init push, and switch to perp relax for next step
       iinit = iinit + 1
       disp_code = INIT
       prev_push = disp_code !! save for previous push
       !
       ! displacement equal to the push
       displ_vec(:,:) = push(:,:)
       !
       ! ...set up the flags for next step (we do an initial push, then we need to relax perpendiculary)
       lperp = .true.
       !
    ENDIF
    ilanc = 0
    !
  end function block_pushinit


end submodule push_init_routine
