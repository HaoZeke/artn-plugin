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
  USE units, only : DP, PI
  !
  IMPLICIT NONE
  REAL(DP), INTENT(IN) :: atom_const(4)
  REAL(DP), INTENT(INOUT) :: push(3)
  REAL(DP), EXTERNAL :: ddot, dnrm2
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
  IF ( cone_angle == 0.0_DP) THEN
     lvalid = .TRUE.
     !
     ! TODO: why is the direction multiplied by 0.1? seems kind of random ...
     !
     push(:) = cone_dir(:)
     !print*, "**disp_valid",push, norm2(push)
  ENDIF
  !
  ! When the atom is not pushed, constrain is useless
  IF (all(push(:) .EQ. 0,1)) lvalid = .TRUE.
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
subroutine constrained_draw( constrain, push )
  use units,       only : DP, PI
  implicit none

  ! Arguments
  REAL(DP), intent(in) :: constrain(4)
  REAL(DP), INTENT(INOUT) :: push(3)

  ! Local variables
  REAL(DP) :: dir(3), alfa, u(3), t, q(4), qinv(4)
  REAL(DP) :: psi, phi, v(3), qv(4), randvec(3)
  REAL(DP) :: n(3), qtmp(4), qdir(4), r

  REAL(DP), dimension(3), parameter :: ez = [0.0_DP, 0.0_DP, 1.0_DP]

  ! ...Extract the dir and solid angle 
  dir = constrain(1:3)
  dir = dir / norm2(dir)
  alfa = deg2rad( constrain(4) )
  print*, "Constrain::dir", dir, "Angle", alfa 


  ! ...Define rotation axe to go from ez to dir
  !call prdvct( ez, dir, u )
  call cross( ez, dir, u )
  u = u / norm2(u)
  ! ...define rotation angle (z.dir/|z||dir|)
  t = acos( dir(3) )
  ! ...Define quaternion change the ref from ez to dir
  ! ...Rotation: w' = q.w.qinv
  call make_quart( u, t, q, qinv )
  !sint = sin(t*0.5_DP)
  !cost = cos(t*0.5_DP)
  !q = [ cost, sint * u ]
  !qinv = [ cost, - sint * u ]

  print*, "Constrain::Rot1: u", u, "angle", t
  print*, "Constrain::quart", q
    
  
  ! ...Draw the angle phi and psi: 
  CALL RANDOM_NUMBER( randvec )
  phi = randvec(1) * 2.0_DP * PI
  psi = ( 0.5_DP - randvec(2) ) * alfa
  r = randvec(3) * 0.25_DP
  print*, "Constrain::Phi", phi, "Psi", psi, "r", r


  ! ...phi define an direction v in polar plan. 
  !!   v and dir define a plan in which psi will define the push fom dir
  v = [ cos(phi), sin(phi), 0.0_DP ]
  qv = [ 0.0_DP, v ]
  call pdtq( q, qv, qtmp )
  call pdtq( qtmp, qinv, qv )
  v = qv(2:4)
  !! Now qv (v) is in the Ref of dir
  print*, "Constrain::qv", qv
  


  ! ...Define rotation axe n to pass from dir to push 
  !call prdvct( v, dir, n )
  call cross( v, dir, n )
  ! ...qn = rotation from dir to push
  call make_quart( n, psi, q, qinv )
  !qn = [ cos(psi*0.5_DP), sin(psi*0.5_DP)* n ]
  !qninv = [ cos(psi*0.5_DP), - sin(psi*0.5_DP)* n ]
  print*, "Constrain::Rot2: n", n, "angle", psi
  print*, "Constrain::quart", q
   
  ! ...Rotation psi around n
  qdir = [ 0.0_DP, dir ]
  call pdtq( q, qdir, qtmp )
  call pdtq( qtmp, qinv, qv )
  push = qv(2:4)

  ! normalization at 0.25
  push = push * r

  
 contains

  real(DP) function deg2rad( degree )result( rad )
    use units, only : PI
    implicit none
    real(DP), intent(in) :: degree
    rad = PI * degree / 180.0_DP
  end function deg2rad
  
  subroutine cross( v, w, u )
  !subroutine prdvct( v, w, u )
    implicit none
    real(DP), intent(in) :: v(3), w(3)
    real(DP), intent(out) :: u(3)
    u(1) = v(2)*w(3) - v(3)*w(2)
    u(2) = v(3)*w(1) - v(1)*w(3)
    u(3) = v(1)*w(2) - v(2)*w(1)
  end subroutine cross
  !end subroutine prdvct

  subroutine make_quart( u, t, q, qinv )
    implicit none
    real(DP), intent(in) :: u(3), t
    real(DP), intent(out) :: q(4), qinv(4)
    real(DP) :: sint, cost
    sint = sin(t*0.5_DP)
    cost = cos(t*0.5_DP)
    q = [ cost, sint * u ]
    qinv = [ cost, - sint * u ] 
  end subroutine make_quart

  subroutine pdtq( q, p, u )
    implicit none
    real(DP), intent(in) :: q(4), p(4)
    real(DP), intent(out) :: u(4)

    u(1) = q(1)*p(1) - q(2)*p(2) - q(3)*p(3) - q(4)*p(4)
    u(2) = q(1)*p(2) + q(2)*p(1) + q(3)*p(4) - q(4)*p(3)
    u(3) = q(1)*p(3) + q(3)*p(1) + q(4)*p(2) - q(2)*p(4)
    u(4) = q(1)*p(4) + q(4)*p(1) + q(2)*p(3) - q(3)*p(2)

  end subroutine pdtq

end subroutine constrained_draw







