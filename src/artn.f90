module m_artn
  use precision, only: DP
  use m_error
  use m_artn_report
  implicit none


  interface

     !! lanczos.f90
     module subroutine lanczos( nat, v_in, pushdir, force, &
          ilanc, nlanc, lowest_eigval, lowest_eigvec, displ_vec )
       integer,                    intent(in)    :: nat
       real(dp), dimension(3,nat), intent(in)    :: v_in
       real(dp), dimension(3,nat), intent(in)    :: pushdir
       real(dp), dimension(3,nat), intent(in)    :: force
       integer,                    intent(inout) :: ilanc
       integer,                    intent(inout) :: nlanc
       real(dp),                   intent(inout) :: lowest_eigval
       real(dp), dimension(3,nat), intent(inout) :: lowest_eigvec
       real(dp), dimension(3,nat), intent(out)   :: displ_vec
     end subroutine lanczos

     !! setup_artn.f90
     module subroutine setup_artn( nat, filnam, error )
       integer, intent(in)            :: nat
       character(len=255), intent(in) :: filnam
       logical, intent(out)           :: error
     end subroutine setup_artn

     !! refresh_artn.f90
     module subroutine refresh_artn( nat, lerror )
       integer, intent(in) :: nat
       logical, intent(out) :: lerror
     end subroutine refresh_artn

     !! start_guess.f90
     module function start_guess( nat, push, eigenvec )result(lerror)
       integer,  intent(in)  :: nat
       real(dp), intent(out) :: push(3,nat)
       real(dp), intent(out) :: eigenvec(3,nat)
       logical :: lerror
     end function start_guess

     !! push_init.f90
     module subroutine push_init( nat, tau, lat, push_ids, dist_thr, add_const, step_size, mode, vector)
       integer,          intent(in)  :: nat
       real(dp),         intent(in)  :: tau(3,nat)
       real(dp),         intent(in)  :: lat(3,3)
       integer,          intent(in)  :: push_ids(nat)
       real(dp),         intent(in)  :: dist_thr
       real(dp),         intent(in)  :: add_const(4,nat)
       real(dp),         intent(in)  :: step_size
       character(*),     intent(in)  :: mode
       real(dp),         intent(out) :: vector(3,nat)
     end subroutine push_init

  end interface

contains




  !> @brief Main ARTn plugin subroutine
  !>
  !> @author Matic Poberznik,
  !>         Miha Gunde,
  !>         Nicolas Salles,
  !>         Antoine Jay
  !>
  !> @par Purpose
  !  ============
  !>  Modifies the input force to perform the ARTn algorithm
  !>
  !> @param[in]     force       force calculated by the engine
  !> @param[inout]  etot_eng    total energy of the engine
  !> @param[in]     nat         number of atoms
  !> @param[in]     ityp        list of type of atoms
  !> @param[in]     atm         list of the element's name relative to the atomic type
  !> @param[inout]  tau         atomic position
  !> @param[in]     order       order of atomic index in the list: force, tau, ityp
  !> @param[in]     at          lattice parameter
  !> @param[in]     if_pos      list of fixed atomic dof (0 or 1)
  !> @param[out]    disp        stage for move_mode
  !> @param[out]    displ_vec   displacement vector communicated to move_mode
  !> @param[out]    lconv       flag for controlling convergence
  !>
  !> @note
  !>  artn_params for variables and counters that need to be stored in each step
  !>  DEFINED IN: artn_params_mod.f90
  !>
  !> @ingroup ARTn
  !> @snippet artn.f90 art
  !
  SUBROUTINE artn( force, etot_eng, nat, ityp, atm, tau, order, at, if_pos, disp, displ_vec, lconv )

    !> [art]
    USE units
    use artn_params
    use m_option
    use artn_data, only: ARTN_ERR_EIGVAL_LOST, ARTN_ERR_NUMSTEP, ARTN_ERR_LARGE_ENER, ARTN_ERR_OTHER
    use artn_save_data
    use m_tools, only: make_filename, random_array, field_split, check_force_convergence
    use m_tools, only: push_over_procedure

    !
    IMPLICIT NONE

    ! -- ARGUMENTS
    INTEGER, value,   INTENT(IN)    :: nat              !  number of atoms
    REAL(DP),         INTENT(IN)    :: etot_eng         !  total energy in current step
    INTEGER,          INTENT(IN)    :: order(nat)       !  Engine order of atom
    REAL(DP),         INTENT(IN)    :: at(3,3)          !  lattice parameters in alat units
    INTEGER,          INTENT(INOUT) :: ityp(nat)        !  atom types
    INTEGER,          INTENT(IN)    :: if_pos(3,nat)    !  coordinates fixed by engine
    CHARACTER(LEN=3), INTENT(IN)    :: atm(*)           !  name of atom corresponding to ityp
    REAL(DP),         INTENT(IN)    :: force(3,nat)     !  force calculated by the engine
    REAL(DP),         INTENT(INOUT) :: tau(3,nat)       !  atomic positions (needed for output only)
    REAL(DP),         INTENT(OUT)   :: displ_vec(3,nat) !  displacement vector communicated to move mode
    INTEGER,          INTENT(OUT)   :: disp             !  Stage for move_mode
    LOGICAL,          INTENT(OUT)   :: lconv            !  flag for controlling convergence

    ! -- LOCAL VARIABLES
    REAL(DP), EXTERNAL              :: dnrm2, ddot      ! lapack functions
    INTEGER                         :: na, icoor        ! integers for loops
    REAL(DP)                        :: fpara(3,nat)     ! force parallel to push/eigenvec
    REAL(DP)                        :: fperp(3,nat)     ! force parallel to push/eigenvec
    REAL(DP)                        :: fpara_tot        ! total force in parallel direction
    INTEGER                         :: ios ,i           ! file IOSTAT
    LOGICAL                         :: lforc_conv       ! flag true when forces are converged
    LOGICAL                         :: lsaddle_conv     ! flag true when saddle is reached
    LOGICAL                         :: lerror           ! flag for an error from the engine
    character(len=256)              :: outfile          ! file where are written the steps
    REAL(DP)                        :: z
    integer                         :: u0, if_pos_ct

    !
    !*> @par The ARTn algorithm proceeds as follows:
    !*  ============================================
    !*> (1) push atoms in the direction specified by user & relax in the perpendicular direction \n
    !*> (2) use the lanczos algorithm calculate the lowest eigenvalue/eigenvec \n
    !*> (3) a negative eigenvalue, update push direction otherwise push again \n
    !*> (4) follow the lanczos direction twoard the saddle point \n
    !*> (5) push twoards adjacent minimum & initial minimum \n
    !
    ! ... Flags that controls convergence
    lconv        = .false.
    lforc_conv   = .false.
    lsaddle_conv = .false.
    !
    ! ... fpara_tot is used to scale the magnitude of the eigenvector
    fpara_tot = 0.D0

    lerror = .false.
    !
    disp = VOID


    outfile = "none"

    !
    ! ... Initialize artn
    istep0: IF( istep == 0 )THEN !! -------------------------------------------------------------------- ISTEP = 0
       !
       lend = .false.
       !
       ! ...Initialize if it is the first search
       IF( isearch == 0 ) CALL setup_artn( nat, filin, lerror )
       !
       IF ( lerror ) THEN
          disp =void
          error_message = 'PROBLEM IN SETUP_ARTN():'//trim(error_message)
          lconv = .true.
          call flag_false()
          exit istep0
       ENDIF
       !
       ! ... call the refresh to get data from interactive mode if present
       call refresh_artn( nat, lerror )
       !
       IF ( lerror ) THEN
          disp =void
          error_message = 'PROBLEM IN REFRESH():'//trim(error_message)
          lconv = .true.
          call flag_false()
          exit istep0
       ENDIF
       !
       ! ... convert to artn units
       ! call convert_artn_params()
       !
       ! ... check for cohenrence among the input parameters
       call check_artn_params( nat, lerror )
       !
       IF( lerror ) THEN
          disp = void
          error_message = "PROBLEM IN CHECK_ARTN_PARAMS:"//trim(error_message)
          lconv = .true.
          call flag_false()
          exit istep0
       ENDIF
       !
       ! ...Fill variables of artn_params (arrays are ordered !!): needs to know engine_units
       !    natoms, lat, etot_step, types, force_step, tau_step
       CALL Fill_param_step( nat, at, order, ityp, tau, etot_eng, force, lerror )
       !! Something went wrong in filling the arrays!
       IF ( lerror ) THEN
          disp =void
          error_message = 'PROBLEM IN FILL_PARAM_STEP():'//trim(error_message)
          lconv = .true.
          call flag_false()
          exit istep0
       ENDIF
       !
       IF( lrestart ) THEN
          !
          ! ...Signal that it is a restart
          call write_comment( trim(filout), "Restarted previous ARTn calculation" )
          !
          ! ...Read the FLAGS, FORCES, POSITIONS, ENERGY, ...
          CALL read_restart( restartfname, nat, types, lerror )
          IF( lerror )THEN
             error_message = 'RESTART FILE DOES NOT EXIST'
             lconv = .true.
             call flag_false()
             exit istep0
          ENDIF
          !
          ! ...Overwirte the engine Arrays
          tau(:,:) = tau_step(:,order(:))
          ityp(:) = types(order(:))
          !
       ELSE
          !
          ! ...Create The input
          !!    To be able to do multiple research in the same run we keep
          !!    in memory "isearch" how many time we pass here and open an output
          !!    file only once
          IF( isearch == 0 ) CALL write_initial_report( filout )
          isearch = isearch + 1

          !
          ! ...Initial parameter
          etot_init = etot_step
          tau_init = tau_step
          !IF( prev_disp==VOID ) THEN        !!!!! Maybe too much
          !  IF( .NOT.ALLOCATED(tau_init) ) THEN
          !    ALLOCATE( tau_init, source = tau_step )
          !  ELSE
          !    tau_init = tau_step
          !  ENDIF
          !ENDIF


          !
          ! ...Initialize pushvect and eigenvec accoriding to user's choice
          lerror = start_guess( nat, push, eigenvec )
          if( lerror ) then
             call err_write(__FILE__, __LINE__)
             lconv = .true.
             call flag_false()
             exit istep0
          end if



          !
          ! ...Write the initial structure
          CALL write_struct( at, nat, tau_step, elements, types, push, etot_eng, 1.0_DP, struc_format_out, initpfname )
          !artn_resume = '* Start: '//trim(initpfname)//'.'//trim(struc_format_out)

          !
          ! ...Start to write the output
          CALL write_header_report( )

       ENDIF



       !
       ! ...Split the force field in para/perp field following the push field
       CALL field_split( 3*nat, force_step, if_pos, push, fperp, fpara )

       !
       ! ...Write the state of the initial configuration
       CALL write_report( etot_step, force_step, fperp, fpara, lowest_eigval, if_pos, istep, nat )

       artn_resume = '* Start: '//trim(initpfname)//'.'//trim(struc_format_out)
       !
       call save_current_data( "init" )



    ELSE !! ------------------------------------------------------------------------------------------  ISTEP > 0
       !
       !! artn is already finished but called more times.
       IF( lend ) THEN
          ! write(*,*) "ARTn has already finished, RETURN"
          if( verbose > 1 ) call write_comment( trim(filout), "Enter in ARTn but already finished, RETURN")
          disp = RELX
          displ_vec(:,:) = 0.0_DP
          lconv = .true.
          lerror = .false.
          call flag_false()
          exit istep0
          ! RETURN
       END IF
       !
       !! receive variables from the engine, split force into perp and para, and check if it is converged
       !
       ! ...Fill variables of artn_params (arrays are ordered !!):
       !    natoms, lat, etot_step, types, force_step, tau_step
       CALL Fill_param_step( nat, at, order, types, tau, etot_eng, force, lerror )
       !! somehing went wrong
       IF( lerror ) THEN
          error_message = "PROBLEM WITH FILL_PARAM_STEP():"//trim(error_message)
          !! finish current search
          displ_vec(:,:) = 0.0_DP
          lconv = .true.
          call save_current_data( "latest", error_code=ARTN_ERR_OTHER )
          call flag_false()
          exit istep0
       ENDIF
       !
       ! ...Split the force field in para/perp field following the push field
       CALL field_split( 3*nat, force_step, if_pos, push, fperp, fpara )

       ! ...Write Output
       CALL write_report( etot_step, force_step, fperp, fpara, lowest_eigval, if_pos, istep, nat )

       ! ...Check the convergence forces
       CALL check_force_convergence( nat, force_step, if_pos, fperp, fpara, lforc_conv, lsaddle_conv )
       !
    ENDIF istep0

    !
    ! initial displacement , then switch off linit, and pass to lperp
    !
    IF ( linit ) THEN
       !
       !=============================
       ! Send a push with initial push vector and decide what to do next: perp_relax, or lanczos
       !=============================
       ! linit flag is touched by:
       !   - initialize_artn(),
       !   - check_force_convergence()
       !   - here
       !.............................

       linit = .false.
       !
       IF ( istep == 0 .AND. ninit== 0 ) THEN
          !
          ! ...no init push to be done, pass directly to Lanczos
          llanczos = .true.
          lperp    = .false.
          !
       ELSE
          !
          ! Do init push, and switch to perp relax for next step
          iinit = iinit + 1
          disp  = INIT
          prev_push = disp !! save previous push
          !
          ! displacement equal to the push
          displ_vec(:,:) = push(:,:)
          !
          !call info_field( iunartout, nat, displ_vec, "init::displ_vec" )
          ! ...set up the flags for next step (we do an initial push, then we need to relax perpendiculary)
          lperp = .true.
          !
       ENDIF
       ilanc = 0
       !
    ELSE IF ( lperp ) THEN
       !
       !===============================================
       ! Relax forces perpendicular to eigenvector/push
       !===============================================
       ! lperp is touched by:
       !   - initialize_artn(),
       !   - check_force_convergence()
       !   - here
       !.............................
       !
       disp = PERP
       !
       ! displacement is the perpendicular force
       displ_vec(:,:) = fperp(:,:)
       !
       iperp = iperp + 1
       !
       !! Here we do a last verification on displ_vec to detect
       !! the box explosion
       !! -> Stop the search if one of displacement has 5 number
       z = 0.0_DP
       do i = 1,nat
          z = max( z, norm2(displ_vec(:,i)) )
       enddo
       IF( nat /= natoms .OR. z > 1.0e4 )THEN
          error_message = "BOX EXPLOSION"
          lconv = .true.  !! Stop the research
       ENDIF
       !
       !call info_field( iunartout, nat, displ_vec, "perp::displ_vec" )
       !
    ELSE IF ( leigen  )THEN
       !================================================
       ! Push in the direction of the lowest eigenvector
       !================================================
       !
       ! leigen is .true. after we obtain a good eigenvector
       ! if we have a good lanczos eigenvector use it as push vector
       !
       !
       disp    = EIGN
       ismooth = ismooth + 1
       ieigen  = ieigen  + 1


       ! ...reset the iterator of previous step
       ilanc   = 0


       ! ...Apply the smooth linear combination to the eigenvector
       IF( nsmooth > 0 .AND. ismooth <= nsmooth )THEN
          CALL smooth_interpol( ismooth, nsmooth, nat, force_step, push, eigenvec )  !! array PUSH change
          disp = SMTH
       ELSE
          push(:,:) = eigenvec(:,:)
       ENDIF

       !! save previous push code for ...?
       prev_push = disp
       !
       ! rescale the eigenvector according to the current force in the parallel direction
       ! see Cances_JCP130: some improvements of the ART technique doi:10.1063/1.3088532
       ! 0.13 is taken from ARTn, 0.5 eV/Angs^2 corresponds roughly to 0.01 Ry/Bohr^2
       !
       ! ...Recompute the norm of fpara because eigenvec (push) change a bit
       fpara_tot = ddot(3*nat, force_step, 1, push, 1)
       !
       current_step_size = -SIGN(1.0_DP,fpara_tot)*MIN(eigen_step_size,ABS(fpara_tot)/MAX( ABS(lowest_eigval), 0.01_DP ))
       !
       ! Put some test on current_step_size
       !
       displ_vec(:,:) = push(:,:) * current_step_size    !! Use PUSH insead of EIGNEVEC
       !
       IF( ieigen >= neigen )THEN
          ! do a perpendicular relax
          lperp = .true.
       ENDIF
       !
       ! Write the latest eigenvec to a file (eigenvec should be in force position)
       !
       CALL write_struct( at, nat, tau_step, elements, types, eigenvec, &
            etot_eng, 1.0_DP, struc_format_out, eigenfname )
       !
    END IF


    !
    ! The saddle point is reached -> confirmed by check_force_convergence()
    !
    !! SHOULD BE A ROUTINE but not :: it's because we call write_struct() that needs
    !!  arguments that exist only in artn()
    IF( lsaddle_conv )THEN

       !
       !! store the saddle point energy
       etot_saddle = etot_step
       tau_saddle = tau_step
       eigen_saddle = eigenvec
       !
       lpush_over = .true.
       ifound = ifound + 1
       !
       ! ...Save the structure
       IF( struc_format_out /= "none" ) call make_filename( outfile, prefix_sad, nsaddle )
       !
       CALL write_struct( at, nat, tau_step, elements, types, force_step, &
            etot_eng, 1.0_DP, struc_format_out, outfile )

       artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)
       !
       ! ...write the report
       CALL write_end_report( lpush_over, lpush_final, etot_step - etot_init )

       !
       !! If the saddle point is lower in energy
       !!  than the initial point: Mode refine
       IF ( etot_step < etot_init ) THEN
          ! ...HERE Warning to says we should be in refine saddle mode
          !! we need this? it's not a real warning, it does not mean something is wrong necessarily
          IF( verbose > 1 ) THEN
             call write_comment( filout, "NOTE::E_Saddle < E_init => Looks like saddle refine mode" )
          END IF
          !
       ENDIF
       !
       CALL save_current_data( "sad" )

    ENDIF
    !
    ! ...If saddle point is reached
    ! This block performs only the PUSH to adjacent minima after the saddle point is found
    !
    IF ( lpush_over ) THEN
       !
       ! do we do a final push ?
       !
       IF ( lpush_final ) THEN
          ! set convergence and other flags to false
          lconv    = .false.
          lperp    = .false.
          leigen   = .false.
          llanczos = .false.
          !
          ! normalize eigenvector
          IF( lbackward ) THEN
             !! reset eigenvector to saddle
             eigenvec(:,:) = eigen_saddle(:,:)
             lbackward     = .false.
             etot_step     = etot_saddle
          ELSE
             !! Normalize it to be sure
             eigenvec(:,:) = eigenvec(:,:)/dnrm2(3*nat,eigenvec,1)
          ENDIF
          !
          !
          ! ... do one step of push_over_procedure
          if( iover == 0 ) then
             disp = OVER
             call push_over_procedure( nat, eigenvec, fpush_factor, displ_vec )
             iover = 1
             !! iover is re-set to 0 in the lrelax block
          else
             !! already did push_over_procedure, start relax
             if( .not. lrelax ) irelax = 0
             lrelax = .true.
             lpush_over = .false.
          end if
          !
       ELSE  ! --- NO FINAL_PUSH
          !
          !! At this point the saddle point is already written by write_struct in lsaddle_conv block
          !! Here we finish the ARTn search.
          !! Preparation of the possible new ARTn search following this step.
          !! - Cleaning the flag/parameter
          !! - write in output saying no more research
          !! - return a configuration in which a new ARTn search can start
          !
          IF( verbose > 1 ) THEN
             call write_comment( filout, "NO FINAL_PUSH :: Return to the start configuration" )
          END IF

          ! ...Return to the initial comfiguration
          tau(:,:) = tau_init(:,order(:))

          ! put block flags to false
          call flag_false()

          ! ...Tell to the engine it is finished
          lconv = .true.

          ! ...Set the force to zero
          displ_vec(:,:) = 0.0_DP

          ! ...Here we dont load the next minimum because it does not exist

       ENDIF
    ENDIF
    !
    ! perform a FIRE relaxation (only for reaching adjacent minima)
    !
    RELAX: IF ( lrelax ) THEN
       !
       ! reset force
       !
       disp      = RELX
       displ_vec = force_step
       irelax    = irelax + 1
       ilanc     = 0
       prev_push = disp !! Save the previous displacement (disp is overwritten just few lines above, is this correct?)
       !
       ! The convergence is reached:
       !  - Switch the push_over or
       !  - Finish the ARTn search
       !
       IF ( lforc_conv .AND. .NOT. llanczos ) THEN
          !
          IF ( lanczos_at_min .AND. .NOT. in_lanczos_at_min ) THEN
             !
             ! ... Minimun has been found (lforc_conv =.true.)
             ! We now do lanczos to check if the lowest eigenvalue is well <0
             in_lanczos_at_min = .true.
             lpush_over        = .false.
             lrelax            = .false.
             llanczos          = .true.
             disp              = LANC
             IF( verbose > 1 ) THEN
                call write_comment( filout, "We do a Lanczos loop at the minimum to check if lowest eivenvalue is <0" )
             END IF
             !
          ELSE
             !
             IF ( fpush_factor == 1 ) THEN
                !
                ! ... found the forward minimum!
                !   We save it and return to the saddle point
                IF( struc_format_out /= "none" )CALL make_filename( outfile, prefix_min, nmin )
                !
                CALL write_struct( at, nat, tau_step, elements, types, force_step, &
                                ! etot_eng, 1.0_DP, iunstruct, struc_format_out, outfile )
                     etot_eng, 1.0_DP, struc_format_out, outfile )
                artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)
                !
                ! ...Save the minimum if it is new
                call save_min( nat, tau_step )
                !
                ! next step is relax in other direction
                disp = RELX
                !
                ! save data
                CALL save_current_data( "min1" )
                !
                ! ...restart from saddle point
                tau(:,:)      = tau_saddle(:,order(:))
                eigenvec(:,:) = eigen_saddle(:,:)
                lbackward     = .true.
                !
                ! ...Return to Push_Over Step in opposit direction
                !lsaddle = .true.
                lpush_over = .true.
                lrelax     = .false.
                !
                etot_final = etot_step
                !
                ! energy difference is saddle - current
                de_back = etot_saddle - etot_final
                !
                call write_inter_report( fpush_factor, [de_back] )
                !
                ! ...reverse direction for the push_over
                fpush_factor = -1
                irelax = 0
                iover = 0
                in_lanczos_at_min = .false.
                !
             ELSE  !< If already pass before no need to rewrite again
                !
                ! ... found the backward minimum!
                IF( struc_format_out /= "none" )CALL make_filename( outfile, prefix_min, nmin )
                !
                CALL write_struct( at, nat, tau_step, elements, types, &
                                ! force_step, etot_eng, 1.0_DP, iunstruct, struc_format_out, outfile )
                     force_step, etot_eng, 1.0_DP, struc_format_out, outfile )
                !
                ! ...Save the structure name file to print it
                artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)
                !
                ! save data
                CALL save_current_data( "min2" )
                !
                ! ...Communicate to the engine it is finished
                CALL flag_false()
                !
                ! signal convergence flag
                lconv = .true.
                lend = lconv  !! Maybe don't need anymore
                !
                ! ...Save the Energy difference as saddle - current
                de_fwd = etot_saddle - etot_step
                !
                call write_inter_report( fpush_factor, &
                     [de_back, de_fwd, etot_init, etot_final, etot_step] )
                !
             END IF
             !
          END IF
          !
       END IF
       !
    END IF RELAX




    !! WHAT FOR THIS BLOCK???
    !!  This should be in check_force()
    IF( etot_step - etot_init > etot_diff_limit ) then
       error_message = 'ENERGY EXCEEDS THE LIMIT'//trim(error_message)
       CALL save_current_data( "latest", error_code=ARTN_ERR_LARGE_ENER )
       lconv = .true.
       lerror = .true.
       call flag_false()
    ENDIF

    IF( istep + 1 > nevalf_max ) then ! istep start at 0
       error_message = 'NUMBER OF STEPS EXCEEDS THE LIMIT'//trim(error_message)
       CALL save_current_data( "latest", error_code=ARTN_ERR_NUMSTEP )
       lconv = .true.
       lerror = .true.
       call flag_false()
       call write_comment( trim(filout), "NUMBER OF STEPS EXCEEDS THE LIMIT")
    ENDIF




    !
    ! check if we should perform the lanczos algorithm
    !
    ! Lanczos at the end. Reason: check convergence at saddle before going into
    ! un-needed lanczos near saddle.
    !
    LANCZOS_: IF ( llanczos ) THEN
       !
       !==========================================
       ! Perform Lanczos algo, one step at a time
       !==========================================
       !
       disp =LANC
       IF (ilanc == 0 ) THEN
          !
          ! first iteraction of current lanczos call
          !
          IF( lanczos_always_random )THEN
             ! generate random initial vector
             call random_array( 3*nat, v_in, force_step )
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
       ENDIF
       !
       ! apply constraints from the engine. Works only with engines which fill if_pos!! (not lammps)
       !
       IF ( ANY(if_pos(:,:) == 0) ) THEN
          DO na=1,nat
             DO icoor=1,3
                IF (if_pos(icoor,na) == 1 ) if_pos_ct = if_pos_ct + 1
             ENDDO
          END DO
          IF ( if_pos_ct < nlanc .and. if_pos_ct /= 0 ) nlanc = if_pos_ct
          v_in(:,:) = v_in(:,:)*if_pos(:,:)
          force_step(:,:) = force_step(:,:)*if_pos(:,:)
       ENDIF
       !
       !
       CALL lanczos( nat, v_in, push, force_step, &
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
          ! lanczos_at_min does not do anything currently
          IF ( .NOT. in_lanczos_at_min ) THEN
             !
             IF ( lowest_eigval < eigval_thr     .OR.  &
                  (.NOT.lbasin.AND.lowest_eigval < 0.0_DP) )THEN
                ! structure is out of the basin (above inflection),
                ! in next step make a push with the eigenvector
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
                IF ( .NOT. lbasin .AND. lowest_eigval > 0.0 ) THEN
                   !
                   ! ... Here the system is into a positive inflection area.
                   ! We can try to cross it several times or stop the programm.
                   IF( inewchance < nnewchance ) THEN
                      ! ... Reinitialize the 1st vector of lanczos for the next time.
                      ! This can be usefull to avoid lanczos beeing blocked by a bias last eigenvector
                      call random_array( 3*nat, v_in, push_initial_vector )
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
                      push(:,:) = -SIGN(1.0_DP,ddot(3*nat,force_step,1,push,1))*push(:,:)/norm2(push)*push_step_size
                   ELSE
                      ! ... Stop
                      error_message = 'EIGENVALUE LOST, try to increase nnewchance or nsmooth'
                      lconv = .true.
                      lerror = .true.
                      call flag_false()
                      !!
                      !! set latest data
                      CALL save_current_data( "latest", error_code=ARTN_ERR_EIGVAL_LOST )
                      exit LANCZOS_
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
          ! ...Compare the eigenvec with the previous one
          !
          a1 = ddot( 3*nat, eigenvec, 1, old_lanczos_vec, 1 )
          a1 = abs( a1 )
          ! set current eigenvec for comparison in next step
          old_lanczos_vec = eigenvec
          !
          ! finish lanczos for now
          !
          llanczos = .false.
          IF ( in_lanczos_at_min ) lrelax = .true.
          !
          ! reset lanczos size for next call
          !
          nlanc = lanczos_max_size
          !
       ENDIF
       !
    ENDIF LANCZOS_



    !
    !! --- Finalization Block
    !
    IF( lconv )THEN
       !
       ! ...Print in the OUTPUT
       IF( verbose > 1 )THEN
          OPEN( NEWUNIT = u0, FILE = filout, FORM = 'formatted', STATUS = 'old', POSITION = 'append', IOSTAT = ios )
          WRITE( u0,'(5x, "|> BLOCK FINALIZE..")')
          !  WRITE( *,'(5x, "|> BLOCK FINALIZE..")')
          WRITE( u0,'(5X, "|> number of steps:",1x, i0)') istep
          close( u0, status="keep" )
       ENDIF

       !... SCHEMA FINILIZATION
       lend = lconv
       !
       ! next displacement should be zero
       displ_vec = 0.0_DP
       ! disp = VOID
       disp = RELX    !! Mode RELX to fill force = displ_vec and converge

       ! reload initial positions
       ! tau(:,:) = tau_init(:,order(:))

       call flag_false()
       IF( lerror ) THEN
          ! there is an error, write report
          error_message = 'STOPPING DUE TO ERROR:'//trim(error_message)
          call write_fail_report( void, etot_step )
          ! STOP
          ! RETURN
       ENDIF

       !
       ! ...Here we should load the next minimum if the user ask
       IF( lmove_nextmin ) CALL move_nextmin( nat, tau )


       IF( lserialize_output ) call artn_data_ptr% dump_generated()
       !
       ! ...The search IS FINISHED
       ! RETURN
       !
    ENDIF
    !
    ! ...Increment the ARTn-step
    istep = istep + 1
    !
    ! [art]
  END SUBROUTINE artn


  !> @details
  !! C-wrapper to artn() routine.
  !! Visible as "artn()" from C.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~{.c}
  !! void artn(const double *f,
  !!           const double *etot,
  !!           const int nat,
  !!           int const *ityp,
  !!           double *const tau,
  !!           const int *order,
  !!           const double *lat,
  !!           const int *if_pos,
  !!           int *disp,
  !!           double *disp_vec,
  !!           bool *lconv);
  !!~~~~~~~~~~~~~~~~
  !!
  SUBROUTINE artn_c( c_force, c_etot_eng, c_nat, c_ityp, c_tau, c_order, c_at, &
       c_if_pos, c_disp, c_displ_vec, c_lconv )&
       bind(C, name="artn")
    use, intrinsic :: iso_c_binding, only: c_int, c_double, c_bool

    real( c_double ),      intent(in)    :: c_force(3,c_nat)     !  force calculated by the engine
    real( c_double ),      intent(in)    :: c_etot_eng           !  total energy in current step
    integer(c_int), value, intent(in)    :: c_nat                !  number of atoms
    integer( c_int ),      intent(inout) :: c_ityp(c_nat)        !  atom types
    real( c_double ),      intent(inout) :: c_tau(3,c_nat)       !  atomic positions (needed for output only)
    integer( c_int ),      intent(in)    :: c_order(c_nat)       !  engine order of atom
    real( c_double ),      intent(in)    :: c_at(3,3)            !  lattice parameters in alat units
    integer( c_int ),      intent(in)    :: c_if_pos(3,c_nat)    !  coordinates fixed by engine
    integer( c_int ),      intent(out)   :: c_disp               !  stage for move_mode
    real( c_double ),      intent(out)   :: c_displ_vec(3,c_nat) !  displacement vector communicated to move mode
    logical( c_bool ),     intent(out)   :: c_lconv              !  flag for controlling convergence

    !! fortran variables
    integer           :: nat
    real(dp)          :: etot_eng
    integer           :: order(c_nat)
    real(dp)          :: at(3,3)
    integer           :: ityp(c_nat)
    integer           :: if_pos(3,c_nat)
    character(len=3), allocatable  :: atm(:)
    real(dp)          :: force(3,c_nat)
    real(dp)          :: tau(3,c_nat)
    real(dp)          :: displ_vec(3,c_nat)
    integer           :: disp
    logical           :: lconv

    !! transfer c input to fortran
    nat      = int( c_nat )
    etot_eng = real( c_etot_eng, DP )
    order    = int( c_order )
    at       = real( c_at, DP )
    ityp     = int( c_ityp )
    if_pos   = int( c_if_pos )
    force    = real( c_force, DP )
    tau      = real( c_tau, DP )

    !! unused
    allocate( atm(1:1), source="XXX")

    call artn( force, etot_eng, nat, ityp, atm, tau, order, at, if_pos, disp, displ_vec, lconv )

    !! transfer output to C
    c_displ_vec = real( displ_vec, c_double )
    c_disp      = int( disp, c_int )
    c_lconv     = logical( lconv, c_bool )

    !! inout args
    ! c_etot_eng = real( etot_eng, c_double )
    c_tau      = real( tau, c_double )

    deallocate( atm )
  end SUBROUTINE artn_c


end module m_artn
