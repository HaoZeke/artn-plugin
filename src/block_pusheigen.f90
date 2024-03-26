submodule( m_artn ) pusheigen_routine
  implicit none
contains

  module function block_pusheigen( disp_code, displ_vec )result(ierr)

    use artn_params, only: lperp
    use artn_params, only: ismooth, nsmooth, ieigen, neigen
    use artn_params, only: natoms
    use artn_params, only: EIGN, SMTH
    use artn_params, only: push, eigenvec, force_step, eigen_step_size, lowest_eigval
    use artn_params, only: current_step_size
    use m_artn_report, only: prev_push
    use m_block_lanczos, only: ilanc
    use m_option, only: smooth_interpol

    implicit none
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3,natoms)
    integer :: ierr

    real(DP) :: fpara_tot
    real(DP), external :: ddot

    ierr = 0
    !================================================
    ! Push in the direction of the lowest eigenvector
    !================================================
    !
    ! leigen is .true. after we obtain a good eigenvector
    ! if we have a good lanczos eigenvector use it as push vector
    !
    !
    disp_code = EIGN
    ismooth   = ismooth + 1
    ieigen    = ieigen  + 1


    ! ...reset the iterator of previous step
    ilanc   = 0


    ! ...Apply the smooth linear combination to the eigenvector
    IF( nsmooth > 0 .AND. ismooth <= nsmooth )THEN
       CALL smooth_interpol( ismooth, nsmooth, natoms, force_step, push, eigenvec )  !! array PUSH change
       disp_code = SMTH
    ELSE
       push(:,:) = eigenvec(:,:)
    ENDIF

    !! save previous push code for ...?
    prev_push = disp_code
    !
    ! rescale the eigenvector according to the current force in the parallel direction
    ! see Cances_JCP130: some improvements of the ART technique doi:10.1063/1.3088532
    ! 0.13 is taken from ARTn, 0.5 eV/Angs^2 corresponds roughly to 0.01 Ry/Bohr^2
    !
    ! ...Recompute the norm of fpara because eigenvec (push) change a bit
    fpara_tot = ddot(3*natoms, force_step, 1, push, 1)
    !
    current_step_size = -SIGN(1.0_DP,fpara_tot)*MIN(eigen_step_size,ABS(fpara_tot)/MAX( ABS(lowest_eigval), 0.01_DP ))
    !
    ! Put some test on current_step_size
    !
    displ_vec(:,:) = push(:,:) * current_step_size
    !
    IF( ieigen >= neigen )THEN
       ! do a perpendicular relax
       lperp = .true.
    ENDIF
    !
    ! Write the latest eigenvec to a file (eigenvec should be in force position)
    !
    ! CALL write_struct( at, nat, tau_step, elements, types, eigenvec, &
    !      etot_eng, 1.0_DP, struc_format_out, eigenfname )
    !

  end function block_pusheigen

end submodule pusheigen_routine
