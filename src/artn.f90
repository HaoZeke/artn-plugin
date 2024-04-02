module m_artn
  use m_artn_data, only: natoms
  use precision, only: DP
  use m_error
  implicit none


  interface



     !! block_pushinit.f90
     module function block_pushinit( disp_code, displ_vec )result(ierr)
       integer, intent( out ) :: disp_code
       real(DP), intent( out ) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_pushinit

     !! block_perprelax.f90
     module function block_perprelax( nat, fperp, disp_code, displ_vec )result(ierr)
       integer, intent(in) :: nat
       real(DP), intent(in) :: fperp(3,nat)
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_perprelax

     !! block_pusheigen.f90
     module function block_pusheigen( disp_code, displ_vec )result(ierr)
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_pusheigen

     !! block_pushover.f90
     module function block_pushover( disp_code, displ_vec )result(ierr)
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3, natoms)
       integer :: ierr
     end function block_pushover

     !! block_finalize.f90
     module function block_finalize( lconv, lerror, disp_code, displ_vec )result(ierr)
       logical, intent(in) :: lconv
       logical, intent(in) :: lerror
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       integer :: ierr
     end function block_finalize


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
    use m_artn_data
    USE units
    use artn_params
    use m_option
    use m_tools, only: make_filename, random_array, field_split, check_force_convergence
    use m_tools, only: push_over_procedure, compute_delr_vec, sum_force

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
    ! natoms = nat

    !! miha2
    !! check if setup has been done or not
    if( isetup == 0 ) then
       call err_set(ERR_OTHER, __FILE__,__LINE__,msg="setup_artn has not beed done!" )
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if



    !
    ! ...Fill variables of artn_params (arrays are ordered !!): needs to know engine_units
    !    The variables which are known from engine are filled:
    !        natoms, lat, etot_step, types, force_step, tau_step
    !
    CALL Fill_param_step( nat, at, order, ityp, tau, etot_eng, force, lerror )
    !! Something went wrong in filling the arrays!
    IF ( lerror ) THEN
       disp_code = void
       error_message = 'PROBLEM IN FILL_PARAM_STEP():'//trim(error_message)
       lconv = .true.
       call flag_false()
       call merr(__FILE__,__LINE__,kill=.true.)
    ENDIF


    !
    ! ... Initialize artn
    istep0: IF( istep == 0 )THEN !! -------------------------------------------------------------------- ISTEP = 0
       !
       lend = .false.


       !
       ! ...Start to write the output
       CALL write_header_report( )


       !!
       !! create start guess if needed
       !!
       lerror = start_guess( nat, push, eigenvec )
       if( lerror ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
          return
       end if


       !
       ! call save_current_data( "init" )
       !
       ! ... save initial data
       ! etot_init = etot_step
       ! tau_init = tau_step
       ! delr_init = 0.0_DP
       call save_step_data( "init", ierr )
       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
          return
       end if


       !!
       !!==========================================
       !! restart will overwrite all params
       IF( lrestart ) THEN
          !! overwrite previously initialised things with read from restart
          !
          ! ...Signal that it is a restart
          call write_comment( trim(filout), "Restarted previous ARTn calculation" )
          !
          ! ...Read the FLAGS, FORCES, POSITIONS, ENERGY, ...
          call read_restart( lerror )
          IF( lerror )THEN
             error_message = 'RESTART FILE DOES NOT EXIST'
             lconv = .true.
             call flag_false()
             exit istep0
          ENDIF
          !
          ! ...Overwirte the engine Arrays with data from restart
          tau(:,:) = tau_step(:,order(:))
          ityp(:) = typ_step(order(:))
          !
       END IF
       !!==========================================


       !
       ! ...Write the initial structure
       CALL write_struct( at, nat, tau_step, elements, typ_step, push, etot_eng, &
            1.0_DP, struc_format_out, initpfname )
       artn_resume = '* Start: '//trim(initpfname)//'.'//trim(struc_format_out)


       ! open(newunit=u0,file="sscheck.xyz",status="unknown",position="append")
       ! close(u0, status="delete")

    ENDIF istep0


    !!
    !! fill delr_step
    !!
    ! ! check alloc status of delr_vec
    ! call allocate_var( 3, nat, delr_vec, 0.0_DP )
    ! !! compute delr of current tau with tau_init
    ! call compute_delr_vec( nat, tau_step, tau_init, lat, delr_vec )
    ! call sum_force( delr_vec, nat, delr_step )
    ! open(newunit=u0,file="sscheck.xyz",status="unknown",position="append")
    ! write(u0,*) nat
    ! write(u0,*) 'Lattice="',lat,'" properties=species:I:1:pos:R:3:id:I:1:force:R:3'
    ! do i = 1, nat
    !    write(u0,*) typ_step(i), tau_step(:,i), i, delr_vec(:,i)
    ! end do
    ! close(u0)

    ! ...Split the force field in para/perp field following the push field
    CALL field_split( 3*nat, force_step, if_pos, push, fperp, fpara )

    ! ...Write Output
    CALL write_report( etot_step, force_step, fperp, fpara, lowest_eigval, if_pos, istep, nat )

    if( istep .ne. 0 ) then
       CALL check_force_convergence( nat, force_step, if_pos, fperp, fpara, lforc_conv, lsaddle_conv )
    end if


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
       ! Write the latest eigenvec to a file (eigenvec instead of force in arguments)
       !
       CALL write_struct( at, nat, tau_step, elements, typ_step, eigenvec, &
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
       ! save the saddle point data
       !
       call save_step_data( "sad", ierr )
       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
          return
       end if

       !
       !! store the saddle point data
       ! etot_sad = etot_step
       ! tau_sad = tau_step
       ! eigen_sad = eigenvec
       ! !
       lpush_over = .true.
       ifound = ifound + 1
       !
       ! ...Save the structure
       IF( struc_format_out /= "none" ) call make_filename( outfile, prefix_sad, nsaddle )
       !
       CALL write_struct( at, nat, tau_step, elements, typ_step, force_step, &
            etot_eng, 1.0_DP, struc_format_out, outfile )

       artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)
       !
       ! ...write the report
       CALL write_end_report( lpush_over, lpush_final, etot_step - etot_init )

       !
       !! If the saddle point is lower in energy
       !!  than the initial point: Mode refine
       IF ( etot_sad < etot_init .and. verbose > 1 ) THEN
          call write_comment( filout, "NOTE::E_Saddle < E_init" )
       ENDIF
       !
       ! CALL save_current_data( "sad" )
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
          ! tau(:,:) = tau_init(:,order(:))
          ! ityp(:) = typ_init(order(:))

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
       prev_push = disp_code !! Save the previous displacement
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
             ! We now do lanczos to check the lowest eigenvalue
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
                CALL write_struct( at, nat, tau_step, elements, typ_step, force_step, &
                     etot_eng, 1.0_DP, struc_format_out, outfile )
                artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)
                !
                ! ...Save the minimum if it is new
                !! this shoudl not be done here
                ! call save_min( nat, tau_step )
                !
                ! next step is relax in other direction
                disp_code = RELX
                !
                ! save data
                ! CALL save_current_data( "min1" )

                !
                ! save the min1 data
                !
                call save_step_data( "min1", ierr )
                if( ierr /= 0 ) then
                   call err_write(__FILE__,__LINE__)
                   call merr(__FILE__,__LINE__,kill=.true.)
                   return
                end if


                !
                ! ...restart from saddle point
                tau(:,:)      = tau_sad(:,order(:))
                ityp(:)       = typ_sad(order(:))
                eigenvec(:,:) = eigen_sad(:,:)
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
                de_back = etot_sad - etot_final
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
                CALL write_struct( at, nat, tau_step, elements, typ_step, &
                     force_step, etot_eng, 1.0_DP, struc_format_out, outfile )
                !
                ! ...Save the structure name file to print it
                artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)
                !
                ! save data
                ! CALL save_current_data( "min2" )

                !
                ! save the min2 data
                !
                call save_step_data( "min2", ierr )
                if( ierr /= 0 ) then
                   call err_write(__FILE__,__LINE__)
                   call merr(__FILE__,__LINE__,kill=.true.)
                   return
                end if

                !
                ! ...Save the Energy difference as saddle - current
                de_fwd = etot_sad - etot_step
                !
                call write_inter_report( fpush_factor, &
                     [de_back, de_fwd, etot_init, etot_final, etot_step] )
                !
                ! signal convergence flag
                lconv = .true.
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
       ! CALL save_current_data( "latest", error_code=ARTN_ERR_LARGE_ENER )
       ierr = block_finalize( .true., .true., disp_code, displ_vec )
    ENDIF

    IF( istep + 1 > nevalf_max ) then ! istep start at 0
       error_message = 'NUMBER OF STEPS EXCEEDS THE LIMIT'//trim(error_message)
       ! CALL save_current_data( "latest", error_code=ARTN_ERR_NUMSTEP )
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


       ! overwrite engine arrays
       IF( lmove_nextmin ) then
          !
          ! ...Here we should load the next minimum if the user ask
          CALL move_nextmin( nat, ityp, tau, order )
       else
          !
          ! reload initial positions
          tau(:,:) = tau_init(:,order(:))
          ityp(:) = typ_init(order(:))
       end IF


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
