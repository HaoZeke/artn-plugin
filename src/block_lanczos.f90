submodule( m_block_lanczos ) block_lanczos_routine
  use d_artn_data, only: natoms
  use m_artn_error
  implicit none

contains

  !> @brief
  !!   carry on the lanczos procedure 
  !!
  !> @param[out]   disp_code    ARTN step
  !> @param[out]   displ_vec    Atomic displacement 
  !> @param[out]   if_pos       mask for atomic displacement or not 
  !> @return       ierr         integer error code
  !
  module function block_lanczos( disp_code, displ_vec, if_pos )result( ierr )
    ! user input variables
    use d_artn_params, only: eigval_thr, lanczos_max_size, alpha_mix_cr, nnewchance
    use d_artn_params, only: push_initial_vector, push_step_size
    ! runtime
    use d_artn_params, only: LANC, nlanc
    use d_artn_params, only: eigenvec
    use d_artn_params, only: in_lanczos_at_min
    use d_artn_params, only: leigen, ieigen, ismooth
    use d_artn_params, only: lbasin, linit, llanczos, lperp, lrelax, inewchance
    use d_artn_params, only: push, nperp_step
    use d_artn_data, only: force_step, eigen_step, eigval_step
    !
    use m_artn_report, only: ilanc_save
    use m_artn_tools, only: ddot, dnrm2
    ! use artn_data, only: ARTN_ERR_EIGVAL_LOST
    ! use artn_save_data, only: save_current_data
    use m_artn_option, only: nperp_limitation_step
    implicit none
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3,natoms)
    INTEGER,          INTENT(IN)    :: if_pos(3,natoms)    !  coordinates fixed by engine
    integer :: ierr


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
       !! NOTE:: check if sizes are coherent
       call lanczos_check_matsize()
       H = 0.0_DP
       Vmat = 0.0_DP
       !
       IF ( .not. ALLOCATED(v_in) ) ALLOCATE( v_in(3,natoms), source = 0.0_DP )
       ierr = prepare_v_in( v_in )
       if( ierr /= 0 ) then
          call err_caller(__FILE__,__LINE__)
          return
       end if
       !
    ENDIF
    ! write(*,*) "ilanc",ilanc
    ! write(*,*) "v_in a",v_in(1,1)
    !
    ! apply constraints from the engine. Works only with engines which fill if_pos!! (not lammps)
    !
    call apply_constrain_position( v_in, if_pos, force_step )
    !
    ! call lanczos routine
    CALL lanczos( natoms, v_in, push, force_step, &
         ilanc, nlanc, lowest_eigval, eigenvec, displ_vec)
    !
    ! orient the eigenvec opposite to force
    eigenvec = -SIGN(1.0_DP,ddot(3*natoms,force_step,1,eigenvec,1))*eigenvec

    ! set into step data
    eigval_step = lowest_eigval
    ! eigen_step is allocated in fill_param_step()
    eigen_step = eigenvec
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
          ! ieigen = 0  !! initialize with the flag
          ! ...Save the eigenvector
          ! ...No yet perp relax
          lperp  = .false.
          old_lowest_eigval = lowest_eigval
          !
       ELSE
          !
          !
          IF ( .NOT. lbasin .AND. lowest_eigval > 0.0_DP ) THEN
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
                ! ... set artn_failure
                ierr = ARTN_FAILURE
                !!
                !! set latest data
                ! CALL save_current_data( "latest", error_code=ARTN_ERR_EIGVAL_LOST )
                call err_set(ierr, __FILE__,__LINE__, &
                     msg="EIGENVALUE LOST, try to increase nnewchance or nsmooth")
                return
                !
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
    ! write(*,*) "cur lanc",ilanc,nlanc, lowest_eigval

  end function block_lanczos


  function prepare_v_in( v_in )result(ierr)
    use h_artn_units, only : EPS
    !
    ! this is called on first iteration of current lanczos call:
    !  prepare the first lanczos vector v_in
    use d_artn_data, only: force_step
    use d_artn_params, only: lanczos_always_random
    use d_artn_params, only: eigenvec, leigen
    use m_setup_artn, only: start_guess_eigenvec
    implicit none
    real(DP), intent(out) :: v_in(3,natoms)
    integer :: ierr
    !
    ierr = 0
    !
    ! write(*,*) "prepare_v_in",v_in(1,1)
    ! write(*,*) "prepare_v_in",force_step(1,1)
    ! write(*,*) "prepare_v_in",eigenvec(1,1), allocated(eigenvec),size(eigenvec,1),size(eigenvec,2)
    IF( lanczos_always_random )THEN
       ! generate random initial vector, biased by current force
       call random_array( 3*natoms, v_in, force_step )
    ELSE
       ! take eigenvector of previous iternation
       if( .not. have_v1 ) then
          ierr = start_guess_eigenvec( natoms, eigenvec )
          if( ierr/=0 ) then
             call err_caller(__FILE__,__LINE__)
             return
          end if

#ifdef DEBUG
          block
            integer :: i
            write(*,*) "first eigenvec:"
            do i = 1, size(eigenvec,2)
               if( norm2(eigenvec(:,i)) > 1e-2_dp ) write(*,*) i, eigenvec(:,i)
            end do
            write(*,*) "norm:",norm2(eigenvec)
          end block
#endif

       end if
       v_in(:,:) = eigenvec(:,:)
       have_v1 = .true.
    ENDIF
    !
    ! reset the eigenvalue flag
    !
    leigen = .false.
    !
    ! allocate memory for previous lanczos vec
    !
    if( .not. allocated( old_lanczos_vec ) ) allocate( old_lanczos_vec, source = v_in )
    a1 = 0.0_DP

    !if( any(v_in .ne. v_in)) then
    if( any(abs(v_in-v_in) > EPS) ) then
       ierr = ERR_OTHER
       call err_set(ierr, __FILE__,__LINE__,msg="v_in contains NaN!")
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

  end function prepare_v_in


  subroutine apply_constrain_position( v_in, if_pos, force_step )
    use d_artn_params, only: nlanc
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
       v_in(:,:) = v_in(:,:)*real(if_pos(:,:),DP)
       force_step(:,:) = force_step(:,:)*real(if_pos(:,:),DP)
    ENDIF
  end subroutine apply_constrain_position


  !> @details
  !! check if lanczos arrays and matrices are of the expected size. If not, deallocate and allocate to
  !! proper size.
  subroutine lanczos_check_matsize()
    use d_artn_data, only: natoms
    use d_artn_params, only: lanczos_max_size
    implicit none

    !! if not allocated, allocate
    if( .not. allocated(force_old)) allocate( force_old(1:3,1:natoms))
    if( .not. allocated(H) ) allocate( H(1:lanczos_max_size, 1:lanczos_max_size))
    if( .not. allocated(Vmat) ) allocate(Vmat(1:3,1:natoms,1:lanczos_max_size))

    !! H size
    if( size(H,1) /= lanczos_max_size .or. size(H,2) /= lanczos_max_size)then
       deallocate(H)
       allocate( H(1:lanczos_max_size, 1:lanczos_max_size))
    end if
    !! Vmat size
    if( size(Vmat,1)/=3 .or. size(Vmat,2)/=natoms .or. size(Vmat,3).ne.lanczos_max_size) then
       deallocate( Vmat )
       allocate(Vmat(1:3,1:natoms,1:lanczos_max_size))
    end if
    !! force_old
    if( size(force_old,1)/=3 .or. size(force_old,2)/=natoms) then
       deallocate( force_old )
       allocate( force_old(1:3, 1:natoms))
    end if

  end subroutine lanczos_check_matsize

end submodule block_lanczos_routine

