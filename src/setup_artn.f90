module m_setup_artn

  use precision, only: DP
  USE units
  USE artn_params
  use m_error
  implicit none


  integer, protected :: isetup=0

  interface

     !! start_guess.f90
     module function start_guess( nat, push, eigenvec )result(lerror)
       integer,  intent(in)  :: nat
       real(dp), intent(out) :: push(3,nat)
       real(dp), intent(out) :: eigenvec(3,nat)
       logical :: lerror
     end function start_guess

     !! push_init.f90
     module subroutine generate_push_init( nat, tau, lat, push_ids, dist_thr, add_const, step_size, mode, vector)
       integer,          intent(in)  :: nat
       real(dp),         intent(in)  :: tau(3,nat)
       real(dp),         intent(in)  :: lat(3,3)
       integer,          intent(in)  :: push_ids(nat)
       real(dp),         intent(in)  :: dist_thr
       real(dp),         intent(in)  :: add_const(4,nat)
       real(dp),         intent(in)  :: step_size
       character(*),     intent(in)  :: mode
       real(dp),         intent(out) :: vector(3,nat)
     end subroutine generate_push_init

     !! clean_artn.f90
     module subroutine clean_artn()bind(C,name="clean_artn")
     end subroutine clean_artn

  end interface

contains


  module subroutine setup_artn2( nat, lerror )
    use m_artn_report, only: prev_push, prev_disp, write_initial_report
    use m_option, only: nperp_limitation_init
    implicit none
    integer,      intent(in)  :: nat
    logical,      intent(out) :: lerror

    integer :: ierr

    lerror=.false.

    !! called for istep that is not zero, do nothing
    if( istep .ne. 0 ) return

    write(*,*) "enter setup2"

    !!
    !! switch the isetup flag to 1
    !!
    isetup = 1

    !!
    !! initialise/read the input params
    !!
    ierr = init_user_params( nat )
    if( ierr /= 0 ) then
       lerror = .true.
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if



    !!
    !! allocate runtime arrays
    !!

    ! could be in start_guess
    call allocate_var( 3, nat, push, 0.0_DP )
    call allocate_var( 3, nat, eigenvec, 0.0_DP )

    ! fill_params?
    call allocate_var( 3, nat, tau_step, 0.0_DP )
    call allocate_var( 3, nat, force_step, 0.0_DP )

    ! ??
    call allocate_var( 300, 3, elements, "XXX" )
    call allocate_var( nat, types, 0 )

    !! should move to data
    call allocate_var( 3, nat, eigen_saddle, 0.0_DP )
    call allocate_var( 3, nat, tau_saddle, 0.0_DP )
    call allocate_var( 3, nat, force_old, 0.0_DP )

    !!
    !! set runtime defaults where needed
    !!
    prev_disp         = VOID
    prev_push         = VOID
    linit             = .true.
    lbasin            = .true.
    lbackward         = .true.
    lend              = .false.

    call local_counters_zero()
    fpush_factor      = 1
    push_over         = 1.0_DP
    nperp_step        = 1
    neigen            = 1
    debrief = 0.0_DP
    error_message = ''
    artn_resume = ''
    call nperp_limitation_init( lnperp_limitation )


    !! find nmin, nsad
    nmin = read_counter_file( trim(prefix_min)//"counter" )
    nsaddle = read_counter_file( trim(prefix_sad)//"counter" )


    !!
    !! destroy previous data
    !!


    !!
    !! check param consistency
    !!


    !!
    !! write header/initial report
    !!
    CALL write_initial_report( filout )

    write(*,*) "exit setup2"
  end subroutine setup_artn2
  !> @details C wrapper to setup_artn2
  !! C header
  !!~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void setup_artn2( const int nat, const char *filnam, bool *cerror)
  !!~~~~~~~~~~~~~~~~~~~~~
  subroutine setup_artn2c( cnat, cerror )bind(C,name="setup_artn2")
    use, intrinsic :: iso_c_binding
    integer( c_int ), value :: cnat
    logical( c_bool), intent(out) :: cerror
    logical :: lerror
    call setup_artn2( int(cnat), lerror )
    cerror = logical(lerror, c_bool )
  end subroutine setup_artn2c




  !> @details
  !! initialise the user-input parameters.
  !! At the end of this function, all parameters will have a sensible value.
  function init_user_params( nat )result(ierr)
    use m_tools, only: to_lower
    implicit none
    integer,      intent(in)  :: nat
    integer :: ierr

    integer :: u0, ios
    character(len=128) :: msg
    character(:), allocatable :: fname
    logical :: lerror


    !! allocate arrays which can be read from input
    !! NOTE:: maybe not the best,, these can change from one run to next
    call allocate_var( 4, nat, push_add_const, 0.0_DP )
    call allocate_var( nat, push_ids, 0 )
    call allocate_var( 10, nperp_limitation, -2 )

    !! if( engine ) then
    !!    undef all except filin
    !!    read file
    !!    make units
    !!    convert
    !! endif
    if( called_from == CALLER_IS_ENGINE ) then
       !
       write(*,*) "we are called from engine"
       !
       ! which filename we read
       allocate( fname, source = filin )
       !
       ! read params from file
       !
       ierr = read_param_file( fname )
       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
          return
       end if

       deallocate( fname )
       !
    else
       write(*,*) "we are called from API!"
    end if

    !!
    !! make units (if already done, it will return without error)
    !!
    call make_units( engine_units, lerror )
    if( lerror ) then
       ierr = ERR_UNITS
       call err_write( __FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    !! check undef, set default values which are already in the units of artn
    !! real
    if( .not. defined_var( forc_thr                )) forc_thr                = def_forc_thr
    if( .not. defined_var( eigval_thr              )) eigval_thr              = def_eigval_thr
    if( .not. defined_var( etot_diff_limit         )) etot_diff_limit         = def_etot_diff_limit
    if( .not. defined_var( push_step_size          )) push_step_size          = def_push_step_size
    if( .not. defined_var( push_step_size_per_atom )) push_step_size_per_atom = def_push_step_size_per_atom
    if( .not. defined_var( eigen_step_size         )) eigen_step_size         = def_eigen_step_size
    if( .not. defined_var( lanczos_disp            )) lanczos_disp            = def_lanczos_disp
    !! str
    if( .not. defined_var( push_mode )) push_mode = "all"
    !! converge_property is alocatable, cannot check with defined_var() ...
    if( .not. allocated(converge_property)) allocate( converge_property, source="maxval")

  end function init_user_params


  !> @details
  !! read parameters from file, immediately make units, and convert the
  !! defined parameters into artn units
  function read_param_file( fname )result(ierr)
    use m_tools, only: to_lower
    implicit none
    character(*), intent(in) :: fname
    integer :: ierr

    integer :: ios, u0
    character(len=128) :: msg
    logical :: lerror

    !!
    !! undef all input vars; might be there from previous run?
    !!
    call undefine_params()

    !!
    !! open input file
    !!
    !!inquire( fname )
    open( newunit=u0, file=fname, status="old", action="read", iostat=ios, iomsg=msg )
    if( ios /= 0 ) then
       ierr = ERR_FILE
       error_message = trim(msg)
       call err_set(ERR_FILE, __FILE__, __LINE__, msg=trim(msg))
       return
    end if

    !!
    !! read artn_parameters namelist
    !! this overwrites anything already set in the params!
    !! Including engine_units
    !!
    read( u0, nml=artn_parameters)
    close( u0, status = "keep" )
    !!
    !! make units
    !!
    engine_units = to_lower( engine_units )
    call make_units( engine_units, lerror )
    if( lerror ) then
       ierr = ERR_UNITS
       call err_write( __FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if
    !!
    !! immediately convert units of the defined values.
    !! Do not touch the undefined.
    !!
    if( defined_var( forc_thr ) ) &
         forc_thr        = convert_param( "forc_thr", forc_thr )

    if( defined_var( eigval_thr ) ) &
         eigval_thr      = convert_param( "eigval_thr", eigval_thr )

    if( defined_var( etot_diff_limit ) ) &
         etot_diff_limit = convert_param( "etot_diff_limit", etot_diff_limit )

    if( defined_var( push_step_size ) ) &
         push_step_size  = convert_param( "push_step_size", push_step_size )

    if( defined_var( push_step_size_per_atom ) ) &
         push_step_size_per_atom = convert_param( "push_step_size_per_atom", push_step_size_per_atom )

    if( defined_var( eigen_step_size ) ) &
         eigen_step_size = convert_param( "eigen_step_size", eigen_step_size )

    if( defined_var( lanczos_disp ) ) &
         lanczos_disp    = convert_param( "lanczos_disp", lanczos_disp )

    ierr = 0

  end function read_param_file




  subroutine undefine_params()
    !!
    !! undefine the user params, set the initial values from artn_params_mod
    !!
    implicit none

    verbose     = 0
    zseed       = 0
    nperp       = -1
    nevalf_max  = NAN_INT
    ninit       = 3
    neigen      = 1
    lanczos_max_size = 16
    lanczos_min_size = 3
    nsmooth          = 0
    nnewchance       = 0
    nrelax_print     = 5
    restart_freq     = 0

    push_dist_thr = def_push_dist_thr
    delr_thr      = def_delr_thr
    push_over     = 1.0_DP
    alpha_mix_cr  = def_alpha_mix_cr
    lanczos_eval_conv_thr = def_lanczos_eval_conv_thr

    forc_thr                = NAN_REAL
    eigval_thr              = NAN_REAL
    etot_diff_limit         = NAN_REAL
    push_step_size          = NAN_REAL
    push_step_size_per_atom = NAN_REAL
    eigen_step_size         = NAN_REAL
    lanczos_disp            = NAN_REAL

    push_mode      = NAN_STR
    engine_units   = NAN_STR
    push_guess     = NAN_STR
    eigenvec_guess = NAN_STR
  end subroutine undefine_params

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
    use m_artn_report, only: prev_push, prev_disp

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
    CHARACTER(LEN=256)              :: line
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

    ! old_lowest_eigval = 1e3 !1e20 is not coherent with the format in write_report f10.4
    ! lowest_eigval     = 1e3 !1e20 is not coherent with the format in write_report f10.4
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
    !
    ! initialize nperp limitation
    CALL nperp_limitation_init( lnperp_limitation )
    !
    !
    !
    ! --- Read the counter files
    !
    nmin = read_counter_file( trim(prefix_min)//"counter" )
    nsaddle = read_counter_file( trim(prefix_sad)//"counter" )
    !
    ! --- Define the Units conversion
    !
    call make_units( engine_units, error )
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


  function read_counter_file( fname )result( number )
    implicit none
    character(*), intent(in) :: fname
    integer :: number

    logical :: file_exists
    character(20) :: dum
    integer :: u0, ios
    character(len=128) :: msg

    !! if file does not exist, return 0
    number = 0

    inquire( file=fname, exist=file_exists )
    if( file_exists ) then
       open(newunit=u0, file=fname, action="read", status="old", iostat=ios, iomsg=msg)
       if( ios/=0) then
          !! should not happen
          call err_set( ERR_OTHER, __FILE__,__LINE__,msg=msg)
          call err_write(__FILE__, __LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if
       read(u0,*) dum, dum, number
       close(u0, status="keep")
    end if
  end function read_counter_file



  !> @brief
  !!   set all counters used locally in single ARTn run to zero
  subroutine local_counters_zero()
    use m_block_lanczos, only: ilanc
    implicit none
    iartn             = 0
    istep             = 0
    iinit             = 0
    iperp             = 0
    ilanc             = 0
    ieigen            = 0
    irelax            = 0
    iover             = 0
    inewchance        = 0
    ismooth           = 0
  end subroutine local_counters_zero



end module m_setup_artn

