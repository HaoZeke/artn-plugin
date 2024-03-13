


!---------------------------------------------------------------
!!> @brief \b SETUP_ARTN
!
!> @par Purpose
!  ============
!> Sets defaults, reads input and creates ARTn output file
!
!> @param[in] nat        INTEGER, Number of Atoms
!> @param[in] i_in       INTEGER, Channel of input
!> @param[in] filnam     CHARACTER, Input file name
!> @param[in] error      LOGICAL, flag if there is an error
!
! SUBROUTINE setup_artn( nat, i_in, filnam, error )
SUBROUTINE setup_artn( nat, filnam, error )

  USE iso_c_binding, ONLY : C_SIZE_T
  USE units
  USE artn_params

  IMPLICIT NONE
  !
  ! -- Arguments
  ! INTEGER,             INTENT(IN) :: nat,i_in
  INTEGER,             INTENT(IN) :: nat
  CHARACTER (LEN=255), INTENT(IN) :: filnam
  LOGICAL,             INTENT(OUT) :: error
  !
  ! -- Local Variables
  LOGICAL                         :: file_exists, verb
  INTEGER                         :: ios, u0
  INTEGER(c_size_t)               :: mem
  CHARACTER(LEN=256)              :: ftmp, ctmp, line
  REAL(DP)                        :: z
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
  if_pos_ct         = 0
  iperp_save        = 0
  ilanc_save        = 0



  !! reset local vars
  prev_disp         = VOID
  prev_push         = VOID

  old_lowest_eigval = 1e3 !1e20 is not coherent with the format in write_report f10.4
  lowest_eigval     = 1e3 !1e20 is not coherent with the format in write_report f10.4
  fpush_factor      = 1
  push_over         = 1.0_DP
  !
  nperp_step        = 1
  noperp            = 0
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
  nevalf_max        = HUGE(1)
  nsmooth           = 0
  nnewchance        = 0
  nrelax_print      = 5   ! print every 5 RELX step
  nperp             = -1 !def_nperp_limitation( nperp_step )
  !
  push_dist_thr     = NAN
  delr_thr          = NAN
  forc_thr          = NAN
  eigval_thr        = NAN ! 0.1 Ry/bohr^2 corresponds to 0.5 eV/Angs^2
  frelax_ene_thr    = NAN ! in Ry; ( etot - etot_saddle ) < frelax_ene_thr
  etot_diff_limit   = NAN
  push_step_size    = NAN
  push_step_size_per_atom    = NAN
  luser_choose_per_atom = .false.
  eigen_step_size   = NAN
  !
  push_mode         = 'all'
  struc_format_out  = ''

  !
  lanczos_disp = NAN
  lanczos_max_size = 16
  lanczos_min_size = 3
  lanczos_eval_conv_thr = NAN
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
  ! ...Compute the size of ARTn lib
  mem = 0
  mem = mem + storage_size( push_add_const )/8*size( push_add_const )
  mem = mem + storage_size( push_ids     )/8*size( push_ids )
  mem = mem + storage_size( push         )/8*size( push )
  mem = mem + storage_size( eigenvec     )/8*size( eigenvec )
  mem = mem + storage_size( eigen_saddle )/8*size( eigen_saddle )
  mem = mem + storage_size( tau_saddle   )/8*size( tau_saddle)
  mem = mem + storage_size( tau_step     )/8*size( tau_step )
  mem = mem + storage_size( force_step   )/8*size( force_step )
  mem = mem + storage_size( force_old    )/8*size( force_old )
  mem = mem + storage_size( v_in         )/8*size( v_in )
  mem = mem + storage_size( elements     )/8*size( elements )
  ! mem = mem + storage_size( delr         )/8*size( delr )
  mem = mem + storage_size( nperp_limitation )/8*size( nperp_limitation )
  mem = mem + storage_size( types        )/8*size( types )
  mem = mem + storage_size( H            )/8*size( H )
  mem = mem + storage_size( Vmat         )/8*size( Vmat )
  !
  IF( verb )THEN
    print*, "* LIB-ARTn MEMORY: ", mem, "Bytes"
    print*, "* LIB-ARTn MEMORY: ", real(mem)/1.0e3, "KB"
    print*, "* LIB-ARTn MEMORY: ", real(mem)/1.0e6, "MB"
  ENDIF

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
  ! call convert_artn_params()
  !
  ! if( verb )then
  !   write(*,2) repeat("*",50)
  !   write(*,2) "* Units:          ", trim(engine_units)
  !   write(*,1) "* push_dist_thr   = ", push_dist_thr
  !   write(*,1) "* delr_thr        = ", delr_thr
  !   write(*,1) "* forc_thr        = ", forc_thr
  !   write(*,1) "* eigval_thr      = ", eigval_thr
  !   write(*,1) "* frelax_ene_thr       = ", frelax_ene_thr
  !   !
  !   write(*,1) "* push_step_size  = ", push_step_size
  !   write(*,1) "* eigen_step_size = ", eigen_step_size
  !   write(*,1) "* lanczos_disp           = ", lanczos_disp
  !   write(*,1) "* lanczos_eval_conv_thr   = ", lanczos_eval_conv_thr
  !   write(*,2) repeat("*",50)
  !   1 format(1x,a,1x,g15.5)
  !   2 format(*(1x,a))
  ! endif


  ! the default output format is xsf for QE, and xyz otherwise
  if( struc_format_out == '' ) then
     struc_format_out = def_struc_format_out
     if( trim(engine_units) /= 'qe' ) struc_format_out = 'xyz'
  endif
  !
  ! Check for errors in input parameters:: (probably should be routine)
  !
  ! ...Character verification
  converge_property = to_lower( converge_property )
  select case( converge_property )
    case( "norm", 'maxval' ); continue
    case default
      call warning( iunartout, "setup_artn",  &
           "converge_property has no good keyword (norm or maxval)" )
      error = .true.
      error_message = " ;converge_property has unsupported value; "//trim(error_message)
     print*, error_message
  end select
  !
  struc_format_out = to_lower( struc_format_out )
  select case( struc_format_out )
  case( 'xsf', 'xyz', 'none' ); continue
  case default
      call warning( iunartout, "setup_artn",  &
           "struc_format_out does not exist" )
     error = .true.
     error_message = " ;struc_format_out has unsupported value; "//trim(error_message)
     print*, error_message
  end select
  !
  engine_units = to_lower( engine_units )
  select case( trim(engine_units) )
  case( 'qe','quantum_espresso','lammps/real','lammps/metal','lammps/lj'); continue
  case default
      call warning( iunartout, "setup_artn",  &
           "engine_unit has unsupprted value" )
     error = .true.
     error_message = " ;engine_units has unsupported value; "
     print*, error_message
  end select

  !! Retsart frenquence
  !select case( trim(engine_units) )
  !  case( 'qe','quantum_espresso' ); restart_freq = 0
  !  case('lammps/real','lammps/metal','lammps/lj'); restart_freq = 1
  !  case default
  !     call warning( iunartout, "setup_artn", "Write restart file at each ARTn calls" )
  !end select

  !
  ! set initial random seed from input, value zseed = 0 means generate random seed
  IF( zseed .EQ. 0) THEN
    !
    ! generate random seed
    CALL random_seed()
    CALL random_number(z)
    z     = z *1e8
    zseed = INT(z)
  ENDIF
  !! Save the seed for DEBUG
  IF( verbose > 0 ) THEN
     OPEN( NEWUNIT=u0, file="random_seed.dat" )
     WRITE( u0, * )" zseed = ", zseed
     CLOSE( u0 )
  END IF
  !


 CONTAINS
  !
  !........................................................
  elemental Function to_lower( str )Result( string )
    !> @brief
    !!   Changes a string to lower case
    !
    !> @param[in]   str     input
    !> @return      string  output
    Implicit None
    Character(*), Intent(IN) :: str
    Character(LEN(str))      :: string

    Integer :: ic, i

    Character(26), Parameter :: cap = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    Character(26), Parameter :: low = 'abcdefghijklmnopqrstuvwxyz'

    !   Capitalize each letter if it is lowecase
    string = str
    do i = 1, LEN_TRIM(str)
        ic = INDEX(cap, str(i:i))
        if( ic > 0 )then
          string(i:i) = low(ic:ic)
        else
          string(i:i) = string(i:i)
        endif
    end do
  END FUNCTION to_lower
  !
END SUBROUTINE setup_artn


SUBROUTINE convert_artn_params()
  !! convert the artn parameters from input units to internal, based on engine_units.
  !! if the param has NAN value, set it to def_* value
  use artn_params
  use units

  implicit none

  !
  ! ...Convert the default values parameters from Engine_units
  !! For the moment the ARTn units is in a.u. (Ry, L, T)
  !! The default value are in ARTn units but the input values gives by the users
  !! are suppose in engine_units.
  !! We convert the USERS Values in ARTn units to be coherente:
  !! So we convert the value if it's differents from NAN initialized values
  !
  ! distance is in units on input, no need to convert
  if( push_dist_thr == NAN ) push_dist_thr = def_push_dist_thr
  !
  !! No convertion for delr_thr because use with position difference that
  !! are not converted in ARTn
  if( delr_thr == NAN )delr_thr = def_delr_thr
  !if( delr_thr == NAN )then; delr_thr = def_delr_thr
  !else;                      delr_thr = convert_length( delr_thr ); endif

  if( forc_thr == NAN )     then;  forc_thr = def_forc_thr
  else;                            forc_thr = convert_force( forc_thr ); endif

  if( eigval_thr == NAN )then; eigval_thr = def_eigval_thr
  else;                        eigval_thr = convert_hessian( eigval_thr ); endif

  if( frelax_ene_thr == NAN )then; frelax_ene_thr = def_frelax_ene_thr
  else;                       frelax_ene_thr = convert_energy( frelax_ene_thr ); endif

  if( etot_diff_limit == NAN ) then; etot_diff_limit = def_etot_diff_limit
  else;    etot_diff_limit = convert_energy( etot_diff_limit ); endif
  !
  !
  !relax_thr  = -0.01_DP ! in Ry; ( etot - etot_saddle ) < relax_thr
  !
  if( push_step_size == NAN )then; push_step_size = def_push_step_size
  else;                            push_step_size = convert_length( push_step_size ); endif
  !push_step_size = 0.3
  if( push_step_size_per_atom == NAN )then
    push_step_size_per_atom = def_push_step_size
  else
    push_step_size_per_atom = convert_length( push_step_size_per_atom )
    luser_choose_per_atom = .true.
  endif

  if( eigen_step_size == NAN )then; eigen_step_size = def_eigen_step_size
  else;                             eigen_step_size = convert_length( eigen_step_size ); endif
  !eigen_step_size = 0.2
  !
  if( lanczos_disp == NAN )then; lanczos_disp = def_lanczos_disp
  else;                   lanczos_disp = convert_length( lanczos_disp ); endif
  !lanczos_disp = 1.D-2
  !
  ! lanczos_eval_conv_thr is a relative quantity, no need to be in specific units
  if( lanczos_eval_conv_thr == NAN )then; lanczos_eval_conv_thr = def_lanczos_eval_conv_thr
  else;                   lanczos_eval_conv_thr = lanczos_eval_conv_thr ; endif
  !lanczos_eval_conv_thr = 1.D-2
  !


END SUBROUTINE convert_artn_params

