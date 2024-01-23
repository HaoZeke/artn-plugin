
!> @note
!!   OPTION: defined by a flag associate to one or more routines

module option

  use units, only : DP
  implicit none

  ! FLAGS
  !logical :: lnextmin

  interface

    ! NEXTMIN
    SUBROUTINE move_nextmin( nat, pos )
      USE UNITS, only : DP
      USE artn_params, only : tau_nextmin, etot_init, etot_final
      implicit none
      INTEGER, INTENT(in) :: nat
      REAL(DP), INTENT(inout) :: pos(3,nat)
    end subroutine move_nextmin
    SUBROUTINE save_min( nat, pos )
      USE UNITS, only : DP, unconvert_length
      USE artn_params, only : tau_init, lat, tau_nextmin
      implicit none
      INTEGER,  INTENT(in) :: nat
      REAL(DP), INTENT(inout) :: pos(3,nat)  ! it is in ARTn units (bohr) 
    END SUBROUTINE save_min

    ! SMOOTH INTERPOLATION
    SUBROUTINE smooth_interpol( ismooth, nsmooth, nat, v0, v1, v2 )
      USE units,       ONLY : DP
      USE artn_params, ONLY : iunartout,  dot_field, filout, verbose
      IMPLICIT NONE
      INTEGER,  INTENT( INOUT ) :: ismooth   ! degree of interpolation
      INTEGER,  INTENT( IN )    :: nsmooth   ! number of degree of interpolation
      INTEGER,  INTENT( IN )    :: nat       ! number of points in 3D field
      REAL(DP), INTENT( IN )    :: v0(3,nat) ! Actuel field
      REAL(DP), INTENT( INOUT ) :: v1(3,nat) ! Orientation field 1
      REAL(DP), INTENT( IN )    :: v2(3,nat) ! Orientation field 2
    end subroutine smooth_interpol

    ! RESTART
    SUBROUTINE write_restart( filnres )
      implicit none
      CHARACTER(LEN=255), INTENT(IN) :: filnres
    end SUBROUTINE write_restart
    SUBROUTINE read_restart( filnres, nat, ityp, ierr )
      implicit none
      CHARACTER (LEN=255), INTENT(IN) :: filnres
      INTEGER, INTENT( IN ) :: nat
      !INTEGER, intent( in ) :: order(nat)
      INTEGER, intent( inout ) :: ityp(nat)   !> We change them or use them
      LOGICAL, intent( out ) :: ierr
    end subroutine read_restart

  end interface

 CONTAINS


end module option
