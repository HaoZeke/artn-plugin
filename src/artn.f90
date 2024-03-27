module m_artn
  use precision, only: DP
  use m_error
  implicit none


  interface



     !! block_pushinit.f90
     module function block_pushinit( disp_code, displ_vec )result(ierr)
       use artn_params, only: natoms
       integer, intent( out ) :: disp_code
       real(DP), intent( out ) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_pushinit

     !! block_perprelax.f90
     module function block_perprelax( nat, fperp, disp_code, displ_vec )result(ierr)
       use artn_params, only: natoms
       integer, intent(in) :: nat
       real(DP), intent(in) :: fperp(3,nat)
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_perprelax

     !! block_pusheigen.f90
     module function block_pusheigen( disp_code, displ_vec )result(ierr)
       use artn_params, only: natoms
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_pusheigen

     !! block_pushover.f90
     module function block_pushover( disp_code, displ_vec )result(ierr)
       use artn_params, only: natoms
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3, natoms)
       integer :: ierr
     end function block_pushover

     !! block_finalize.f90
     module function block_finalize( lconv, lerror, disp_code, displ_vec )result(ierr)
       use artn_params, only: natoms
       logical, intent(in) :: lconv
       logical, intent(in) :: lerror
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_finalize






     !! setup_artn.f90
     ! module subroutine setup_artn2( nat, filnam, lerror )
     !   integer,      intent(in)  :: nat
     !   character(*), intent(in)  :: filnam
     !   ! integer,      intent(out) :: ierr
     !   logical,      intent(out) :: lerror
     ! end subroutine setup_artn2
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
  !> @param[out]    disp_code   encoder of stage for move_mode
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
  SUBROUTINE artn( force, etot_eng, nat, ityp, atm, tau, order, at, if_pos, disp_code, displ_vec, lconv )

    !> [art]
    USE units
    use artn_params
    use m_option
    use artn_data, only: ARTN_ERR_EIGVAL_LOST, ARTN_ERR_NUMSTEP, ARTN_ERR_LARGE_ENER, ARTN_ERR_OTHER
    use artn_save_data
    use m_tools, only: make_filename, random_array, field_split, check_force_convergence
    use m_tools, only: push_over_procedure

    use m_setup_artn

    use m_artn_report, only: write_end_report, write_fail_report, write_comment
    use m_artn_report, only: write_struct
    use m_artn_report, only: write_initial_report, write_header_report
    use m_artn_report, only: write_report, write_inter_report
    use m_artn_report, only: ilanc_save, prev_push

    use m_block_lanczos, only: block_lanczos, ilanc, lowest_eigval
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
    INTEGER,          INTENT(OUT)   :: disp_code        !  encoder of stage for move_mode
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
    integer                         :: u0, if_pos_ct, ierr


    write(*,*) "enter artn with istep",istep
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
    disp_code = VOID


    outfile = "none"

    !! miha
    natoms = nat

    !! miha2
    !! check if setup has been done or not
    if( isetup == 0 ) then
       call err_set(ERR_OTHER, __FILE__,__LINE__,msg="setup_artn has not beed done!" )
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if


    !
    ! ... Initialize artn
    istep0: IF( istep == 0 )THEN !! -------------------------------------------------------------------- ISTEP = 0
       !
       lend = .false.
       ! call setup_artn2( nat, trim(filin), lerror )
       ! if( lerror ) then
       !    call err_write(__FILE__,__LINE__)
       !    lconv = .true.
       !    call flag_false
       !    exit istep0
       ! end if

       ! !
       ! ! ...Initialize if it is the first search
       ! IF( isearch == 0 ) CALL setup_artn( nat, filin, lerror )
       ! !
       ! IF ( lerror ) THEN
       !    disp_code = void
       !    error_message = 'PROBLEM IN SETUP_ARTN():'//trim(error_message)
       !    lconv = .true.
       !    call flag_false()
       !    exit istep0
       ! ENDIF
       ! !
       ! ! ... call the refresh to get data from interactive mode if present
       ! call refresh_artn( nat, lerror )
       ! !
       ! IF ( lerror ) THEN
       !    disp_code = void
       !    error_message = 'PROBLEM IN REFRESH():'//trim(error_message)
       !    lconv = .true.
       !    call flag_false()
       !    exit istep0
       ! ENDIF
       ! !
       ! ! ... convert to artn units
       ! ! call convert_artn_params()
       ! !
       
       ! !!==============================
       ! !! move into setup
       ! !!
       ! ! ...Initialize pushvect and eigenvec accoriding to user's choice
       ! write(*,*) "before start_guess",eigenvec(1,1)
       ! lerror = start_guess( nat, push, eigenvec )
       ! write(*,*) "after start_guess",eigenvec(1,1)
       ! if( lerror ) then
       !    call err_write(__FILE__, __LINE__)
       !    lconv = .true.
       !    call flag_false()
       !    exit istep0
       ! end if
       ! !!==============================
       
       ! ! ... check for cohenrence among the input parameters
       ! call check_artn_params( nat, lerror )
       ! !
       ! IF( lerror ) THEN
       !    disp_code = void
       !    error_message = "PROBLEM IN CHECK_ARTN_PARAMS:"//trim(error_message)
       !    lconv = .true.
       !    call flag_false()
       !    exit istep0
       ! ENDIF



       !
       ! ...Fill variables of artn_params (arrays are ordered !!): needs to know engine_units
       !    natoms, lat, etot_step, types, force_step, tau_step
       CALL Fill_param_step( nat, at, order, ityp, tau, etot_eng, force, lerror )
       !! Something went wrong in filling the arrays!
       IF ( lerror ) THEN
          disp_code = void
          error_message = 'PROBLEM IN FILL_PARAM_STEP():'//trim(error_message)
          lconv = .true.
          call flag_false()
          exit istep0
       ENDIF
       !
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
       !IF( prev_disp_code==VOID ) THEN        !!!!! Maybe too much
       !  IF( .NOT.ALLOCATED(tau_init) ) THEN
       !    ALLOCATE( tau_init, source = tau_step )
       !  ELSE
       !    tau_init = tau_step
       !  ENDIF
       !ENDIF


       !
       ! ...Write the initial structure
       CALL write_struct( at, nat, tau_step, elements, types, push, etot_eng, 1.0_DP, struc_format_out, initpfname )
       !artn_resume = '* Start: '//trim(initpfname)//'.'//trim(struc_format_out)

       !
       ! ...Start to write the output
       CALL write_header_report( )

       !!
       !!==========================================
       !! restart will have to move into setup
       IF( lrestart ) THEN
          !! overwrite previously initialised things with read from restart
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
       END IF
       !!==========================================




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
       !! receive variables from the engine, split force into perp and para, and check if it is converged
       !
       ! ...Fill variables of artn_params (arrays are ordered !!): needs to know engine_units
       !    natoms, lat, etot_step, types, force_step, tau_step
       CALL Fill_param_step( nat, at, order, types, tau, etot_eng, force, lerror )
       !! somehing went wrong
       IF( lerror ) THEN
          error_message = "PROBLEM WITH FILL_PARAM_STEP():"//trim(error_message)
          call save_current_data( "latest", error_code=ARTN_ERR_OTHER )
          ierr = block_finalize( .true., .true., disp_code, displ_vec )
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


    !! artn is already finished but called more times.
    IF( lend ) THEN
       ! write(*,*) "ARTn has already finished, RETURN"
       if( verbose > 1 ) call write_comment( trim(filout), "Enter in ARTn but already finished, RETURN")

       !! call finalize, even if not done anything, since we always need to fill the variables:
       !! disp_code, displ_vec, and lconv
       ierr = block_finalize( .true., .false., disp_code, displ_vec )
       lconv = .true.
       return
    END IF
    !



    !
    !  the basic ARTn blocks: init, perp, eigen
    !
    IF ( linit ) THEN
       !
       ! initial displacement , then switch off linit, and pass to lperp
       ! set displ_vec = push, and set flags for next step (lperp or llanczos)
       ierr = block_pushinit( disp_code, displ_vec )
       !
    ELSE IF ( lperp ) THEN

       ! set displ_vec = fperp
       ierr = block_perprelax( nat, fperp, disp_code, displ_vec )

       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          call flag_false()
          lconv = .true.
       end if

    ELSE IF ( leigen  )THEN

       ! set displ_vec = eigenvec*current_step_size and set lperp=.true.
       ierr = block_pusheigen( disp_code, displ_vec )

       !
       ! Write the latest eigenvec to a file (eigenvec should be in force position)
       !
       CALL write_struct( at, nat, tau_step, elements, types, eigenvec, &
            etot_eng, 1.0_DP, struc_format_out, eigenfname )
       ! !
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
       !
       ! set relevant counters to zero
       ! iperp = 0

    ENDIF
    !
    ! ...If saddle point is reached
    ! This block performs only the PUSH to adjacent minima after the saddle point is found
    !
    IF ( lpush_over ) THEN

       !
       !
       ! do we do a final push ?
       !
       IF ( lpush_final ) THEN
          !
          ! perform step_over
          ierr = block_pushover( disp_code, displ_vec )
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
          !! should be block finalzie====
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
       disp_code = RELX
       displ_vec = force_step
       irelax    = irelax + 1
       ilanc     = 0
       iperp     = 0
       prev_push = disp_code !! Save the previous displacement (disp_code is overwritten just few lines above, is this correct?)
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
             disp_code         = LANC
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
                disp_code = RELX
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
       ierr = block_finalize( .true., .true., disp_code, displ_vec )
    ENDIF

    IF( istep + 1 > nevalf_max ) then ! istep start at 0
       error_message = 'NUMBER OF STEPS EXCEEDS THE LIMIT'//trim(error_message)
       CALL save_current_data( "latest", error_code=ARTN_ERR_NUMSTEP )
       call write_comment( trim(filout), "NUMBER OF STEPS EXCEEDS THE LIMIT")
       ierr = block_finalize( .true., .true., disp_code, displ_vec )
    ENDIF




    !
    ! check if we should perform the lanczos algorithm
    !
    ! Lanczos at the end. Reason: check convergence at saddle before going into
    ! un-needed lanczos near saddle.
    !
    LANCZOS_: IF ( llanczos ) THEN
       !
       ierr = block_lanczos( disp_code, displ_vec, if_pos )
       ! write(*, "(3(f9.4,1x))")displ_vec
       !
       if( ierr /= 0 ) then
          ierr = block_finalize( .true., .true., disp_code, displ_vec )
          call err_write(__FILE__,__LINE__)
          return
       end if
       !
    ENDIF LANCZOS_



    !
    !! --- Finalization Block
    !
    IF( lconv )THEN
       !
       !
       ierr = block_finalize( lconv, lerror, disp_code, displ_vec )
       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          return
       end if


       !
       ! reload initial positions
       tau(:,:) = tau_init(:,order(:))
       !
       ! ...Here we should load the next minimum if the user ask
       IF( lmove_nextmin ) CALL move_nextmin( nat, tau )

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
  !!           int *disp_code,
  !!           double *disp_vec,
  !!           bool *lconv);
  !!~~~~~~~~~~~~~~~~
  !!
  SUBROUTINE artn_c( c_force, c_etot_eng, c_nat, c_ityp, c_tau, c_order, c_at, &
       c_if_pos, c_disp_code, c_displ_vec, c_lconv )&
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
    integer( c_int ),      intent(out)   :: c_disp_code          !  encoder of stage for move_mode
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
    integer           :: disp_code
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

    call artn( force, etot_eng, nat, ityp, atm, tau, order, at, if_pos, disp_code, displ_vec, lconv )

    !! transfer output to C
    c_displ_vec = real( displ_vec, c_double )
    c_disp_code      = int( disp_code, c_int )
    c_lconv     = logical( lconv, c_bool )

    !! inout args
    ! c_etot_eng = real( etot_eng, c_double )
    c_tau      = real( tau, c_double )

    deallocate( atm )
  end SUBROUTINE artn_c



end module m_artn
