!
!> @author
!!  Matic Poberznik, 
!!  Miha Gunde,
!!  Nicolas Salles,
!!  Antoine Jay
!!
!> @brief
!!   OPTION: defined by a flag associate to one or more routines
!
module m_artn_option

  use h_artn_precision, only : DP
  implicit none

  ! FLAGS
  !logical :: lnextmin

  

  !! move_nextmin.f90
  ! .....................................................................................
  !> @fn move_nextmin( nat, typ, pos, order )
  !!
  !> @brief
  !!   Load the structure corresponding to min furthest from initial configuration,
  !!   into the engine arrays.
  !> @note
  !!   Called in LCONV block in artn()
  !!
  !> @param[in] nat :: number of atoms
  !> @param[out] typ :: atomic types
  !> @param[out] pos :: atomic positions
  !> @param[in] order :: atomic indices
  !!
  !> @ingroup Control
  interface move_nextmin
    module procedure move_nextmin
  end interface
  interface
    module subroutine move_nextmin( nat, typ, pos, order )
      !IMPORT DP
      INTEGER, INTENT(in) :: nat
      integer, intent(out) :: typ(nat)
      REAL(DP), INTENT(out) :: pos(3,nat)
      integer, intent(in) :: order(nat)
    end subroutine move_nextmin
  end interface


  !! smooth_interpol.f90
  ! .....................................................................................
  !> @fn smooth_interpol( nat, typ, pos, order )
  !!
  !> @brief Smooth Interpolation
  !!
  !> @par Purpose
  !  ============ 
  !>   Return a smooth interpolation v2 betwwen 2 field v1 and v2:
  !>   - v2 is a linear combination between v1 and v2
  !>   - v2= v1 when ismooth = 0       -> done in init
  !>   - v2= V2 when ismooth = nsmooth -> done in eigen 
  !!
  !> @param[in,out]  ismooth  actual smooth step 
  !> @param[in]      nsmooth  max smooth step 
  !> @param[in]      nat      number of atom
  !> @param[in]      v0       the actual orientation
  !> @param[in,out]  v1       the direction we come
  !> @param[in]      v2       the direction we go
  !!
  !> @ingroup Control
  !
  interface smooth_interpol
    module procedure smooth_interpol
  end interface
  interface
    MODULE SUBROUTINE smooth_interpol( ismooth, nsmooth, nat, v0, v1, v2 )
      INTEGER,  INTENT( INOUT ) :: ismooth   ! degree of interpolation
      INTEGER,  INTENT( IN )    :: nsmooth   ! number of degree of interpolation
      INTEGER,  INTENT( IN )    :: nat       ! number of points in 3D field
      REAL(DP), INTENT( IN )    :: v0(3,nat) ! Actuel field
      REAL(DP), INTENT( INOUT ) :: v1(3,nat) ! Orientation field 1
      REAL(DP), INTENT( IN )    :: v2(3,nat) ! Orientation field 2
    end subroutine smooth_interpol
  end interface

  !! restart.f90
  ! .....................................................................................
  !> @fn write_restart()
  !!
  !> @brief
  !!   write a file with artn parameters and data needed to restart a calculation
  !> @ingroup Control
  interface write_restart
    module procedure write_restart
  end interface 
  interface
    module subroutine write_restart()
    end subroutine write_restart
  end interface 

  !> @fn read_restart( lerror )
  !!
  !> @brief
  !! read variables from a restart file, and overwrite the data to continue computation
  !! from the restart point.
  !!
  !> @param[out]   lerror   logical flag for error during the reading
  !!
  !> @ingroup Control
  interface read_restart
    module procedure read_restart
  end interface
  interface
    module subroutine read_restart( lerror )
      logical, intent(out) :: lerror
    end subroutine read_restart
  end interface


  !! nperp_limitation.f90
  ! .....................................................................................
  !> @fn nperp_limitation_step( increment )
  !!
  !> @brief
  !!   increment in the list only if the actual perp-relax finished
  !!
  !> @param[in]  increment   command {-1,0,1} allows to show what it does
  !!
  !> @ingroup Control
  interface nperp_limitation_step
    module procedure nperp_limitation_step
  end interface
  interface
    module subroutine nperp_limitation_step( increment )
      integer, intent(in) :: increment
    end subroutine nperp_limitation_step
  end interface

  !> @fn nperp_limitation_init( flag )
  !!
  !> @brief manage the max perp-relax iteration
  !!
  !> @verbatim
  !> the nperp are stored in array nperp_limitation() with in
  !> first element the value of nperp if exist and in last the
  !> nperp_end. The last element is repeated until the end of research
  !> Values:
  !>  -2 nothing
  !>  -1 no limitation
  !>  {0,1,...} nperp limit
  !> @endverbatim
  !!
  !> @param[in]    flag      true/false to use nperp_limitation
  !!
  !> @ingroup Control
  interface nperp_limitation_init
    module procedure nperp_limitation_init
  end interface
  interface
    module subroutine nperp_limitation_init( flag )
      logical, intent(in) :: flag
    end subroutine nperp_limitation_init
  end interface


  !! constrained_draw.f90
  !...........................................................................................
  !> @fn constrained_draw( constrain, push )
  !!
  !> @brief
  !!   The random push is contained in solid cone of angle [alfa = constrain(4)]
  !!   oriented by direction [dir = constrain(1:3)]
  !!
  !> @verbatim
  !!   The method is to draw 2 random number
  !!   - phi in [0,2Pi]: angle in polar plan oriented by dir -> v
  !!   - psi in [-alfa,alfa]: angle of push with dir oriented by phi
  !!   Concretely dir will be the Ref, so it needs 2 rotation (Ref change)
  !!   1) rotation to align ez with dir to align v
  !!   2) rotation psi in the plan (dir,v) around axe n to align dir with push
  !> @endverbatim
  !!
  !> @param[in]     constrain     vector contains solid angle
  !> @param[out]    push          push direction vector
  !!
  !> @ingroup Control
  interface constrained_draw
    module procedure constrained_draw
  end interface
  interface
    module SUBROUTINE constrained_draw( constrain, push )
      !IMPORT                  :: DP
      REAL(DP), INTENT(IN)    :: constrain(4)
      REAL(DP), INTENT(INOUT) :: push(3)
    END SUBROUTINE constrained_draw
  end interface

 CONTAINS

  !include "move_nextmin.f90"
!#include "move_nextmin.f90"

end module m_artn_option
