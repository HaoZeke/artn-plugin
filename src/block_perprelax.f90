submodule( m_artn )perprelax_routine
  implicit none

contains

  module function block_perprelax( nat, fperp, disp_code, displ_vec )result(ierr)
    use m_artn_data, only: natoms
    use artn_params, only: iperp, PERP
    use artn_params, only: error_message
    implicit none
    integer, intent(in) :: nat
    real(DP), intent(in) :: fperp(3,nat)
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3,natoms)
    integer :: ierr

    integer :: i
    real(DP) :: z

    ierr = 0
    !
    !===============================================
    ! Relax forces perpendicular to eigenvector/push
    !===============================================
    ! lperp is touched by:
    !   - initialize_artn(),
    !   - check_force_convergence()
    !   - here
    !.............................
    !
    disp_code = PERP
    !
    ! displacement is the perpendicular force
    displ_vec(:,:) = fperp(:,:)
    !
    iperp = iperp + 1
    !
    !! Here we do a last verification on displ_vec to detect
    !! the box explosion
    !! -> Stop the search if one of displacement has 5 number
    z = 0.0_DP
    do i = 1,nat
       z = max( z, norm2(displ_vec(:,i)) )
    enddo
    IF( nat /= natoms .OR. z > 1.0e4 )THEN
       error_message = "BOX EXPLOSION"
       ierr = -1  !! Stop the research
    ENDIF
    !
    !

  end function block_perprelax

end submodule perprelax_routine
