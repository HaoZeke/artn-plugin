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
!> @param[in]   nat        number of point
!! @param[out]  push       array(3*nat) push of atom
!! @param[out]  eigenvec   array(3*nat) eigenvec for lanczos
!
SUBROUTINE start_guess( nat, push, eigenvec )
  !
  USE units,       ONLY : DP
  USE artn_params, ONLY : push_mode, push_step_size, push_step_size_per_atom, push_add_const, push_dist_thr,   &
                          lat, tau_step, eigen_step_size, push_guess, eigenvec_guess, &
                          push_ids, filout, verbose, lUSER_CHOOSE_PER_ATOM, &
                          push_initial_vector
  !
  IMPLICIT NONE
  !
  ! Arguments
  INTEGER,  INTENT(IN)  :: nat
  REAL(DP), INTENT(OUT) :: push(3,nat)
  REAL(DP), INTENT(OUT) :: eigenvec(3,nat)
  !
  ! Local variables
  INTEGER               :: dummy(nat)
  REAL(DP)              :: push_size
  INTEGER               :: u0
  !
  IF( verbose >1 ) OPEN ( NEWUNIT=u0, FILE = filout, FORM = 'formatted', POSITION = 'append', STATUS = 'unknown' )
  !
  ! The PUSH vector
  SELECT CASE( TRIM(push_mode) )
     !
  CASE( 'all', 'list', 'rad' )
     !
     IF( verbose>1 ) WRITE(u0,'(5x,"|> First PUSH vectors almost RANDOM")')
     !
     push_size = push_step_size
     IF( lUSER_CHOOSE_PER_ATOM ) push_size = push_step_size_per_atom
     !
     ! generate push vector
     !CALL push_init( nat, tau_step, lat, push_ids, push_dist_thr, push_add_const, &
     !     push_size, push_mode, push )
     CALL push_init_new( nat, tau_step, lat, push_ids, push_dist_thr, push_add_const, &
                         push_size, push_mode, push )
     !
  CASE( 'file' )
     !
     ! read from file
     IF( verbose >1 ) WRITE(u0,'(5x,"|> PUSH vectors read in file",1x,a)') TRIM(push_guess)
     CALL read_guess( nat, push, push_guess )
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
     IF( verbose>1 ) WRITE(u0,'(5x,"|> First EIGEN vectors read in file",1x,a)') TRIM(eigenvec_guess)
     CALL read_guess( nat, eigenvec, eigenvec_guess )
     !
  CASE( 'input' )
     !
     ! do nothing here, eigenvec is already copied from artn_data in refresh_artn()
     write(*,*) "eigenvec guess from input"
     write(*,*) eigenvec(:,1)

  CASE default
     !
     !! generate random
     IF( verbose>1 ) WRITE(u0,'(5x,"|> First EIGEN vectors RANDOM")')
     push_add_const = 0
     !! Replace Mask on norm(force) by keyword 'list_force'.
     !! keyword 'bias_force' = orient the randomness on the actual atomic forces
     !call push_init( nat, tau_step, lat, dummy, push_dist_thr, push_add_const, &
     !     eigen_step_size, 'list_force', eigenvec )
     call push_init_new( nat, tau_step, lat, dummy, push_dist_thr, push_add_const, &
                         eigen_step_size, 'list_force', eigenvec )
     !
  END SELECT
  !
  IF( verbose>1 ) CLOSE(UNIT=u0, STATUS='KEEP')
  !
  ! allocate and save the initial push vector, to avoid reading from initp file.
  ! for the 'double random' vector when losing eigenvalue
  !
  IF( allocated(push_initial_vector))deallocate( push_initial_vector )
  ALLOCATE( push_initial_vector, source = push )
  !
END SUBROUTINE start_guess
