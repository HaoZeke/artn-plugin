submodule( m_artn )setup_routines

  use precision, only: DP
  USE units
  USE artn_params
  use m_error
  implicit none
contains


  !---------------------------------------------------------------
  !!> @brief \b SETUP_ARTN
  !
  !> @par Purpose
  !  ============
  !> Sets defaults, reads input and creates ARTn output file
  !
  !> @param[in] nat        INTEGER, Number of Atoms
  !> @param[in] filnam     CHARACTER, Input file name
  !> @param[in] error      LOGICAL, flag if there is an error
  !
  MODULE SUBROUTINE setup_artn( nat, filnam, error )

    USE iso_c_binding, ONLY : C_SIZE_T
    use m_option, only: nperp_limitation_init
    use m_tools, only: to_lower

    IMPLICIT NONE
    !
    ! -- Arguments
    INTEGER,             INTENT(IN) :: nat
    CHARACTER (LEN=255), INTENT(IN) :: filnam
    LOGICAL,             INTENT(OUT) :: error
    !
    ! -- Local Variables
    LOGICAL                         :: file_exists, verb
    INTEGER                         :: ios, u0
    INTEGER(c_size_t)               :: mem
    CHARACTER(LEN=256)              :: ftmp, ctmp, line
    !

    verb = .true.
    verb = .false.
    !
    error = .false.
    !
    if(verb) write(*,'(5x,a)') "|> Initialize_ARTn()"

    !! reset block flags to false
    call flag_false()

    !! === associated to the whole exploration run ======
    !! set only at isearch==0
    ifails            = 0
    ifound            = 0
    nmin              = 0
    nsaddle           = 0
    !! ==================================================
    !
    !
    !!========== local variables associated to current search ==============
    !! NOTE: should be reset for every search
    !!
    !! set local initial state flags
    linit             = .true.
    lbasin            = .true.
    lbackward         = .true.
    lnperp_limitation = .true.  ! We always use nperp limitaiton
    lend              = .false.

    !! zero the counters for this search
    call local_counters_zero()



    !! reset local vars
    prev_disp         = VOID
    prev_push         = VOID

    old_lowest_eigval = 1e3 !1e20 is not coherent with the format in write_report f10.4
    lowest_eigval     = 1e3 !1e20 is not coherent with the format in write_report f10.4
    fpush_factor      = 1
    push_over         = 1.0_DP
    !
    nperp_step        = 1
    ! noperp            = 0
    neigen            = 1
    !
    debrief = 0.0_DP
    ! error string
    error_message = ''
    artn_resume = ''
    !!========== end of variables local to current search =====




    ! ============= initial values for input parameters ====================
    !! NOTE: default values are converted later on
    !! params accessible from input (in namelist artn_parameters)
    lpush_final       = .false.
    lmove_nextmin     = .false.
    verbose           = 0
    zseed             = 0
    restart_freq      = 2
    ninit             = 3
    nevalf_max        = NAN_INT
    nsmooth           = 0
    nnewchance        = 0
    nrelax_print      = 5   ! print every 5 RELX step
    nperp             = -1 !def_nperp_limitation( nperp_step )
    !
    push_dist_thr     = NAN_REAL
    delr_thr          = NAN_REAL
    forc_thr          = NAN_REAL
    alpha_mix_cr      = NAN_REAL
    eigval_thr        = NAN_REAL ! 0.1 Ry/bohr^2 corresponds to 0.5 eV/Angs^2
    frelax_ene_thr    = NAN_REAL ! in Ry; ( etot - etot_saddle ) < frelax_ene_thr
    etot_diff_limit   = NAN_REAL
    push_step_size    = NAN_REAL
    push_step_size_per_atom    = NAN_REAL
    luser_choose_per_atom = .false.
    eigen_step_size   = NAN_REAL
    !
    push_mode         = 'all'
    struc_format_out  = ''

    !
    lanczos_disp = NAN_REAL
    lanczos_max_size = 16
    lanczos_min_size = 3
    lanczos_eval_conv_thr = NAN_REAL
    lanczos_always_random = .false.
    lanczos_at_min = .false.
    !
    engine_units = 'qe'
    !
    ! Default convergence parameter
    converge_property = "maxval"
    !! =============== end of input values =======================
    !
    !
    ! Allocate the arrays
    IF ( .not. ALLOCATED(push_add_const) )   ALLOCATE( push_add_const(4,nat),source = 0.0_DP )
    IF ( .not. ALLOCATED(push_ids) )         ALLOCATE( push_ids(nat),        source = 0      )
    IF ( .not. ALLOCATED(push) )             ALLOCATE( push(3,nat),          source = 0.0_DP )
    IF ( .not. ALLOCATED(eigenvec) )         ALLOCATE( eigenvec(3,nat),      source = 0.0_DP )
    IF ( .not. ALLOCATED(eigen_saddle) )     ALLOCATE( eigen_saddle(3,nat),  source = 0.0_DP )
    IF ( .not. ALLOCATED(tau_saddle) )       ALLOCATE( tau_saddle(3,nat),    source = 0.0_DP )
    IF ( .not. ALLOCATED(tau_step) )         ALLOCATE( tau_step(3,nat),      source = 0.0_DP )
    IF ( .not. ALLOCATED(force_step) )       ALLOCATE( force_step(3,nat),    source = 0.0_DP )
    IF ( .not. ALLOCATED(force_old) )        ALLOCATE( force_old(3,nat),     source = 0.0_DP )
    IF ( .not. ALLOCATED(v_in) )             ALLOCATE( v_in(3,nat),          source = 0.0_DP )
    IF ( .not. ALLOCATED(elements) )         ALLOCATE( elements(300),        source = "XXX"  )
    IF ( .not. ALLOCATED(nperp_limitation) ) ALLOCATE( nperp_limitation(10), source = -2     )
    IF ( .not. ALLOCATED(types) )            ALLOCATE( types(nat),           source = 0      )
    !
    !
    ! See if input file with ARTn params exists, if yes read from it, if not use default params
    !
    INQUIRE( file = filnam, exist = file_exists )
    !
    IF( file_exists ) THEN
       !
       ! read the ARTn params from input file
       !
       OPEN( NEWUNIT = u0, FILE = filnam, FORM = 'formatted', STATUS = 'unknown', IOSTAT = ios)
       !! error opening
       IF( ios /= 0 ) THEN
          error = .true.
          error_message = "Problem opening input file: "//trim(filnam)
          write(*,*) trim(error_message)
          RETURN
       ENDIF
       !! read namelist
       READ( NML = artn_parameters, UNIT = u0, IOSTAT = ios)
       !! attempt to recover error in namelist
       IF( ios /= 0 ) THEN
          BACKSPACE(u0)
          READ(u0, '(a)' ) line
          error = .true.
          error_message = "ERROR in artn input line:"//trim(line)
          write(*,*) trim(error_message)
          RETURN
       END IF
       !
       CLOSE( UNIT = u0, STATUS = 'KEEP')
       !
    ENDIF
    !
    ! lread_param = .true.
    !
    ! inital number of lanczos iterations
    nlanc = lanczos_max_size
    !
    ! initialize lanczos matrices (user chooses wheter to change lanczos_max_size)
    IF ( .NOT. ALLOCATED(H))    ALLOCATE( H(1:lanczos_max_size,1:lanczos_max_size), source = 0.0_DP )
    IF ( .NOT. ALLOCATED(Vmat)) ALLOCATE( Vmat(3,nat,1:lanczos_max_size),           source = 0.0_DP )
    !
    ! initialize nperp limitation
    CALL nperp_limitation_init( lnperp_limitation )
    !
    !
    !
    ! --- Read the counter files
    !
    !! min counter file
    ftmp = trim(prefix_min)//"counter"
    inquire( file=trim(ftmp), exist=file_exists )
    IF( file_exists )then
       open( newunit=ios, file=trim(ftmp), action="read" )
       read(ios,*) ctmp, ctmp, nmin
       close( ios )
    endif
    !
    !! saddle counter file
    ftmp = trim(prefix_sad)//"counter"
    inquire( file=trim(ftmp), exist=file_exists )
    IF( file_exists )then
       open( newunit=ios, file=trim(ftmp), action="read" )
       read(ios,*) ctmp, ctmp, nsaddle
       close( ios )
    endif
    !
    ! --- Define the Units conversion
    !
    call make_units( engine_units )
    !
    ! ...Convert the parameters from engine_units into internal
    !! NOTE: convert is moved to main artn routine
    call convert_artn_params()
    !

    ! the default output format is xsf for QE, and xyz otherwise
    if( struc_format_out == '' ) then
       struc_format_out = "xsf"
       if( trim(engine_units) /= 'qe' ) struc_format_out = 'xyz'
    endif
    !
    !
    ! ...Characters to lower case
    converge_property = to_lower( converge_property )
    struc_format_out = to_lower( struc_format_out )
    engine_units = to_lower( engine_units )

    !! Retsart frenquence
    !select case( trim(engine_units) )
    !  case( 'qe','quantum_espresso' ); restart_freq = 0
    !  case('lammps/real','lammps/metal','lammps/lj'); restart_freq = 1
    !  case default
    !     call warning( iunartout, "setup_artn", "Write restart file at each ARTn calls" )
    !end select
    !
    !
  END SUBROUTINE setup_artn


  SUBROUTINE convert_artn_params()
    !! convert the artn parameters from input units to internal, based on engine_units.
    !! if the param has NAN value, set it to def_* value

    implicit none
    integer :: ierr

    !
    ! ...Convert the default values parameters from Engine_units
    !! For the moment the ARTn units is in a.u. (Ry, L, T)
    !! The default value are in ARTn units but the input values gives by the users
    !! are suppose in engine_units.
    !! We convert the USERS Values in ARTn units to be coherente:
    !! So we convert the value if it's differents from NAN initialized values
    !
    ! distance is in units on input, no need to convert
    if( push_dist_thr == NAN_REAL ) push_dist_thr = def_push_dist_thr
    if( alpha_mix_cr  == NAN_REAL ) alpha_mix_cr  = def_alpha_mix_cr
    !
    !! No convertion for delr_thr because use with position difference that
    !! are not converted in ARTn
    if( delr_thr == NAN_REAL )delr_thr = def_delr_thr
    !if( delr_thr == NAN_REAL )then; delr_thr = def_delr_thr
    !else;                      delr_thr = convert_length( delr_thr ); endif

    if( forc_thr == NAN_REAL )     then
       forc_thr = def_forc_thr
    else
       ! forc_thr = convert_force( forc_thr )
       forc_thr = convert_param( "forc_thr", forc_thr, ierr )
       if( ierr /= 0 ) call err_write(__FILE__, __LINE__)
    endif

    if( eigval_thr == NAN_REAL )then
       eigval_thr = def_eigval_thr
    else
       eigval_thr = convert_hessian( eigval_thr )
    endif

    if( frelax_ene_thr == NAN_REAL )then
       frelax_ene_thr = def_frelax_ene_thr
    else
       frelax_ene_thr = convert_energy( frelax_ene_thr )
    endif

    if( etot_diff_limit == NAN_REAL ) then
       etot_diff_limit = def_etot_diff_limit
    else
       etot_diff_limit = convert_energy( etot_diff_limit )
    endif
    !
    !
    !relax_thr  = -0.01_DP ! in Ry; ( etot - etot_saddle ) < relax_thr
    !
    if( push_step_size == NAN_REAL )then
       push_step_size = def_push_step_size
    else
       push_step_size = convert_length( push_step_size )
    endif


    !push_step_size = 0.3
    if( push_step_size_per_atom == NAN_REAL )then
       push_step_size_per_atom = def_push_step_size
    else
       push_step_size_per_atom = convert_length( push_step_size_per_atom )
       luser_choose_per_atom = .true.
    endif

    if( eigen_step_size == NAN_REAL )then
       eigen_step_size = def_eigen_step_size
    else
       eigen_step_size = convert_length( eigen_step_size )
    endif


    !eigen_step_size = 0.2
    !
    if( lanczos_disp == NAN_REAL )then
       lanczos_disp = def_lanczos_disp
    else
       lanczos_disp = convert_length( lanczos_disp )
    endif


    !lanczos_disp = 1.D-2
    !
    ! lanczos_eval_conv_thr is a relative quantity, no need to be in specific units
    if( lanczos_eval_conv_thr == NAN_REAL )then
       lanczos_eval_conv_thr = def_lanczos_eval_conv_thr
    else
       lanczos_eval_conv_thr = lanczos_eval_conv_thr
    endif
    !lanczos_eval_conv_thr = 1.D-2
    !


  END SUBROUTINE convert_artn_params

end submodule setup_routines
