submodule( m_block_lanczos ) block_lanczos_routine
  use artn_params, only: natoms
  implicit none

contains

  function block_lanczos( disp_code, displ_vec, if_pos )result( ierr )
    ! user input variables
    use artn_params, only: eigval_thr, lanczos_max_size, alpha_mix_cr, nnewchance
    use artn_params, only: push_initial_vector, push_step_size
    ! runtime
    use artn_params, only: LANC, nlanc
    use artn_params, only: force_step, eigenvec, error_message
    use artn_params, only: in_lanczos_at_min
    use artn_params, only: leigen, ieigen, ismooth
    use artn_params, only: lbasin, linit, llanczos, lperp, lrelax, inewchance
    use artn_params, only: push, nperp_step
    !
    use m_artn_report, only: ilanc_save
    use artn_data, only: ARTN_ERR_EIGVAL_LOST
    use artn_save_data, only: save_current_data
    use m_option, only: nperp_limitation_step
    implicit none
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3,natoms)
    INTEGER,          INTENT(IN)    :: if_pos(3,natoms)    !  coordinates fixed by engine
    integer :: ierr

    real(DP), external :: ddot, dnrm2

    ierr = 0

    !
    !==========================================
    ! Perform Lanczos algo, one step at a time
    !==========================================
    !
    a1 = 0.0_DP
    disp_code = LANC
    IF (ilanc == 0 ) THEN
       !
       ! first iteration of current lanczos, allocate and zero the data
       !
       IF( .NOT. ALLOCATED(H)) ALLOCATE( H(1:lanczos_max_size,1:lanczos_max_size) )
       IF( .NOT. ALLOCATED(Vmat)) ALLOCATE( Vmat(1:3,1:natoms,1:lanczos_max_size) )
       H = 0.0_DP
       Vmat = 0.0_DP
       !
       IF ( .not. ALLOCATED(v_in) ) ALLOCATE( v_in(3,natoms), source = 0.0_DP )
       call prepare_v_in( v_in )
       !
    ENDIF
    !
    ! apply constraints from the engine. Works only with engines which fill if_pos!! (not lammps)
    !
    call apply_constrain_position( v_in, if_pos, force_step )
    !
    ! call lanczos routine
    CALL lanczos( natoms, v_in, push, force_step, &
         ilanc, nlanc, lowest_eigval, eigenvec, displ_vec)
    !
    ilanc = ilanc + 1
    !
    ! if Lanczos has converged:
    ! nlanc is overwritten by number of steps it took to converge,
    ! and ilanc=nlanc+1
    !
    IF ( ilanc > nlanc ) THEN
       !
       ! check lowest eigenvalue, decide what to do in next step
       !
       ilanc_save = ilanc
       !
       ! ...Compare the eigenvec with the previous one
       !
       a1 = ddot( 3*natoms, eigenvec, 1, old_lanczos_vec, 1 )
       a1 = abs( a1 )
       ! set current eigenvec for comparison in next step
       old_lanczos_vec = eigenvec
       !
       ! finish lanczos for now
       !
       llanczos = .false.
       !
       ! reset lanczos size for next call
       !
       nlanc = lanczos_max_size

       ! lanczos_at_min does not do anything currently
       IF ( in_lanczos_at_min ) then
          lrelax = .true.
          return
       end IF
       !
       ! set data for next step
       !
       IF ( lowest_eigval < eigval_thr     .OR.  &
            (.NOT.lbasin.AND.lowest_eigval < 0.0_DP) )THEN
          !
          ! structure is out of the basin (above inflection),
          ! in next step make a push with the eigenvector
          !
          !! Next Mstep outside the basin
          lbasin = .false.
          ! ...push in eigenvector direction
          leigen = .true.
          ieigen = 0  !! initialize with the flag
          ! ...Save the eigenvector
          ! ...No yet perp relax
          lperp  = .false.
          old_lowest_eigval = lowest_eigval
          !
       ELSE
          !
          !
          IF ( .NOT. lbasin .AND. lowest_eigval > 0.0 ) THEN
             !
             ! ... Here the system is in a convex region.
             ! We can try to cross it several times or stop the programm.
             IF( inewchance < nnewchance ) THEN
                ! ... Reinitialize the 1st vector of lanczos for the next time.
                ! This can be usefull to avoid lanczos beeing blocked by a bias last eigenvector
                call random_array( 3*natoms, v_in, push_initial_vector )
                !
                ! ... Reinitialize some counters
                call nperp_limitation_step( -1 )
                inewchance = inewchance +1
                ismooth    = 0
                !
                ! ... Redefine the push for next step as the initial direction and
                ! ... Avoid some cycling cases by adding a random part to the push using nomalize V_in
                push=push_initial_vector+v_in*push_step_size
                push=(1.0_DP-alpha_mix_cr)*push_initial_vector+alpha_mix_cr*v_in*push_step_size
                ! push_initial_vector: potentially a problem with order here, if engine reordered atoms since start
                !
                ! ... Norm and orient the push in the direction opposite to forces
                push(:,:) = -SIGN(1.0_DP,ddot(3*natoms,force_step,1,push,1))*push(:,:)/norm2(push)*push_step_size
             ELSE
                ! ... Stop
                error_message = 'EIGENVALUE LOST, try to increase nnewchance or nsmooth'
                ierr = -1
                !!
                !! set latest data
                CALL save_current_data( "latest", error_code=ARTN_ERR_EIGVAL_LOST )
                return
             ENDIF
             !
          ENDIF
          !
          ! structure is still in basin (under unflection),
          ! in next step it moves following push vetor (can be a previous eigenvec)
          !! Next Mstep inside the Basin
          !lowest_eigval = 0.D0
          leigen = .false.
          linit  = .true.
          lbasin = .true.
          ! noperp = 0      !! count the init-perp fail
          nperp_step = 1  !! count the out-basin perp relax step
          !
       ENDIF
       !
    ENDIF
    !

  end function block_lanczos


  subroutine prepare_v_in( v_in )
    !
    ! this is called on first iteration of current lanczos call:
    !  prepare the first lanczos vector v_in
    !
    use artn_params, only: lanczos_always_random, force_step
    use artn_params, only: eigenvec, leigen
    implicit none
    real(DP), intent(out) :: v_in(3,natoms)
    !
    IF( lanczos_always_random )THEN
       ! generate random initial vector, biased by current force
       call random_array( 3*natoms, v_in, force_step )
    ELSE
       ! take eigenvector of previous iternation
       v_in(:,:) = eigenvec(:,:)
    ENDIF
    !
    ! reset the eigenvalue flag
    !
    leigen = .false.
    !
    ! allocate memory for previous lanczos vec
    !
    if( .not. allocated( old_lanczos_vec ) ) allocate( old_lanczos_vec, source = v_in )
    a1 = 0.0

  end subroutine prepare_v_in


  subroutine apply_constrain_position( v_in, if_pos, force_step )
    use artn_params, only: natoms
    use artn_params, only: nlanc
    implicit none
    real(DP), intent(inout) :: v_in(3,natoms)
    integer, intent(in) :: if_pos(3,natoms)
    real(DP), intent(inout) :: force_step(3,natoms)

    integer :: na, icoor, if_pos_ct

    if_pos_ct = 0

    IF ( ANY(if_pos(:,:) == 0) ) THEN
       DO na=1,natoms
          DO icoor=1,3
             IF (if_pos(icoor,na) == 1 ) if_pos_ct = if_pos_ct + 1
          ENDDO
       END DO
       IF ( if_pos_ct < nlanc .and. if_pos_ct /= 0 ) nlanc = if_pos_ct
       v_in(:,:) = v_in(:,:)*if_pos(:,:)
       force_step(:,:) = force_step(:,:)*if_pos(:,:)
    ENDIF
  end subroutine apply_constrain_position

end submodule block_lanczos_routine

