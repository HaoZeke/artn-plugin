
!> @note
!!   OPTION: defined by a flag associate to one or more routines

module m_option

  use precision, only : DP
  implicit none

  ! FLAGS
  !logical :: lnextmin

  interface

    !! nextmin.f90
    module subroutine move_nextmin( nat, pos )
      INTEGER, INTENT(in) :: nat
      REAL(DP), INTENT(inout) :: pos(3,nat)
    end subroutine move_nextmin
    module subroutine save_min( nat, pos )
      INTEGER,  INTENT(in) :: nat
      REAL(DP), INTENT(inout) :: pos(3,nat)  ! it is in ARTn units (bohr) 
    END SUBROUTINE save_min


    !! smooth_interpol.f90
    MODULE SUBROUTINE smooth_interpol( ismooth, nsmooth, nat, v0, v1, v2 )
      INTEGER,  INTENT( INOUT ) :: ismooth   ! degree of interpolation
      INTEGER,  INTENT( IN )    :: nsmooth   ! number of degree of interpolation
      INTEGER,  INTENT( IN )    :: nat       ! number of points in 3D field
      REAL(DP), INTENT( IN )    :: v0(3,nat) ! Actuel field
      REAL(DP), INTENT( INOUT ) :: v1(3,nat) ! Orientation field 1
      REAL(DP), INTENT( IN )    :: v2(3,nat) ! Orientation field 2
    end subroutine smooth_interpol


    !! restart.f90
    MODULE SUBROUTINE write_restart( filnres )
      CHARACTER(LEN=255), INTENT(IN) :: filnres
    end subroutine write_restart
    MODULE SUBROUTINE read_restart( filnres, nat, ityp, ierr )
      CHARACTER (LEN=255), INTENT(IN) :: filnres
      INTEGER, INTENT( IN ) :: nat
      INTEGER, intent( inout ) :: ityp(nat)   !> We change them or use them
      LOGICAL, intent( out ) :: ierr
    end subroutine read_restart


    !! nperp_limitation.f90
    module subroutine nperp_limitation_step( increment )
      integer, intent(in) :: increment
    end subroutine nperp_limitation_step
    module subroutine nperp_limitation_init( flag )
      logical, intent(in) :: flag
    end subroutine nperp_limitation_init

  end interface

 CONTAINS


end module m_option
