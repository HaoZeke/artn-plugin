
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


  !! Units convertor
  CHARACTER(LEN=256) :: strg_units       !< @brief String containing the unit of the system with the output format 
  REAL(DP) :: Mass                       !< @brief Mass in Rydberg to buid the force - ARTn is in Rydberg (QE)

  !........................................INETRNAL VARIABLE
  ! character(len=:), allocatable :: ctmp(:), words(:)


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
     module subroutine make_units( txt )
       character(*), intent( inout ) :: txt
     end subroutine make_units




  end interface

contains



end module units


#ifdef DEBUG
#include "artn_debug.f90"
#endif
