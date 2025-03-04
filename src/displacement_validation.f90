!> @author
!!  Matic Poberznik,
!!  Miha Gunde, 
!!  Nicolas Salles
!
!> @brief
!!   subroutine that checks if the initial_displacement is within given parameters
!
!> @param [in]      atom_const  Constrain Applied on the atom
!> @param [inout]   push        Direction of the push applied on the atoms
!> @param [inout]   lvalid      Flag to know if the random displacement correspond to the constrain
!
SUBROUTINE displacement_validation( atom_const, push, lvalid)
  !
  use precision, only: DP
  USE units, only : PI, EPS
  use m_tools, only: ddot, dnrm2
  !
  IMPLICIT NONE
  REAL(DP), INTENT(IN) :: atom_const(4)
  REAL(DP), INTENT(INOUT) :: push(3)
  LOGICAL,         INTENT(INOUT) :: lvalid
  !
  ! Local variables
  REAL(DP)               :: cone_angle, displacement_angle
  REAL(DP)               :: dot_prod, displacement_norm, cone_dir_norm
  REAL(DP), DIMENSION(3) :: cone_dir,displacement
  !
  !
  !
  !write (*,*) " * ARTn: Called displacement validation:", atom_id 
  !write(*,*) " with cone_dir:",atom_const(1:3), "current push:", push(:)
  cone_dir = atom_const(1:3)
  cone_angle = atom_const(4)
  !print*, 
  !
  displacement(:)         = push(:)
  !
  displacement_norm       = dnrm2(3,displacement,1)
  cone_dir_norm           = dnrm2(3,cone_dir,1)
  !
  dot_prod                = ddot( 3, cone_dir, 1, displacement, 1 ) / ( cone_dir_norm * displacement_norm )
  displacement_angle      = ACOS( dot_prod ) *180.0_DP / PI
  lvalid                  = ( displacement_angle < cone_angle )
  !write (*,*) "Finished displacement validation",lvalid  !&
          !, displacement_norm, cone_dir_norm, dot_prod, displacement_angle, atom_const
  !
  !IF ( cone_angle == 0.0_DP) THEN
  IF ( cone_angle <= EPS ) THEN
     lvalid = .TRUE.
     !
     ! TODO: why is the direction multiplied by 0.1? seems kind of random ...
     !
     push(:) = cone_dir(:)
     !print*, "**disp_valid",push, norm2(push)
  ENDIF
  !
  ! When the atom is not pushed, constrain is useless
  !IF (all(push(:) .EQ. 0,1)) lvalid = .TRUE.
  IF (all(push(:) < EPS,1)) lvalid = .TRUE.
  !
END SUBROUTINE displacement_validation

!...........................................................................................
!> @author
!!  Matic Poberznik,
!!  Miha Gunde, 
!!  Nicolas Salles
!
!> @brief
!!   The random push is contained in solid cone of angle [alfa = constrain(4)] 
!!   oriented by direction [dir = constrain(1:3)]
!
!> @note
!!   The method is to draw 2 random number 
!!   - phi in [0,2Pi]: angle in polar plan oriented by dir -> v
!!   - psi in [-alfa,alfa]: angle of push with dir oriented by phi
!!   Concretely dir will be the Ref, so it needs 2 rotation (Ref change)
!!   1) rotation to align ez with dir to align v
!!   2) rotation psi in the plan (dir,v) around axe n to align dir with push
!
!> @param[in]     constrain     vector contains solid angle
!> @param[out]    push          push direction vector
!
SUBROUTINE constrained_draw( constrain, push )
  !  
  USE precision,  ONLY: DP
  USE units,      ONLY: PI, EPS
  USE m_tools,    ONLY: ARTN_RANDOM_NUMBER
  !
  IMPLICIT NONE
  !
  ! Arguments
  REAL(DP), INTENT(IN)              :: constrain(4)
  REAL(DP), INTENT(INOUT)           :: push(3)
  !
  ! Local variables
  REAL(DP)                          :: dir(3), alfa, u(3), t, q(4), qinv(4)
  REAL(DP)                          :: psi, phi, v(3), qv(4), randvec(2)
  REAL(DP)                          :: n(3), qtmp(4), qdir(4)
  REAL(DP), dimension(3), parameter :: ez = [0.0_DP, 0.0_DP, 1.0_DP]

  !
  ! ... Extract the dir and solid angle 
  dir  = constrain(1:3)
  dir  = dir / NORM2(dir)
  alfa = deg2rad( constrain(4) )
  !
  ! ... Define the rotation to go from ez to dir if usefull
  IF ( ABS(DOT_PRODUCT(ez,dir))-1.0_DP < EPS ) THEN
     u = dir
     t = 0.0_DP
  ELSE
     CALL cross( ez, dir, u )           ! u is the axe of the rotation 
     u = u / NORM2(u)                   ! normalized
     t = ACOS( dir(3) )                 ! t is the rotation angle (z.dir/|z||dir|)
  ENDIF  
  CALL make_quart( u, t, q, qinv )      ! q and qinv are the quaternion for the rotation: w' = q.w.qinv

  !
  ! ... Define random angles phi and psi needed to be randomly positioned into the cone 
  CALL ARTN_RANDOM_NUMBER( randvec(1) )
  CALL ARTN_RANDOM_NUMBER( randvec(2) )
  phi = randvec(1) * 2.0_DP * PI        ! Is in [0;2PI]
  psi = ( 0.5_DP - randvec(2) ) * alfa  ! Is in [-alpha;alpha]

  !
  ! ... First Rotation  of q around v and angle phi
  v  = [ cos(phi), sin(phi), 0.0_DP ]   ! v and dir define a plan in which psi will define the push fom dir
  qv = [ 0.0_DP, v ]                    ! quaternion associated to v
  CALL pdtq( q, qv, qtmp )
  CALL pdtq( qtmp, qinv, qv )
  v  = qv(2:4)                          ! v is in the Ref of dir

  !
  ! ... Second Rotation around axis n angle psi 
  CALL cross( v, dir, n )               ! n is the rotation axis to pass from dir to push with angle psi 
  CALL make_quart( n, psi, q, qinv )    ! q and qinv are the quaternions for the rotation 
  qdir = [ 0.0_DP, dir ]                ! quaternion associated to dir
  CALL pdtq( q, qdir, qtmp )
  CALL pdtq( qtmp, qinv, qv )
  push = qv(2:4)                        ! final push vector randomly in a cone directed by dir and of angle alpha

  !
  ! ... Normalized by the size asked by user. The 3Nat vector will be further normalized to push_size
  push = push * NORM2(constrain(1:3))
  !
 CONTAINS

  REAL(DP) FUNCTION deg2rad( degree ) RESULT( rad )
    USE units, ONLY : PI
    IMPLICIT NONE
    REAL(DP), INTENT(IN) :: degree
    !
    rad = PI * degree / 180.0_DP
    !
  ENDFUNCTION deg2rad
  
  SUBROUTINE cross( v, w, u )
    IMPLICIT NONE
    REAL(DP), INTENT(IN)  :: v(3), w(3)
    REAL(DP), INTENT(OUT) :: u(3)
    !
    u(1) = v(2)*w(3) - v(3)*w(2)
    u(2) = v(3)*w(1) - v(1)*w(3)
    u(3) = v(1)*w(2) - v(2)*w(1)
    !
  ENDSUBROUTINE cross

  SUBROUTINE make_quart( u, t, q, qinv )
    IMPLICIT NONE
    REAL(DP), INTENT(IN)  :: u(3), t
    REAL(DP), INTENT(OUT) :: q(4), qinv(4)
    REAL(DP)              :: sint, cost
    !
    sint = sin(t*0.5_DP)
    cost = cos(t*0.5_DP)
    q = [ cost, sint * u ]
    qinv = [ cost, - sint * u ] 
    !
  ENDSUBROUTINE make_quart

  SUBROUTINE pdtq( q, p, u )
    IMPLICIT NONE
    REAL(DP), INTENT(IN)  :: q(4), p(4)
    REAL(DP), INTENT(OUT) :: u(4)
    !
    u(1) = q(1)*p(1) - q(2)*p(2) - q(3)*p(3) - q(4)*p(4)
    u(2) = q(1)*p(2) + q(2)*p(1) + q(3)*p(4) - q(4)*p(3)
    u(3) = q(1)*p(3) + q(3)*p(1) + q(4)*p(2) - q(2)*p(4)
    u(4) = q(1)*p(4) + q(4)*p(1) + q(2)*p(3) - q(3)*p(2)
    !
  ENDSUBROUTINE pdtq

ENDSUBROUTINE constrained_draw
