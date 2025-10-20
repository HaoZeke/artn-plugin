submodule( m_artn_tools )splitfield_routines
  implicit none

contains

  !> @brief
  !!   Extract the parallel and perpendicular component of field
  !!   followig a reference field (fref) according to a mask.
  !!
  !> @param[in]     nat         number of atoms in the field
  !! @param[in]     force       Field input
  !! @param[in]     if_pos      Constrain in field
  !! @param[in]     push        Parallel field reference
  !! @param[out]    fperp       Perpendicular force field following Push field
  !! @param[out]    fpara       Parallel force field following Push field
  !
  module subroutine split_field( nat, force, if_pos, push, fperp, fpara )
    !
    use m_artn_tools, only: ddot
    IMPLICIT NONE

    ! -- ARGUMENTS
    INTEGER,  INTENT(IN)     :: nat
    REAL(DP), INTENT(IN)     :: force(3,nat)
    INTEGER,  INTENT(IN)     :: if_pos(3,nat)
    REAL(DP), INTENT(IN)     :: push(3,nat)
    REAL(DP), INTENT(OUT)    :: fpara(3,nat)
    REAL(DP), INTENT(OUT)    :: fperp(3,nat)

    ! -- LOCAL VARIABLE
    REAL(DP) :: a, b

    ! force component parallel to the push
    a = ddot(3*nat,force(:,:),1,push(:,:),1) ! a = dot_product( force, push )
    b = ddot(3*nat,push(:,:),1,push(:,:),1)  ! b = dot_product( push, push )
    fpara(:,:) = a / b * push(:,:)

    ! force component perpendicular to the push:
    ! subtract parallel from total
    fperp(:,:) = force(:,:) - fpara(:,:)

    ! apply constraints
    IF ( ANY(if_pos(:,:) == 0)  ) fperp(:,:) = fperp(:,:)*real(if_pos(:,:),DP)
    IF ( ANY(if_pos(:,:) == 0)  ) fpara(:,:) = fpara(:,:)*real(if_pos(:,:),DP)


  end subroutine split_field


end submodule splitfield_routines
