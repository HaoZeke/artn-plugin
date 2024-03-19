submodule( units ) convert_units
  implicit none


  !! variables local to this submodule
  REAL(DP) :: E2au, L2au, T2au, F2au, H2au, M2au
  REAL(DP) :: au2E, au2L, au2T, au2F, au2H, au2M
  character(:), allocatable :: cL, cE

  character(len=:), allocatable :: words(:)
contains



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
      case( 'length' );  uchar = cL
      case( 'energy' );  uchar = cE
      case( 'force' );   uchar = cE//'/'//cL
      case( 'hessian' ); uchar = cE//'/'//cL//to2
    end select

  end function




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
  module subroutine make_units( txt )
    use m_tools, only: to_lower
    ! -- Arguments
    character(*), intent( inout ) :: txt
    ! -- Local variables
    character(:), allocatable :: engine, mode!, words(:)
    integer :: n

    logical :: verbose
    ! verbose = .true.
    verbose = .false.


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

        !! Energy: Rydberg
        E2au = 1. !/ Ry2eV
        au2E = 1. !  Ry2eV

        !! Length: Bohr
        L2au = 1. ! / B2A
        au2L = 1. !  B2A

        !! Time: aut(Ry)
        T2au = 1.
        au2T = 1.

        !! Mass: au(Ry) AMU/2
        Mass = AMU_RY

        !! Force: Ry/au
        F2au = 1. !/ au2E / L2au
        au2F = 1. !/ F2au

        !! Hessian
        H2au = 1.0_DP
        au2H = 1.0_DP

        cE = "Ry"  ! "Ry"
        cL = "a.u." ! "bohr"
        !strg_units = '(27X, "[Ry]",17X,"-----------[Ry/a.u.]----------",3X,"Ry/a.u.^2")'

      ! ---------------------------------------------- LAMMPS
      case( 'lammps' )

        select case( to_lower(mode) )

          case( 'metal' )

            !! Energy: eV
            E2au = 1.0_DP / Ry2eV
            au2E = Ry2eV

            !! Length: Angstrom
            L2au = 1.0_DP / B2A
            au2L = B2A

            !! Time: picosecond
            T2au = 1.0_DP / AU_PS
            au2T = AU_PS

            !! Mass: gram/mol
            Mass = AMU_RY

            !! Force
            F2au = E2au / L2au
            au2F = 1.0_DP / F2au

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

        end select


      ! ---------------------------------------------- OTHER
      case default
        print*, " * ARTn::WARNING::make_units::Engine not defined "

    end select


    ! ...Define the output units string
    strg_units = '(27X, "['//cE//']",31X,"-----------['//cE//'/'//   &
                  cL//']-----------",2X,"['//cE//'/'//cL//to2//']   ['//cL//']")'

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
      1 format(*(1x,a,1x,g15.5))
    endif


  end subroutine make_units




end submodule convert_units
