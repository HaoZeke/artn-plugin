submodule( m_artn )pushover_routine
  implicit none



contains

  module function block_pushover( disp_code, displ_vec )result(ierr)
    use m_artn_data, only: natoms
    use m_artn_data, only: eigen_sad
    use m_artn_data, only: etot_step, etot_sad

    use artn_params, only: lpush_final, lperp, leigen, llanczos, lbackward, lrelax, lpush_over
    use artn_params, only: eigenvec
    use artn_params, only: OVER, iover, irelax
    use artn_params, only: fpush_factor
    use m_tools, only: push_over_procedure
    use m_tools, only: dnrm2
    implicit none
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3, natoms)
    integer :: ierr


    ierr = 0

    ! set convergence and other flags to false
    lperp    = .false.
    leigen   = .false.
    llanczos = .false.
    !
    ! normalize eigenvector
    IF( lbackward ) THEN
       !! reset eigenvector to saddle
       eigenvec(:,:) = eigen_sad(:,:)
       lbackward     = .false.
       etot_step     = etot_sad
    ELSE
       !! Normalize it to be sure
       eigenvec(:,:) = eigenvec(:,:)/dnrm2(3*natoms,eigenvec,1)
    ENDIF
    !
    !
    ! ... do one step of push_over_procedure
    if( iover == 0 ) then
       disp_code = OVER
       call push_over_procedure( natoms, eigenvec, fpush_factor, displ_vec )
       iover = 1
       !! iover is re-set to 0 in the lrelax block
    else
       !! already did push_over_procedure, start relax
       if( .not. lrelax ) irelax = 0
       lrelax = .true.
       lpush_over = .false.
    end if
    !
  end function block_pushover

end submodule pushover_routine
