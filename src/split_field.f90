submodule( m_artn_tools )splitfield_routines
  implicit none

contains

  !> @brief
  !!   Extract the parallel and perpendicular component of field
  !!   followig a reference field (fref) according to a mask.
  !!
  !> @param[in]     force       Field input
  !! @param[in]     if_pos      Constrain in field
  !! @param[in]     push        Parallel field reference
  !! @param[out]    fperp       Perpendicular force field following Push field
  !! @param[out]    fpara       Parallel force field following Push field
  !! @param[in]     nat         number of point in the field
  !
  module SUBROUTINE split_force( nat, force, if_pos, push, fperp, fpara )
    !
    use m_artn_tools, only: ddot
    IMPLICIT NONE

    ! -- ARGUMENTS
    INTEGER,  INTENT(IN)     :: nat
    REAL(DP), INTENT(IN)     :: push(3,nat)
    REAL(DP), INTENT(IN)     :: force(3,nat)
    REAL(DP), INTENT(OUT)    :: fpara(3,nat)
    REAL(DP), INTENT(OUT)    :: fperp(3,nat)
    INTEGER,  INTENT(IN)     :: if_pos(3,nat)

    ! -- LOCAL VARIABLE
    REAL(DP) :: a, b

    ! calculate components parallel to the push
    !fpara(:,:) = ddot(3*nat,force(:,:),1,push(:,:),1) / ddot(3*nat,push(:,:),1,push(:,:),1) * push(:,:)
    a = ddot(3*nat,force(:,:),1,push(:,:),1)
    b = ddot(3*nat,push(:,:),1,push(:,:),1)
    fpara(:,:) = a / b * push(:,:)

    ! subtract them
    fperp(:,:) = force(:,:) - fpara(:,:)

    ! apply constraints
    IF ( ANY(if_pos(:,:) == 0)  ) fperp(:,:) = fperp(:,:)*real(if_pos(:,:),DP)
    IF ( ANY(if_pos(:,:) == 0)  ) fpara(:,:) = fpara(:,:)*real(if_pos(:,:),DP)


  END SUBROUTINE split_force


  !> @brief
  !!   Extract the parallel and perpendicular component of field
  !!   followig a reference field (fref) according to a mask.
  !!   (Generalization of perpforce)
  !!
  !> @note 
  !!   The interface field(*) does not works with generic interface (too abstract)
  !!
  !> @param[in]     n           number of point in the field
  !! @param[in]     field       Field input
  !! @param[in]     mask        Constrain in field
  !! @param[in]     fref        Parallel direction field reference
  !! @param[out]    fperp       Perpendicular force field following dir field
  !! @param[out]    fpara       Parallel force field following dir field
  !
  !module subroutine split_field( n, field, mask, fref, fperp, fpara )
  !  !
  !  use m_artn_tools, only: ddot
  !  IMPLICIT NONE

  !  ! -- ARGUMENTS
  !  INTEGER,  INTENT(IN)     :: n
  !  REAL(DP), INTENT(IN)     :: field(*)
  !  REAL(DP), INTENT(IN)     :: fref(*)
  !  INTEGER,  INTENT(IN)     :: mask(*)
  !  REAL(DP), INTENT(OUT)    :: fpara(*)
  !  REAL(DP), INTENT(OUT)    :: fperp(*)

  !  ! -- LOCAL VARIABLE
  !  REAL(DP) :: a, b

  !  ! calculate components parallel to the dir
  !  a = ddot( n, field, 1, fref, 1 )
  !  b = ddot( n, fref, 1, fref, 1 )
  !  fpara(1:n) = a / b * fref(1:n)

  !  ! subtract them
  !  fperp(1:n) = field(1:n) - fpara(1:n)

  !  ! apply constraints
  !  IF( ANY(mask(1:n) == 0) )then
  !     fperp(1:n) = fperp(1:n)*real(mask(1:n),DP)
  !     fpara(1:n) = fpara(1:n)*real(mask(1:n),DP)
  !  endif

  !end subroutine split_field


end submodule splitfield_routines
