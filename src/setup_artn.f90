


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
SUBROUTINE setup_artn( nat, i_in, filnam, error )

  USE iso_c_binding, ONLY : C_SIZE_T
  USE units
  USE artn_params !, ONLY:  iunartout, iunstruct, verbose, &
!       lrelax, linit, lperp, leigen, llanczos, lrestart, lbasin, lpush_over, lpush_final, lbackward, lmove_nextmin,  &
!       irelax, istep, iperp, ieigen, iinit, ilanc, ismooth, iover, isearch, ifound, nlanc, nperp, noperp, nperp_step,  &
!       if_pos_ct, lowest_eigval, etot_init, etot_step, etot_saddle, etot_final, de_back, de_fwd, &
!       ninit, neigen, lanczos_max_size, nsmooth, push_mode, dist_thr, forc_thr, &
!       fpara_thr, eigval_thr, frelax_ene_thr, push_step_size, current_step_size, eigen_step_size, fpush_factor, &
!       push_ids, add_const, push, eigenvec, types, tau_step, force_step, tau_init, tau_saddle, eigen_saddle, v_in, &
!       VOID, INIT, PERP, EIGN, LANC, RELX, OVER, zseed, &
!       engine_units, struc_format_out, elements, ilanc_save, &
!       inewchance, nnewchance, &
!       push_over, ran3, a1, old_lanczos_vec, lend, fill_param_step, &
!       filin, filout, sadfname, initpfname, eigenfname, restartfname, warning, flag_false,  &
!       prefix_min, nmin, prefix_sad, nsaddle, artn_resume, natoms, old_lowest_eigval, &
!       lanczos_always_random, etot_diff_limit, error_message, prev_push, SMTH, random_array

  IMPLICIT NONE
  !
  ! -- Arguments
  INTEGER,             INTENT(IN) :: nat,i_in
  CHARACTER (LEN=255), INTENT(IN) :: filnam
  LOGICAL,             INTENT(OUT) :: error
  !
  ! -- Local Variables
  LOGICAL                         :: file_exists, verb
  INTEGER                         :: ios, u0
  INTEGER(c_size_t)               :: mem
  CHARACTER(LEN=256)              :: ftmp, ctmp
  REAL(DP)                        :: z
  !
  verb = .true.
  verb = .false.
  !
  error = .false.
  !
  INQUIRE( file = filnam, exist = file_exists )
  !
  if(verb) write(*,'(5x,a)') "|> Initialize_ARTn()"
  !
  IF( .not.file_exists )THEN
    !
    WRITE(*,*) "ARTn: Input file does not exist!"
    lrelax = .true.
    RETURN
    ! 
  ELSE !%! FILE EXIST
    !
    ! set up defaults for flags and counters
    !
    lrelax            = .false.
    linit             = .true.
    lbasin            = .true.
    lperp             = .false.
    llanczos          = .false.
    leigen            = .false.
    !lsaddle          = .false.
    lpush_over        = .false.
    lpush_final       = .false.
    lbackward         = .true.
    lrestart          = .false.
    lmove_nextmin     = .false.
    lread_param       = .false.
    lnperp_limitation = .true.  ! We always use nperp limitaiton
    lend              = .false.
    !
    verbose           = 0
    ifails            = 0
    iartn             = 0
    istep             = 0
    iinit             = 0
    iperp             = 0
    iperp_save        = 0
    ilanc             = 0
    ilanc_save        = 0
    ieigen            = 0
    ismooth           = 0
    if_pos_ct         = 0
    irelax            = 0
    iover             = 0
    zseed             = 0
    ifound            = 0
    isearch           = 0
    inewchance        = 0

    prev_disp         = VOID
    prev_push         = VOID
    restart_freq      = 0
    !
    old_lowest_eigval = HUGE(lanczos_disp)
    lowest_eigval     = 0.D0
    fpush_factor      = 1.0
    push_over         = 1.0_DP
    !
    ! Defaults for input parameters
    ninit             = 3
    nperp_step        = 1
    nperp             = -1 !def_nperp_limitation( nperp_step )
    noperp            = 0
    neigen            = 1
    nsmooth           = 0
    nmin              = 0
    nsaddle           = 0
    nnewchance        = 0
    nrelax_print      = 5   ! print every 5 RELX step
    !
    dist_thr          = NAN
    delr_thr          = NAN
    forc_thr          = NAN
    fpara_thr         = NAN
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

    bilan = 0.0_DP
    !
    lanczos_disp = NAN
    lanczos_max_size = 16
    lanczos_min_size = 3
    lanczos_eval_conv_thr = NAN
    lanczos_always_random = .false.
    !
    engine_units = 'qe'
    !
    ! Default convergence parameter
    converge_property = "maxval"
    !
    ! error string
    error_message = ''
    !
    ! Allocate the arrays
    IF ( .not. ALLOCATED(add_const) )        ALLOCATE( add_const(4,nat),     source = 0.D0 )
    IF ( .not. ALLOCATED(push_ids) )         ALLOCATE( push_ids(nat),        source = 0    )
    IF ( .not. ALLOCATED(push) )             ALLOCATE( push(3,nat),          source = 0.D0 )
    IF ( .not. ALLOCATED(eigenvec) )         ALLOCATE( eigenvec(3,nat),      source = 0.D0 )
    IF ( .not. ALLOCATED(eigen_saddle) )     ALLOCATE( eigen_saddle(3,nat),  source = 0.D0 )
    IF ( .not. ALLOCATED(tau_saddle) )       ALLOCATE( tau_saddle(3,nat),    source = 0.D0 )
    IF ( .not. ALLOCATED(tau_step) )         ALLOCATE( tau_step(3,nat),      source = 0.D0 )
    IF ( .not. ALLOCATED(force_step) )       ALLOCATE( force_step(3,nat),    source = 0.D0 )
    IF ( .not. ALLOCATED(force_old) )        ALLOCATE( force_old(3,nat),     source = 0.D0 )
    IF ( .not. ALLOCATED(v_in) )             ALLOCATE( v_in(3,nat),          source = 0.D0 )
    IF ( .not. ALLOCATED(elements) )         ALLOCATE( elements(300),        source = "XXX")
    IF ( .not. ALLOCATED(delr) )             ALLOCATE( delr(3,nat),          source = 0.D0 )
    IF ( .not. ALLOCATED(nperp_limitation) ) ALLOCATE( nperp_limitation(10), source = -2   )
    IF ( .not. ALLOCATED(types) )            ALLOCATE( types(nat),           source = 0    )
    !
    ! ...Compute the size of ARTn lib
    mem = 0
    mem = mem + sizeof( add_const    )
    mem = mem + sizeof( push_ids     )
    mem = mem + sizeof( push         )
    mem = mem + sizeof( eigenvec     )
    mem = mem + sizeof( eigen_saddle )
    mem = mem + sizeof( tau_saddle   )
    mem = mem + sizeof( tau_step     )
    mem = mem + sizeof( force_step   )
    mem = mem + sizeof( force_old    )
    mem = mem + sizeof( v_in         )
    mem = mem + sizeof( elements     )
    mem = mem + sizeof( delr         )
    !
    IF( verb )THEN
      print*, "* LIB-ARTn MEMORY: ", mem, "Bytes"
      print*, "* LIB-ARTn MEMORY: ", real(mem)/1.0e3, "KB"
      print*, "* LIB-ARTn MEMORY: ", real(mem)/1.0e6, "MB"
    ENDIF
    !
    ! read the ARTn input file
    !
    OPEN( UNIT = i_in, FILE = filnam, FORM = 'formatted', STATUS = 'unknown', IOSTAT = ios)
    READ( NML = artn_parameters, UNIT = i_in)
    CLOSE( UNIT = i_in, STATUS = 'KEEP')
    lread_param = .true.
    !
    ! inital number of lanczos iterations
    nlanc = lanczos_max_size
    !
    ! initialize lanczos matrices (user chooses wheter to change lanczos_max_size)
    IF ( .NOT. ALLOCATED(H))    ALLOCATE( H(1:lanczos_max_size,1:lanczos_max_size), source = 0.D0 )
    IF ( .NOT. ALLOCATED(Vmat)) ALLOCATE( Vmat(3,nat,1:lanczos_max_size), source = 0.D0 )
    !
    ! initialize nperp limitation
    CALL nperp_limitation_init( lnperp_limitation )
    !
  ENDIF
  !
  !
  ! --- Read the counter file
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
  if( verb )then
    write(*,2) repeat("*",50)
    write(*,2) "* Units:          ", trim(engine_units)
    write(*,1) "* dist_thr        = ", dist_thr
    write(*,1) "* delr_thr        = ", delr_thr
    write(*,1) "* forc_thr        = ", forc_thr
    write(*,1) "* fpara_thr       = ", fpara_thr
    write(*,1) "* eigval_thr      = ", eigval_thr
    write(*,1) "* frelax_ene_thr       = ", frelax_ene_thr
    !
    write(*,1) "* push_step_size  = ", push_step_size
    write(*,1) "* eigen_step_size = ", eigen_step_size
    write(*,1) "* lanczos_disp           = ", lanczos_disp
    write(*,1) "* lanczos_eval_conv_thr   = ", lanczos_eval_conv_thr
    write(*,2) repeat("*",50)
    1 format(x,a,x,g15.5)
    2 format(*(x,a))
  endif

  !
  ! ...Convert the default values parameters from Engine_units
  !! For the moment the ARTn units is in a.u. (Ry, L, T)
  !! The default value are in ARTn units but the input values gives by the users
  !! are suppose in engine_units.
  !! We convert the USERS Values in ARTn units to be coherente:
  !! So we convert the value if it's differents from NAN initialized values
  !
  ! distance is in units on input, no need to convert
  if( dist_thr == NAN )then; dist_thr = def_dist_thr; endif
  !
  if( delr_thr == NAN )then; delr_thr = def_delr_thr
  else;                      delr_thr = convert_force( delr_thr ); endif
  !convcrit_init = 1.0d-2
  if( forc_thr == NAN )     then;  forc_thr = def_forc_thr
  else;                            forc_thr = convert_force( forc_thr ); endif
  !convcrit_final = 1.0d-3
  if( fpara_thr == NAN )then; fpara_thr = def_fpara_thr
  else;                            fpara_thr = convert_force( fpara_thr ); endif
  !fpara_convcrit = 0.5d-2
  if( eigval_thr == NAN )then; eigval_thr = def_eigval_thr
  else;                        eigval_thr = convert_hessian( eigval_thr ); endif
  !eigval_thr = -0.01_DP ! in Ry/bohr^2 corresponds to 0.5 eV/Angs^2
  if( frelax_ene_thr == NAN )then; frelax_ene_thr = def_frelax_ene_thr
  else;                       frelax_ene_thr = convert_energy( frelax_ene_thr ); endif
  !etot_diff_limit = 1000.0 eV ~ 80 Ry
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
  ! the default output format is xsf for QE, and xyz otherwise
  if( struc_format_out == '' ) then
     struc_format_out = def_struc_format_out
     if( trim(engine_units) /= 'qe' ) struc_format_out = 'xyz'
  endif
  !
  if( verb )then
    write(*,2) repeat("*",50)
    write(*,2) "* Units:          ", trim(engine_units)
    write(*,1) "* dist_thr        = ", dist_thr
    !write(*,1) "* init_forc_thr   = ", init_forc_thr
    write(*,1) "* forc_thr        = ", forc_thr
    write(*,1) "* fpara_thr       = ", fpara_thr
    write(*,1) "* eigval_thr      = ", eigval_thr
    write(*,1) "* frelax_ene_thr       = ", frelax_ene_thr
    write(*,1) "* etot_diff_limit      = ", etot_diff_limit
    !
    write(*,1) "* push_step_size  = ", push_step_size
    write(*,1) "* eigen_step_size = ", eigen_step_size
    write(*,1) "* lanczos_disp           = ", lanczos_disp
    write(*,1) "* lanczos_eval_conv_thr   = ", lanczos_eval_conv_thr
    write(*,2) repeat("*",50)
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
  case( 'xsf', 'xyz' ); continue
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
  select case( trim(engine_units) )
    case( 'qe','quantum_espresso' ); restart_freq = 0
    case('lammps/real','lammps/metal','lammps/lj'); restart_freq = 1
    case default
       call warning( iunartout, "setup_artn", "Write restart file at each ARTn calls" )
  end select

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
  OPEN( NEWUNIT=u0, file="random_seed.dat" )
  WRITE( u0, * )" zseed = ", zseed
  CLOSE( u0 )
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


