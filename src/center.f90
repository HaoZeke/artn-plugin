!
!> @author Matic Poberznik
!! @author Miha Gunde
!! @author Nicolas Salles
!
!> @brief
!!   takes as input a vector of size (3,nat) and centers it to the geometric center
!
!! @param[inout]  vec    output vector
!> @param[in]     nat    number of atom
!
SUBROUTINE center ( vec, nat )
  !
  USE units, ONLY: DP
  !
  !
  IMPLICIT none
  INTEGER,  INTENT(IN) :: nat             !> Size of vec array: Number of atom
  REAL(DP), INTENT(INOUT) :: vec(3,nat)   !> Vector will be centered
  INTEGER :: na
  REAL(DP) :: delta(3)
  !
  ! get geometric center
  !
  delta(:) = 0.D0
  DO na = 1,nat
     delta(:) = delta(:) + vec(:,na)
  ENDDO
  delta(:) = delta(:)/dble(nat)
  !
  ! shift vec to geometric center
  !
  DO na = 1, nat
      vec(:,na) = vec(:,na) - delta(:)
  ENDDO
  !
END SUBROUTINE center
