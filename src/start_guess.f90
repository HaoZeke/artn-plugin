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
!! @param[out]  push       array(3*nat) push vector
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
  REAL(DP)              :: dummy2(3,nat)
  REAL(DP)              :: push_size
  !
  IF( verbose >1 ) OPEN ( UNIT = iunartout, FILE = filout, FORM = 'formatted', POSITION = 'append', STATUS = 'OLD' )

  !
  ! generate the initial push vector
  !
  SELECT CASE( TRIM(push_mode) )
    !
    CASE( 'all', 'list', 'rad' )
       !
       IF( verbose>1 ) WRITE(iunartout,'(5x,"|> First PUSH vectors almost RANDOM")')
       !
       ! set push_size
       push_size = push_step_size
       IF( lUSER_CHOOSE_PER_ATOM ) push_size = push_step_size_per_atom
       !
       ! generate initial push vector with push_size
       CALL vector_init( nat, tau_step, lat, idum, push_ids, push_dist_thr, push_add_const, &
            push_size, push, push_mode)
       !
    CASE( 'file' )
       !
       ! read initial push vector from file
       IF( verbose >1 ) WRITE(iunartout,'(5x,"|> PUSH vectors read in file",1x,a)') TRIM(push_guess)
       CALL read_guess( idum, nat, push, push_guess )
       !
    CASE default
       ! error
       WRITE(*,*) "ERROR in pARTn :: start_guess() -> invalid 'push_mode':",trim(push_mode)
       WRITE(*,*) "STOPPING"
       IF( verbose>1) then
          write(iunartout,*)"ERROR in pARTn :: start_guess() -> invalid 'push_mode':",trim(push_mode)
          write(iunartout,*)"STOPPING"
       END IF
       STOP
  END SELECT

  !
  ! ...Define initial EIGENVEC:
  !
  IF( LEN_TRIM(eigenvec_guess) /= 0 ) THEN

    !! read eigenvector from file
    IF( verbose>1 ) WRITE(iunartout,'(5x,"|> First EIGEN vectors read in file",1x,a)') TRIM(eigenvec_guess)
    CALL read_guess( idum, nat, eigenvec, eigenvec_guess )

  ELSE

    !! random
    IF( verbose>1 ) WRITE(iunartout,'(5x,"|> First EIGEN vectors RANDOM")')
    ! push_add_const = 0
    dummy(:) = 0
    dummy2(:,:) = 0.0_DP
    !! Replace Mask on norm(force) by keyword 'list_force'.
    !! keyword 'bias_force' = orient the randomness on the actual atomic forces
    call vector_init( nat, tau_step, lat, idum, dummy, push_dist_thr, dummy2, &
         eigen_step_size, eigenvec, 'list_force')

  ENDIF
  !
  IF( verbose>1 ) CLOSE(UNIT=iunartout, STATUS='KEEP')
  !
END SUBROUTINE start_guess


