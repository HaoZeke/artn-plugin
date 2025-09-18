submodule( h_artn_units ) convert_units

  use m_artn_error
  use m_artn_tools, only: parser
  implicit none


  !! variables local to this submodule
  REAL(DP), save :: E2au, L2au, T2au, F2au, H2au, M2au
  REAL(DP), save :: au2E, au2L, au2T, au2F, au2H, au2M
  character(len=32), save :: cL="", cE=""

contains


  !!==========================
  !! Centralize routines for convert and unconvret:
  !! Can be called for any real(DP),rank=0 variable name, will be properly converted
  !! according to <name>.
  !! NOTE: this could be made better to include flags for each variable,
  !! if it is already converted or not, to avoid error of converting multiple times.
  !!==========================

  module function convert_param( name, val_in, ierr )result(val)
    !! Convert units of variable <name>, with values <val_in>
    !! into artn units. If <name> is not converted, do nothing, no error.
    !! Error happens only if units are not defined.
    !! NOTE: this is NOT "elemental" function -> need to loop for arrays
    character(*), intent(in)    :: name
    real(DP),     intent(in)    :: val_in
    integer, optional, intent(out)   :: ierr
    real(DP) :: val

    val = val_in
    if( .not. units_are_set ) then
       !! units are not known
       if( present(ierr) ) ierr = ERR_UNITS
       call err_set( ERR_UNITS, __FILE__, __LINE__, msg="Cannot convert, engine_units are not set!")
       return
    end if

    !! for each name that we convert
    select case( name )
    case( &
         "forc_thr" &
         ); val = convert_force( val_in )

    case( &
         "eigval_thr", &
         "eigval_step", &
         "eigval_sad", &
         "eigval_min1", &
         "eigval_min2" &
         ); val = convert_hessian( val_in )

    case(&
         "etot_diff_limit", &
         "etot_init", &
         "etot_step", &
         "etot_sad", &
         "etot_min1", &
         "etot_min2" &
         ); val = convert_energy( val_in )

    case( &
         "push_step_size", &
         "push_step_size_per_atom", &
         "eigen_step_size", &
         "lanczos_disp" &
         ); val = convert_length( val_in )

    case default
       !! do nothing (name is not converted)
    end select
    if( present(ierr) )ierr = 0
  end function convert_param

  module function unconvert_param( name, val_in, ierr )result(val)
    !! Unconvert units of variable <name>, with values <val_in>
    !! from artn units. If <name> is not converted, do nothing, no error.
    !! Error happens only if units are not defined.
    !! NOTE: this is NOT "elemental" function -> need to loop for arrays
    character(*), intent(in)    :: name
    real(DP),     intent(in)    :: val_in
    integer, optional, intent(out)   :: ierr
    real(DP) :: val

    val = val_in
    if( .not. units_are_set ) then
       !! units are not known
       if( present(ierr)) ierr = ERR_UNITS
       call err_set( ERR_UNITS, __FILE__, __LINE__, msg="Cannot unconvert, engine_units are not set! name:"//trim(name))
       return
    end if

    !! for each name that we convert
    select case( name )
    case( &
         "forc_thr" &
         ); val = unconvert_force( val_in )

    case( &
         "eigval_thr", &
         "eigval_step", &
         "eigval_sad", &
         "eigval_min1", &
         "eigval_min2" &
         ); val = unconvert_hessian( val_in )

    case(&
         "etot_diff_limit", &
         "etot_step", &
         "etot_init", &
         "etot_sad", &
         "etot_min1", &
         "etot_min2" &
         ); val = unconvert_energy( val_in )

    case( &
         "push_step_size", &
         "push_step_size_per_atom", &
         "eigen_step_size", &
         "lanczos_disp" &
         ); val = unconvert_length( val_in )

    case default
       !! do nothing (name is not converted)
    end select
    if( present(ierr) ) ierr = 0
  end function unconvert_param



  !......................................................................................
  ! FORCE

  !> @brief Convert the engine force to a.u.
  !> @param[in] f   force in engine unit
  !> @return a force in atomic units a.u.
  module elemental pure function convert_force( f )result( fau )
    real(DP), intent( in ) :: f
    real(DP) :: fau
    fau = f * F2au
  end function convert_force

  !> @brief Convert the force in a.u. in engine units
  !> @param [in] fau   force in a.u.
  !> @return a force in engine units
  module elemental pure function unconvert_force( fau )result( f )
    real(DP), intent( in ) :: fau
    real(DP) :: f
    f = fau * au2F
  end function unconvert_force



  !......................................................................................
  ! HESSIAN

  !> @brief Convert the engine hessian to a.u.
  !> @param [in] h   hessian in engine unit
  !> @return a hessain in atomic units a.u.
  module elemental pure function convert_hessian( h )result( hau )
    real(DP), intent( in ) :: h
    real(DP) :: hau
    hau = h * H2au
  end function convert_hessian

  !> @brief Convert the force in a.u. in engine units
  !> @param [in] hau   force in a.u.
  !> @return a force in engine units
  module elemental pure function unconvert_hessian( hau )result( h )
    real(DP), intent( in ) :: hau
    real(DP) :: h
    h = hau * au2H
  end function unconvert_hessian



  !......................................................................................
  ! LENGTH

  !> @brief Convert the engine length to a.u.
  !> @param [in] p   position in engine unit
  !> @return a position in a.u.
  module elemental pure function convert_length( p )result( pau )
    real(DP), intent( in ) :: p
    real(DP) :: pau
    pau = p * L2au
  end function convert_length

  !> @brief Convert the a.u. length to engine unit
  !> @param [in] pau   position in a.u.
  !> @return  position in engine units
  module elemental pure function unconvert_length( pau )result( p )
    real(DP), intent( in ) :: pau
    real(DP) :: p
    p = pau * au2L
  end function unconvert_length



  !......................................................................................
  ! ENERGY

  !> @brief Convert the engine energy to a.u.
  !> @param [in] e   enegy in engine unit
  !> @return an energy in a.u.
  module elemental pure function convert_energy( e )result( eau )
    real(DP), intent( in ) :: e
    real(DP) :: eau
    eau = e * E2au
  end function convert_energy

  !> @brief Convert the a.u. energy to engine unit
  !> @param [in] eau   energy in a.u.
  !> @return an energy in engine units
  module elemental pure function unconvert_energy( eau )result( e )
    real(DP), intent( in ) :: eau
    real(DP) :: e
    e = eau * au2E
  end function unconvert_energy



  !......................................................................................
  ! TIME

  !> @brief Convert the engine time to a.u.
  !> @param [in] t   time in engine unit
  !> @return a time in a.u.
  module elemental pure function convert_time( t )result( aut )
    real(DP), intent( in ) :: t
    real(DP) :: aut
    aut = t * T2au
  end function convert_time

  !> @brief Convert the a.u. TIME to engine unit
  !> @param [in] aut   time in a.u.
  !> @return a time in engine units
  module elemental pure function unconvert_time( aut )result( t )
    real(DP), intent( in ) :: aut
    real(DP) :: t
    t = aut * au2T
  end function unconvert_time


  !......................................................................................
  ! Return UNIT
  !> @brief Return the unit in character of the quantity received
  !> @param[in] quantity   (length, energy, force or hessian)
  !> @return correct unit in character
  module function unit_char( quantity )result( uchar )
    character(*), intent(in) :: quantity
    character(:), allocatable :: uchar

    select case( quantity )
    case( 'length' );  uchar = trim(cL)
    case( 'energy' );  uchar = trim(cE)
    case( 'force' );   uchar = trim(cE)//'/'//trim(cL)
    case( 'hessian' ); uchar = trim(cE)//'/'//trim(cL)//to2
    end select

  end function unit_char


  !......................................................................................
  !> @brief
  !!   Receive the keyword of Engine which contains the engine name and
  !!   type of unit. Maybe we can also define the units for the output
  !
  !> @note
  !!   Important to know:
  !!   Hessian, Force, Position, Time are exchange with Engine
  !!   Energy is converted only for the ouput
  !!   Mass is needed for the fire integration. Defined in Ry can
  !!   change depending the unit used.
  !
  !> WARNING: The mass in LJ is 1 but can be defined by the user so
  !!  we should take care about this
  !
  !> @param[in,out]  txt Name of the Engine
  !
  module subroutine make_units( txt, lerror )
    use m_artn_tools, only: to_lower
    use d_artn_params, only: struc_format_out
    implicit none
    ! -- Arguments
    character(*), intent( inout ) :: txt
    logical, intent(out) :: lerror
    ! -- Local variables
    character(:), allocatable :: engine, mode, words(:)
    integer :: n

    logical :: verbose
    ! verbose = .true.
    verbose = .false.

    lerror = .false.

    ! ...Extract the Keyword from the engine_units
    n = parser( trim(txt), "/",  words )
    if( n >= 1 )then
       allocate( engine, source = trim(words(1)))
    else
       allocate(engine, source = "")
    endif
    if( n > 1 ) then
       allocate( mode, source=trim(words(2)))
    else
       allocate(mode, source = "" )
    endif

    ! ...Initialization

    E2au = 1.0_DP
    au2E = 1.0_DP
    L2au = 1.0_DP
    au2L = 1.0_DP
    T2au = 1.0_DP
    au2T = 1.0_DP
    M2au = 1.0_DP
    au2M = 1.0_DP

    F2au = 1.0_DP
    au2F = 1.0_DP
    H2au = 1.0_DP
    au2H = 1.0_DP


    ! ...Select the units as function of engine and mode

    select case( to_lower(engine) )


       ! ---------------------------------------------- QE
    case( 'qe', 'quantum_espresso' )

       !! set default struc_format_out to xsf
       if( .not. defined_var( struc_format_out ) ) struc_format_out = "xsf"

       !! Energy: Rydberg
       E2au = 1._DP !/ Ry2eV
       au2E = 1._DP !  Ry2eV

       !! Length: Bohr
       L2au = 1._DP ! / B2A
       au2L = 1._DP !  B2A

       !! Time: aut(Ry)
       T2au = 1._DP
       au2T = 1._DP

       !! Mass: au(Ry) AMU/2
       Mass = AMU_RY

       !! Force: Ry/au
       F2au = 1._DP !/ au2E / L2au
       au2F = 1._DP !/ F2au

       !! Hessian
       H2au = 1.0_DP
       au2H = 1.0_DP

       cE = "Ry"  ! "Ry"
       cL = "a.u." ! "bohr"
       !strg_units = '(27X, "[Ry]",17X,"-----------[Ry/a.u.]----------",3X,"Ry/a.u.^2")'

       ! ---------------------------------------------- LAMMPS
    case( 'lammps' )

       !! set default struc_format_out to xyz
       if( .not. defined_var( struc_format_out ) ) struc_format_out = "xyz"


       select case( to_lower(mode) )

       case( 'metal' )

          !! Energy: eV
          E2au = 1.0_DP / Ry2eV
          au2E = Ry2eV

          !! Length: Angstrom
          L2au = 1.0_DP / B2A
          au2L = B2A
          ! L2au=1.0_DP
          ! au2L = 1.0_DP

          !! Time: picosecond
          T2au = 1.0_DP / AU_PS
          au2T = AU_PS
          ! write(*,*) "T2au",T2au
          ! write(*,*) "au2T",au2T

          !! Mass: gram/mol
          Mass = AMU_RY
          ! write(*,*) "MASS",mass

          !! Force
          F2au = E2au / L2au
          au2F = 1.0_DP / F2au
          ! write(*,*) "F2au", F2au
          ! write(*,*) "au2F",au2F
          ! write(*,*) "ry2ev/b2a",ry2ev/b2a
          ! au2F = L2au / E2au
          ! au2F = (1.0_DP / B2A) / (1.0_DP / Ry2eV ) = Ry2ev / B2A

          !! Hessian
          H2au = F2au / L2au
          au2H = 1.0_DP / H2au

          cE = "eV"
          !cL = AA
          cL = "Ang"

       case( 'lj' )
          !! Energy: 1
          E2au = 1.0_DP
          au2E = 1.0_DP
          !! Length: 1
          L2au = 1.0_DP
          au2L = 1.0_DP
          !! Mass: 1
          Mass = 1.0_DP
          !! Time: 1
          T2au = 1.0_DP
          au2T = 1.0_DP
          !! Force
          F2au = E2au / L2au
          au2F = 1.0_DP / F2au

          !! Hessian
          H2au = F2au / L2au
          au2H = 1.0_DP / H2au

          cE = "LJ"
          cL = "LJ"


       case( 'real' )
          !! Energy: Kcal/mol
          E2au = 1.0_DP / Ry2kcalPmol
          au2E = Ry2kcalPmol

          !! Length: Angstrom
          L2au = 1.0_DP / B2A
          au2L = B2A

          !! Time: femtosecond
          T2au = 1.0_DP / AU_FS
          au2T = AU_FS

          !! Mass: gram/mol
          Mass = AMU_RY

          !! Force
          F2au = E2au / L2au
          au2F = 1.0_DP / F2au

          !! Hessian
          H2au = F2au / L2au
          au2H = 1.0_DP / H2au

          cE = "Kcal/mol"
          !cL = AA
          cL = "Ang"

          !case( 'si' )
          !! Energy: J
          !! Length: metre
          !! Time: second
          !case( 'cgs' )
          !! Energy: ergs
          !! Length: cm
          !! Time: second
          !case( 'electron' )
          !! Energy: Hatree
          !! Length: Bohr
          !! Time: femtosecond
          !case( 'micro' )
          !! Energy: picogram-micrometer^2/microsecond^2
          !! Length: micrometer
          !! Time: microsecond
          !case( 'nano' )
          !! Energy: attogram-nanometer^2/nanosecond^2
          !! Length: nanometer
          !! Time: nanosecond

       case default
          print*, " * ARTn::WARNING::make_units::LAMMPS/unit not defined "
          lerror = .true.
          call err_set(ERR_UNITS, __FILE__,__LINE__,msg="make_units fail for engine_units: "//trim(txt))
          return

       end select

    case ('siesta' )

       !! set default struc_format_out to xyz
       if( .not. defined_var( struc_format_out ) ) struc_format_out = "xyz"

       !! Energy: Rydberg
       E2au = 1.0_DP
       au2E = 1.0_DP

       !! Length: Bohr
       L2au = 1.0_DP
       au2L = 1.0_DP

       !! Time: fs
       T2au = 1.0_DP
       ! T2au = 1.0_DP / AU_FS
       ! au2T = AU_FS
       au2T = 1.0_DP

       ! T2au = 41.341374575751
       ! au2T = 1.0_DP/T2au
       ! T2au = 1.0_DP
       ! au2T = 1.0_DP
       ! write(*,*) "artn units: AU_FS",au2T

       !! Mass: au(Ry) AMU/2
       !! Mass: AMU_AU !! Hartree?
       ! Mass = AMU_RY/2.133107
       ! Mass = AMU_AU/2.133107
       ! Mass = 2.0_DP  !! due to 1/2 in fire
       Mass = AMU_RY


       !! Force: Ry/au
       F2au = 1.0_DP !/ au2E / L2au
       au2F = 1.0_DP !/ F2au

       ! F2au = 1.0/2.133107
       ! au2F = 1.0/F2au

       !! Hessian
       H2au = 1.0_DP
       au2H = 1.0_DP
       H2au = F2au / L2au
       au2H = 1/H2au

       cE = "Ry"  ! "Ry"
       cL = "a.u." ! "bohr"

              ! ---------------------------------------------- VASP
    case ('vasp' )
       !! set default struc_format_out to xyz
       if( .not. defined_var( struc_format_out ) ) struc_format_out = "vasp"
       !if( .not. defined_var( struc_format_out ) ) struc_format_out = "xyz"

       !! Energy: eV
       E2au = 1.0_DP / RY2EV
       au2E = RY2EV

       !! Length: Angstrom
       L2au = 1.0_DP / B2A
       au2L = B2A

       !! Time: fs
       T2au = 1.0_DP
       !T2au = 1.0_DP / RY2EV
       !au2T =  RY2EV
       au2T = 1.0_DP

       !! Mass: g/mol
       !Mass = 1.0_DP
       Mass =  AMU_RY ! / RY2EV

       !! Force: ev/angs
       F2au =  E2au / L2au
       au2F = 1.0_DP / F2au

       !! Hessian
       H2au = F2au / L2au
       au2H = 1.0_DP / H2au

       cE = "eV"  ! "eV"
       cL = "Ang" ! "angstrom"

       ! ---------------------------------------------- OTHER
    case default
       print*, " * ARTn::WARNING::make_units::Engine not defined "
       lerror = .true.
       call err_set(ERR_UNITS, __FILE__,__LINE__,msg="make_units fail for engine_units: "//trim(txt))
       return

    end select


    ! ...Define the output units string
    strg_units = '(27X, "['//trim(cE)//']",31X,"-----------['//trim(cE)//'/'//   &
         trim(cL)//']-----------",2X,"['//trim(cE)//'/'//trim(cL)//to2//']   ['//trim(cL)//']")'

    !! flag true
    units_are_set = .true.

    if( verbose )then
       write(*,*) repeat("-",50)
       write(*,1) " * ARTn::UNITS::E2au::", E2au, "au2E", au2E
       write(*,1) " * ARTn::UNITS::L2au::", L2au, "au2L", au2L
       write(*,1) " * ARTn::UNITS::T2au::", T2au, "au2T", au2T
       write(*,1) " * ARTn::UNITS::F2au::", F2au, "au2F", au2F
       write(*,1) " * ARTn::UNITS::H2au::", H2au, "au2H", au2H
       write(*,1) " * ARTn::UNITS::Mass::", Mass
       write(*,*) repeat("-",50)
1      format(*(1x,a,1x,g15.5))
    endif


  end subroutine make_units





end submodule convert_units
