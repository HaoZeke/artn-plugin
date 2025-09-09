SUBMODULE ( m_setup_artn ) push_init_routine

  use h_artn_precision, ONLY: DP
  use m_artn_error
  IMPLICIT NONE

CONTAINS

  !> @brief
  !!   subroutine that generates the initial push, or initial eigenvector, depending on the caller
  !
  !> @par Purpose
  !  ============
  !>
  !> @verbatim
  !>   options are specified by mode:
  !!           (1) 'all' generates a push on all atoms
  !!           (2) 'list' generates a push on a list of atoms
  !!           (3) 'rad' generates a push on a list of atoms and all atoms within push_dist_thr
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
  MODULE FUNCTION generate_push_init( nat, tau, lat, push_ids, dist_thr, add_const, step_size, mode, push )&
       result(ierr)
    !
    USE d_artn_data,  ONLY : force_step
    USE m_artn_tools, ONLY : pbc, center, dnrm2, invmat3x3, ARTN_RANDOM_NUMBER
    USE m_artn_option,     ONLY : constrained_draw
    use h_artn_units, only: is_finite
    !
    IMPLICIT NONE
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
    ! -- result
    INTEGER :: ierr
    !
    ! -- LOCAL VARIABLE
    !character(*), parameter   :: here = "generate_push_init"
    INTEGER                   :: na, ia, nmax, idx
    REAL(DP)                  :: bias(3,nat)
    REAL(DP)                  :: rdist(3)
    REAL(DP)                  :: vmax, randvec(3), invlat(3,3)
    LOGICAL                   :: lvalid, lcenter
    INTEGER                   :: atom_displaced(nat)

    !
    ! ... Initialization
    ! write(*,*) "enter generate_push_init mode", trim(mode)
    ierr = 0
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
       ! how many atomic indices are in push_ids array
       nmax = count( push_ids > 0 )
       if( nmax == 0 ) then
          ierr = ERR_OTHER
          call err_set(ierr, __FILE__,__LINE__, msg="no indices in `push_ids` array?")
          return
       end if
       !
       if( any(push_ids > nat) ) then
          ierr = ERR_OTHER
          call err_set(ierr, __FILE__,__LINE__, &
               msg="push_ids includes invalid values! (out of scope: 0 < x <= nat)")
          return
       end if
       !
       call invmat3x3(lat, invlat)
       do na = 1, nmax
          ! my atomic index
          idx = push_ids(na)
          ! set bias=1.0 for neighbors within dist_thr, including self
          ia_: do ia = 1, nat
             rdist = tau(:,ia) - tau(:,idx)
             call pbc( rdist, lat, invlat )
             if( dnrm2(3,rdist,1) <= dist_thr ) bias(:,ia) = 1.0_dp
          end do ia_
       end do
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
          CALL ARTN_RANDOM_NUMBER( randvec(1) )
          CALL ARTN_RANDOM_NUMBER( randvec(2) )
          CALL ARTN_RANDOM_NUMBER( randvec(3) )
          ! write(*,*) "generate_push_init> INDEX LOOP:", na, nat, bias(:,na)
          !bias(1,na) = bias(1,na)
          push(1:3,na) = [ (0.5_DP - randvec(1)) * bias(1,na),   &
                          (0.5_DP - randvec(2)) * bias(2,na),   &
                          (0.5_DP - randvec(3)) * bias(3,na) ]
       ENDIF
       !
    ENDDO INDEX
    !write(*,*) here,">",push


    !
    ! ... If all atoms are pushed center the push vector to avoid translational motion
    IF ( lcenter )CALL center(push(:,:), nat)
    !write(*,*) here,"> push after center:",push

    !
    ! ... Choose the normalization coeficient
    IF ( lUSER_CHOOSE_PER_ATOM ) THEN
       ! normalize so that the norm of the largest displacement of any atom is 1.0
       vmax = 0.0_DP
       DO na = 1,nat
          vmax = max( vmax, norm2(push(:,na)) )
       ENDDO
    ELSE
       ! normalise by the total vector length
       vmax = norm2( push )
    ENDIF

    !
    ! ... Normalize and scale initial push vector according to step size (ORDERED)
    push = push * step_size / vmax

    ! check if generated vector is zero or nan
    if( .not. all(is_finite(push) .eqv. .true.)) then
       ierr = ERR_OTHER
       call err_set(ierr, __FILE__,__LINE__, &
            msg="generated vector contains NaN!")
       return
    end if


  END FUNCTION generate_push_init

END SUBMODULE push_init_routine
