!> @author
!!  Matic Poberznik
!!  Miha Gunde
!!  Nicolas Salles

!> @brief
!!    Initialize the push and eigenvec arrays following the mode keyword
!
!> @par Purpose
!  ============
!> MIHA <= Move in push_init \n
!! use force input as mask for push_ids when calling push_init for eigenvec. \n
!! Why? To not generate initial lanczos vec for fixed atoms.
!
!> @param[in]   idum       seed for random number
!> @param[in]   nat        number of point
!! @param[out]  push       array(3*nat) push of atom
!! @param[out]  eigenvec   array(3*nat) eigenvec for lanczos
!
SUBROUTINE start_guess( idum, nat, push, eigenvec )
  !
  USE units,       ONLY : DP
  USE artn_params, ONLY : push_mode, push_step_size, push_step_size_per_atom, push_add_const, push_dist_thr,   &
                          lat, tau_step, eigen_step_size, push_guess, eigenvec_guess, &
                          push_ids, iunartout, filout, verbose, lUSER_CHOOSE_PER_ATOM
  !
  IMPLICIT NONE
  !
  ! Arguments
  INTEGER,  INTENT(IN)  :: nat, idum
  REAL(DP), INTENT(OUT) :: push(3,nat)
  REAL(DP), INTENT(OUT) :: eigenvec(3,nat)
  !
  ! Local variables
  INTEGER               :: dummy(nat)
  REAL(DP)              :: push_size
  !
  IF( verbose >1 ) OPEN ( UNIT = iunartout, FILE = filout, FORM = 'formatted', POSITION = 'append', STATUS = 'OLD' )
  !
  ! The PUSH vector
  SELECT CASE( TRIM(push_mode) )
     !
  CASE( 'all', 'list', 'rad' )
     !
     IF( verbose>1 ) WRITE(iunartout,'(5x,"|> First PUSH vectors almost RANDOM")')
     !
     push_size = push_step_size
     IF( lUSER_CHOOSE_PER_ATOM ) push_size = push_step_size_per_atom
     !
     ! generate push vector
     CALL push_init( nat, tau_step, lat, idum, push_ids, push_dist_thr, push_add_const, &
          push_size, push_mode, push )
     !
  CASE( 'file' )
     !
     ! read from file
     IF( verbose >1 ) WRITE(iunartout,'(5x,"|> PUSH vectors read in file",1x,a)') TRIM(push_guess)
     CALL read_guess( idum, nat, push, push_guess )
     !
  CASE( "input" )
     !
     ! do nothing here, push vector is already copied from artn_data in refresh_artn()
  END SELECT
  !
  ! generate EIGENVEC:
  SELECT CASE( trim(eigenvec_guess) )
     !
  CASE( 'file' )
     !
     !! read from file
     IF( verbose>1 ) WRITE(iunartout,'(5x,"|> First EIGEN vectors read in file",1x,a)') TRIM(eigenvec_guess)
     CALL read_guess( idum, nat, eigenvec, eigenvec_guess )
     !
  CASE( 'input' )
     !
     ! do nothing here, eigenvec is already copied from artn_data in refresh_artn()
     write(*,*) "eigenvec guess from input"
     write(*,*) eigenvec(:,1)

  CASE default
     !
     !! generate random
     IF( verbose>1 ) WRITE(iunartout,'(5x,"|> First EIGEN vectors RANDOM")')
     push_add_const = 0
     !! Replace Mask on norm(force) by keyword 'list_force'.
     !! keyword 'bias_force' = orient the randomness on the actual atomic forces
     call push_init( nat, tau_step, lat, idum, dummy, push_dist_thr, push_add_const, &
          eigen_step_size, 'list_force', eigenvec )
     !
  END SELECT
  !
  IF( verbose>1 ) CLOSE(UNIT=iunartout, STATUS='KEEP')
  !
END SUBROUTINE start_guess
