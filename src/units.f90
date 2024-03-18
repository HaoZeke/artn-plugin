
!> @author Matic Poberznik,
!! @author Miha Gunde,
!! @author Nicolas Salles

!> @brief 
!!   UNITS module contains all the tool to reconize the Engine and its units
!!   to convert the energy/force/length/time in atomic units
!!   Atomic Units (au) in plugin-ARTn is the Rydberg-bohr-aut
!
!> @todo
!!   Change the unit philosophy: In principle ARTn could work whitout 
!!   to convert the quantities. 
!
!> @ingroup ARTn
!
Module units
  !
  use m_tools, only: parser
  use precision, only: DP
  PRIVATE

  PUBLIC :: PI, Mass, B2A,  make_units,   &
            convert_length, unconvert_length,   &
            convert_force, unconvert_force,     &
            convert_hessian, unconvert_hessian, &
            convert_energy, unconvert_energy,   &
            convert_time, unconvert_time, strg_units, unit_char

  PUBLIC :: lower



  REAL(DP), PARAMETER :: PI     = 3.14159265358979323846_DP        !< @brief pi number 

  REAL(DP), PARAMETER :: H_PLANCK_SI      = 6.62607015E-34_DP      !< @brief J s
  REAL(DP), PARAMETER :: K_BOLTZMANN_SI   = 1.380649E-23_DP        !< @brief J K^-1 
  REAL(DP), PARAMETER :: ELECTRON_SI      = 1.602176634E-19_DP     !< @brief C
  REAL(DP), PARAMETER :: ELECTRONVOLT_SI  = 1.602176634E-19_DP     !< @brief J  
  REAL(DP), PARAMETER :: ELECTRONMASS_SI  = 9.1093837015E-31_DP    !< @brief Kg
  REAL(DP), PARAMETER :: HARTREE_SI       = 4.3597447222071E-18_DP !< @brief J
  REAL(DP), PARAMETER :: RYDBERG_SI       = HARTREE_SI/2.0_DP      !< @brief J
  REAL(DP), PARAMETER :: BOHR_RADIUS_SI   = 0.529177210903E-10_DP  !< @brief m
  REAL(DP), PARAMETER :: AMU_SI           = 1.66053906660E-27_DP   !< @brief Kg
  REAL(DP), PARAMETER :: C_SI             = 2.99792458E+8_DP       !< @brief m sec^-1
  REAL(DP), PARAMETER :: NA               = 6.022140857E+23_DP     !< @brief mol^-1

  REAL(DP), PARAMETER :: RY2EV            = 13.605691930242388_DP  !< @brief Ry to eV conversion 
  REAL(DP), PARAMETER :: RY2KCAL          = 5.2065348237317E-22_DP !< @brief Ry to kcal conversion 
  REAL(DP), PARAMETER :: RY2KJ            = 2.17987197E-21_DP      !< @brief Ry to kJoules conversion 
  REAL(DP), PARAMETER :: RY2KCALPMOL      = RY2KCAL*NA             !< @brief Ry to kcal/mole conversion 
  REAL(DP), PARAMETER :: RY2KJPMOL        = RY2KJ*NA               !< @brief Ry to kJoules per mole conversion 
  REAL(DP), PARAMETER :: B2A              = 0.529177210903_DP      !< @brief bohr to angstrom conversion (Used for QE engine)
  REAL(DP), PARAMETER :: AMU_RY2          = 911.44424310865645_DP  !< @brief calculated from QE using DP
  REAL(DP), PARAMETER :: ps2aut           = 41341.374575751 / 2.   !< @brief picosecond to atomic unit of time
  REAL(DP), PARAMETER :: aut2s            = 4.8278E-17_DP          !< @brief atomic units of times to second conversion (Ry atomic unit)

  REAL(DP), PARAMETER :: AMU_AU           = AMU_SI / ELECTRONMASS_SI  !< @brief Dimensionless Hartree
  REAL(DP), PARAMETER :: AMU_RY           = AMU_AU / 2.0_DP           !< @brief Dimensionless Rydberg

  !REAL(DP), PARAMETER :: AU_SEC           = H_PLANCK_SI/(2.*pi)/HARTREE_SI
  REAL(DP), PARAMETER :: AU_SEC           = H_PLANCK_SI/(2.*pi)/RYDBERG_SI    !< @brief Atomic unit of time to second
  REAL(DP), PARAMETER :: AU_PS            = AU_SEC * 1.0E+12_DP               !< @brief Atomic unit of time to picosecond
  REAL(DP), PARAMETER :: AU_FS            = AU_SEC * 1.0E+15_DP               !< @brief Atomic unit of time to femtosecond


  !! Units Character
  character(*), parameter :: AA = char(197)    !< @brief  Angstrom (ANSI code)
  !character(*), parameter :: to2 = char(178)  ! exponent 2
  character(*), parameter :: to2 = "**2"       !< @brief exponent 2

  character(:), allocatable :: cL, cE

  !! Units convertor
  CHARACTER(LEN=256) :: strg_units             !< @brief String containing the unit of the system with the output format 
  REAL(DP) :: Mass                             !< @brief Mass in Rydberg to buid the force - ARTn is in Rydberg (QE)
  REAL(DP) :: E2au, L2au, T2au, F2au, H2au, M2au
  REAL(DP) :: au2E, au2L, au2T, au2F, au2H, au2M

  !........................................INETRNAL VARIABLE
  character(len=:), allocatable :: ctmp(:), words(:)


  interface

     !! convert_units.f90
     module elemental pure function convert_force( f )result( fau )
       real(DP), intent( in ) :: f
       real(DP) :: fau
     end function convert_force
     module elemental pure function unconvert_force( fau )result( f )
       real(DP), intent( in ) :: fau
       real(DP) :: f
     end function unconvert_force
     module elemental pure function convert_hessian( h )result( hau )
       real(DP), intent( in ) :: h
       real(DP) :: hau
     end function convert_hessian
     module elemental pure function unconvert_hessian( hau )result( h )
       real(DP), intent( in ) :: hau
       real(DP) :: h
     end function unconvert_hessian
     module elemental pure function convert_length( p )result( pau )
       real(DP), intent( in ) :: p
       real(DP) :: pau
     end function convert_length
     module elemental pure function unconvert_length( pau )result( p )
       real(DP), intent( in ) :: pau
       real(DP) :: p
     end function unconvert_length
     module elemental pure function convert_energy( e )result( eau )
       real(DP), intent( in ) :: e
       real(DP) :: eau
     end function convert_energy
     module elemental pure function unconvert_energy( eau )result( e )
       real(DP), intent( in ) :: eau
       real(DP) :: e
     end function unconvert_energy
     module elemental pure function convert_time( t )result( aut )
       real(DP), intent( in ) :: t
       real(DP) :: aut
     end function convert_time
     module elemental pure function unconvert_time( aut )result( t )
       real(DP), intent( in ) :: aut
       real(DP) :: t
     end function unconvert_time
     module function unit_char( quantity )result( uchar )
       character(*), intent(in) :: quantity
       character(:), allocatable :: uchar
     end function unit_char




  end interface

 contains

  !......................................................................................
  !> @brief  Convert an Array of Capital letter to lower case letter
  function lower( s1 )result( s2 )
    !
    !> @param[in]  s1   input string, contain some capital letter
    !! @return     s2   string with only lower case
    !
    character(*)       :: s1
    character(len(s1)) :: s2
    character          :: ch
    integer,parameter  :: duc = ichar('A') - ichar('a')
    integer            :: i

    do i = 1,len(s1)
       ch = s1(i:i)
       if (ch >= 'A'.and. ch <= 'Z') ch = char(ichar(ch)-duc)
       s2(i:i) = ch
    end do
  end function lower



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
  subroutine make_units( txt )
    ! -- Arguments
    character(*), intent( inout ) :: txt
    ! -- Local variables
    character(:), allocatable :: engine, mode !, words(:)
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

    select case( lower(engine) )


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

        select case( lower(mode) )

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




end module units


#ifdef DEBUG
#include "artn_debug.f90"
#endif
