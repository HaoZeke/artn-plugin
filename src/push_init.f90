SUBMODULE ( m_setup_artn ) push_init_routine

  USE precision, ONLY: DP
  IMPLICIT NONE

CONTAINS

  !> @brief
  !!   subroutine that generates the initial push, or initial eigenvector, depending on the caller
  !
  !> @par Purpose
  !  ============
  !>
  !> @verbatim
  !>   options are specified by mode: \n
  !!           (1) 'all' generates a push on all atoms \n
  !!           (2) 'list' generates a push on a list of atoms \n
  !!           (3) 'rad' generates a push on a list of atoms and all atoms within push_dist_thr \n
  !!   the user should supply: number and list of atoms to push; and add_constraints on these atoms
  !> @endverbatim
  !
  !> @ingroup Control
  !>
  !> @param [in]    nat             Size of list: number of atoms
  !> @param [in]    push_ids        List of atoms on which apply a push
  !> @param [in]    dist_thr        Threshold on the distance interatomic
  !> @param [in]    step_size       length of initial step
  !> @param [in]    tau             atomic position
  !> @param [in]    lat             Box length
  !> @param [in] add_const       list of atomic constrain
  !> @param [in]    mode            Actual kind displacement
  !> @param [out]   push            list of push applied on the atoms (ORDERED)
  !>
  !> @snippet push_init.f90 push_init
  MODULE SUBROUTINE generate_push_init( nat, tau, lat, push_ids, dist_thr, add_const, step_size, mode, vector)
    !
    !> [push_init]
    USE units,       ONLY: unconvert_length
    USE m_artn_data, ONLY: force_step
    USE artn_params, ONLY: luser_choose_per_atom, delr_thr
    use artn_params, ONLY: push
    USE m_tools,     ONLY: pbc, center
    use m_tools,     ONLY: dnrm2
    IMPLICIT none
    ! -- ARGUMENTS
    INTEGER,      INTENT(IN)  :: nat
    INTEGER,      INTENT(IN)  :: push_ids(nat)
    REAL(DP),     INTENT(IN)  :: dist_thr, step_size
    REAL(DP),     INTENT(IN)  :: tau(3,nat), lat(3,3)
    REAL(DP),     INTENT(IN)  :: add_const(4,nat)
    CHARACTER(*), INTENT(IN)  :: mode
    REAL(DP),     INTENT(OUT) :: vector(3,nat)
    !
    ! -- LOCAL VARIABLE
    INTEGER                   :: na, ia, u0
    REAL(DP)                  :: dr2, vmax 
    REAL(DP)                  :: dist(3), tau0(3), randvec(3)
    REAL(DP)                  :: bias(3,nat)
    LOGICAL                   :: lvalid, lcenter

    ! ... Initialization
    ! write(*,*) "enter generate_push_init mode", trim(mode)
    vector(:,:) = 0.0_DP
    lvalid      = .FALSE.
    lcenter     = .FALSE.
    bias        = 0.0_DP

    !
    ! ... Define the list of atoms that will be pushed according the the case
    SELECT CASE( trim(mode) )
      !
      CASE( 'all' )  !! generate displacement on all atoms
        !  
        bias = 1.0_DP
        lcenter = .true.
        ! 
      CASE( 'list' ) !! generate displacement only for atoms in the list
        ! 
        DO na=1,nat
           IF( ANY(push_ids == na) )THEN
              bias(:,na) = 1.0_DP
           ENDIF
        ENDDO
        !
      CASE( 'rad' )  !! generate displacement for atoms into a radius around atoms in mask
        !
        DO na=1,nat
           IF( ANY(push_ids == na) )THEN
              bias(:,na) = 1.0_DP
              !
              tau0 = tau(:,na)
              DO ia = 1,nat
                 ! skip na, it's already set
                 IF( ia == na ) CYCLE
                 dist(:) = tau(:,ia) - tau0(:)

                 CALL pbc( dist, lat)
                 IF ( dnrm2(3,dist,1) <= dist_thr ) THEN
                    ! found an atom within dist_thr
                    bias(:,ia) = 1.0_DP
                 ENDIF
              ENDDO
           ENDIF
        ENDDO
        !
      CASE( 'bias_force' ) !! define an array bias used in random_array()
        !                  !! Usefull to initialize eigenvec around atoms that have moved
        bias = force_step / dnrm2( 3*nat, force_step, 1) !! The ones that move have non null forces 
        lcenter = .true.
        ! 
      CASE( 'list_force' ) !! Equivalent to  list on the force
         ! 
         DO na=1,nat
            bias(:,na) = MERGE( 1.0_DP, 0.0_DP, NORM2(force_step(:,na)) > 1e-16_DP )
            ! print*, "push_init", na, bias(:,na), push_ids(na)
         ENDDO
         !
      CASE( 'list_push' )  !! Equivalent to list_force, except bias is push vector
         ! 
         DO na=1,nat
            bias(:,na) = MERGE( 1.0_DP, 0.0_DP, NORM2(push(:,na)) > 1e-16_DP )
            ! print*, "push_init", na, bias(:,na), push_ids(na)
         ENDDO
         !
    END SELECT
    
    !
    ! ... All the information is converted in local index
    INDEX:DO na=1,nat
       !
       ia = 0
       RDM:DO
          !
          ia = ia + 1
          CALL RANDOM_NUMBER( randvec )
          vector(:,na) = (/ (0.5_DP - randvec(1)) * bias(1,na),  &
                            (0.5_DP - randvec(2)) * bias(2,na),  &
                            (0.5_DP - randvec(3)) * bias(3,na)  /)
          dr2 = vector(1,na)**2 + vector(2,na)**2 + vector(3,na)**2
          !  
          ! check if the atom is constrained
          IF( ANY(ABS(add_const(:,na)) > 0.0_DP) ) THEN
             CALL displacement_validation( add_const(:,na), vector(:,na), lvalid ) ! Is the displacement within the chosen constrain?
             IF     ( .NOT. lvalid  )  THEN; CYCLE RDM                             ! NO : draw another random vector
             ELSEIF ( dr2 < 0.25_DP )  THEN; CYCLE INDEX                           ! YES: go to the next atom index
             ENDIF
          ENDIF
          ! 
       ENDDO RDM
       !
    ENDDO INDEX
    
    !
    ! ... Center the vector to geometric center, avoid translational motion
    IF ( lcenter ) CALL center(vector(:,:), nat)

    !
    ! ... Choose the normalization coeficient
    IF ( lUSER_CHOOSE_PER_ATOM ) THEN  ! normalize so that the norm of the largest displacement of any atom is 1.0
       vmax = 0.0_DP
       DO na = 1,nat
          vmax = MAX( vmax, NORM2(vector(:,na)) )
       ENDDO
    ELSE                               ! normalise by the total vector length
       vmax = NORM2( vector )
    ENDIF
    ! 
    IF ( vmax .LT. EPS ) THEN
       CALL err_set(ERR_OTHER, __FILE__,__LINE__,msg="vmax is zero!")
       CALL err_write(__FILE__,__LINE__)
       CALL merr(__FILE__,__LINE__,kill=.true.)
       RETURN
    ENDIF

    !
    ! ...Normalize and scale initial vector according to step size (ORDERED)
    vector(:,:) = vector(:,:) / vmax
    vector = step_size * vector

    ! write(*,*) "exit generate_push_init"
    !> [push_init]
  END SUBROUTINE generate_push_init



  SUBROUTINE generate_push_init_new( nat, tau, lat, push_ids, dist_thr, add_const, step_size, mode, push )
    !
    !> @brief
    !!   subroutine that generates the initial push; options are specified by mode:
    !!           (1) 'all' generates a push on all atoms
    !!           (2) 'list' generates a push on a list of atoms
    !!           (3) 'rad' generates a push on a list of atoms and all atoms within dist_thr
    !!   the user should supply: number and list of atoms to push; and add_constraints on these atoms
    !
    !> @param [in]    nat             Size of list: number of atoms
    !> @param [in]    push_ids        List of atoms on which apply a push
    !> @param [in]    dist_thr        Threshold on the distance interatomic
    !> @param [in]    step_size       length of initial step
    !> @param [in]    tau             atomic position
    !> @param [in]    lat             Box length
    !> @param [inout] add_const       list of atomic constrain
    !> @param [in]    mode            Actual kind displacement
    !> @param [out]   push            list of push applied on the atoms (ORDERED)
    !
    USE m_artn_data, ONLY : force_step
    USE m_tools,     ONLY : pbc, center
    USE m_tools,     ONLY : dnrm2
    !
    IMPLICIT NONE
    INTERFACE
       SUBROUTINE constrained_draw( constrain, push )
         IMPORT                  :: DP
         REAL(DP), INTENT(IN)    :: constrain(4)
         REAL(DP), INTENT(INOUT) :: push(3)
       END SUBROUTINE constrained_draw
    END INTERFACE
    !
    ! -- ARGUMENTS
    INTEGER,      INTENT(IN)  :: nat
    INTEGER,      INTENT(IN)  :: push_ids(nat)
    REAL(DP),     INTENT(IN)  :: dist_thr, step_size
    REAL(DP),     INTENT(IN)  :: tau(3,nat), lat(3,3)
    REAL(DP),     INTENT(IN)  :: add_const(4,nat)
    CHARACTER(*), INTENT(IN)  :: mode
    REAL(DP),     INTENT(OUT) :: push(3,nat)
    !
    ! -- LOCAL VARIABLE
    INTEGER                   :: na, ia
    REAL(DP)                  :: dr2, bias(3,nat)
    REAL(DP)                  :: dist(3), tau0(3)
    REAL(DP)                  :: vmax, randvec(3)
    LOGICAL                   :: lvalid, lcenter
    INTEGER                   :: atom_displaced(nat)
    
    !
    ! ... Initialization 
    ! write(*,*) "enter generate_push_init mode", trim(mode)
    push(:,:)         = 0.0_DP
    atom_displaced(:) = 0
    lvalid            = .FALSE.
    lcenter           = .FALSE.
    bias              = 0.0_DP

    !
    ! ... Define the bias that will multiply random array according the the case.
    ! ... displaced atom are the ones having non zero bias
    SELECT CASE( trim(mode) )
      !
      CASE( 'all' )       ! displace all atoms
        !   
        bias = 1.0_DP
        lcenter = .true.
        ! 
      CASE( 'list' )      ! displace only atoms in list
        !   
        DO na=1,nat
           IF( ANY(push_ids == na) )THEN
              !atom_displaced(na) = 1
              bias(:,na) = 1.0_DP
           ENDIF
         ENDDO
         ! 
      CASE( 'rad' )       ! displace atoms within chosen a cutoff radius of chosen atoms
         !  
         DO na=1,nat
           IF( ANY(push_ids == na) )THEN
              !iglob = order(na)
              !IF( ANY(push_ids == iglob) )THEN
              !atom_displaced(na) = 1   !%! Array based on local index i
              bias(:,na) = 1.0_DP
              tau0 = tau(:,na)
              DO ia = 1,nat
                 IF( ia /= na ) THEN
                    dist(:) = tau(:,ia) - tau0(:)
                    CALL pbc( dist, lat)
                    IF ( dnrm2(3,dist,1) <= dist_thr ) THEN
                       bias(:,ia) = 1.0_DP
                    ENDIF
                 ENDIF
              ENDDO
           ENDIF
         ENDDO
         ! 
      CASE( 'bias_force' ) ! displace atoms proportionally to the force_step
         ! 
         bias = force_step / dnrm2( 3*nat, force_step, 1)
         lcenter = .true.
         !
      CASE( 'list_force' ) ! displace atoms if their force is non null
         ! 
         DO na=1,nat
            bias(:,na) = MERGE( 1.0_DP, 0.0_DP, NORM2(force_step(:,na)) > 1e-16_DP )
         ENDDO
         !
    END SELECT

    !
    ! ... Create the random displacement
    INDEX:DO na=1,nat
       !
       IF ( ANY(ABS(add_const(:,na)) > 0.0_DP) ) THEN          ! with respect to the contrain on atom
          CALL constrained_draw( add_const(:,na), push(:,na) )
       ELSE                                                    ! with respect to the bias
          CALL RANDOM_NUMBER( randvec )
          push(:,na) = (/ (0.5_DP - randvec(1)) * bias(1,na),   &
                          (0.5_DP - randvec(2)) * bias(2,na),   &
                          (0.5_DP - randvec(3)) * bias(3,na) /)
       ENDIF
       !
    ENDDO INDEX

    !
    ! ... If all atoms are pushed center the push vector to avoid translational motion
    IF ( lcenter )CALL center(push(:,:), nat)

    ! 
    ! ... Choose the normalization coeficient
    IF ( lUSER_CHOOSE_PER_ATOM ) THEN ! normalize so that the norm of the largest displacement of any atom is 1.0
       vmax = 0.0_DP
       DO na = 1,nat
          vmax = max( vmax, norm2(push(:,na)) )
       ENDDO
    ELSE                              ! normalise by the total vector length
       vmax = norm2( push )
    ENDIF

    !
    ! ... Normalize and scale initial push vector according to step size (ORDERED)
    push(:,:) = push(:,:) / vmax
    push = step_size * push

    DO na = 1,nat
       PRINT*, push(:, na)
    ENDDO
    ! write(*,*) "exit generate_push_init"
  END SUBROUTINE generate_push_init_new

END SUBMODULE push_init_routine
