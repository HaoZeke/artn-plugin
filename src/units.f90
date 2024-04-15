
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
  implicit none
  PRIVATE

  PUBLIC :: NAN_REAL, NAN_INT, NAN_STR, PI, Mass, B2A,  make_units,   &
            convert_length, unconvert_length,   &
            convert_force, unconvert_force,     &
            convert_hessian, unconvert_hessian, &
            convert_energy, unconvert_energy,   &
            convert_time, unconvert_time, strg_units, unit_char, &
            units_are_set, convert_param, unconvert_param

  PUBLIC :: CALLER_IS_ENGINE, CALLER_IS_API, defined_var, allocate_var
  PUBLIC :: lenstr_local, size_i1d, size_r1d, size_r2d
  PUBLIC :: is_inf, is_finite, is_nan


  INTEGER, PARAMETER :: &
       CALLER_IS_ENGINE = 10, &
       CALLER_IS_API    = 20

  !! initializer values
  !!  -- probably to move into setup_artn
  INTEGER, PARAMETER :: NAN_INT = huge( 1 )
  REAL(DP), PARAMETER :: NAN_REAL = HUGE( 1.0_DP )  !< @brief Biggest number in DP representation
  CHARACTER(len=*), PARAMETER :: NAN_STR = "none"


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

  REAL(DP), PARAMETER :: AMU_AU           = AMU_SI / ELECTRONMASS_SI  !< @brief Dimensionless Hartree ~= 1822.88848
  REAL(DP), PARAMETER :: AMU_RY           = AMU_AU / 2.0_DP           !< @brief Dimensionless Rydberg ~= 911.444243

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

  logical :: units_are_set = .false.


  interface

     !! convert_units.f90
     module function convert_param( name, val_in, ierr )result(val)
       character(*), intent(in)    :: name
       real(DP),     intent(in)    :: val_in
       integer, optional, intent(out)   :: ierr
       real(DP) :: val
     end function convert_param
     module function unconvert_param( name, val_in, ierr )result(val)
       character(*), intent(in)    :: name
       real(DP),     intent(in)    :: val_in
       integer, optional, intent(out)   :: ierr
       real(DP) :: val
     end function unconvert_param


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
     module subroutine make_units( txt, lerror )
       character(*), intent( inout ) :: txt
       logical, intent(out) :: lerror
     end subroutine make_units




  end interface


  interface defined_var
     module procedure :: defined_int, defined_real, defined_str
  end interface defined_var

  interface allocate_var
     module procedure :: allocate_int1d, allocate_int2d
     module procedure :: allocate_real1d, allocate_real2d, allocate_real3d
     module procedure :: allocate_str1d
  end interface allocate_var

  interface is_inf
     module procedure :: is_inf_int, is_inf_real
  end interface is_inf
  interface is_finite
     module procedure :: is_finite_int, is_finite_real
  end interface is_finite
  interface is_nan
     module procedure :: is_nan_int, is_nan_real
  end interface is_nan

contains


  !!  -- probably to move into setup
  !! check if value is NAN, Inf, or 'none' then variable is not defined
  pure function defined_int( val )result(val_defined)
    integer, intent(in) :: val
    logical :: val_defined
    val_defined = .true.
    !! value == NAN_INT signifies undefined
    if( abs(val) .eq. NAN_INT ) val_defined = .false.
    !! check for Inf or NaN
    val_defined = is_inf(val)
    val_defined = is_nan(val)
  end function defined_int
  pure function defined_real( val )result(val_defined)
    real(DP), intent(in) :: val
    logical :: val_defined
    val_defined = .true.
    !! check within some precision (value == NAN_REAL signifies undefined)
    if( abs(val) .gt. NAN_REAL-1.0_DP) val_defined = .false.
    !! check for Inf or NaN
    val_defined = is_inf( val )
    val_defined = is_nan( val )
  end function defined_real
  pure function defined_str( val )result(val_defined)
    character(len=*), intent(in) :: val
    logical :: val_defined
    val_defined = .false.
    if( len_trim(val) == 0) return
    if( trim(adjustl(val)) /= NAN_STR ) val_defined = .true.
  end function defined_str


  !! modif from: https://github.com/equipez/infnan
  pure elemental function is_inf_int( val )result(inf)
    integer, intent(in) :: val
    logical :: inf
    inf = ( abs(val) > NAN_INT )
  end function is_inf_int
  pure elemental function is_finite_int( val ) result(fin)
    integer, intent(in) :: val
    logical :: fin
    fin = (val <= NAN_INT .and. val >= -NAN_INT )
  end function is_finite_int
  pure elemental function is_nan_int( val )result(nan)
    integer, intent(in) :: val
    logical :: nan
    nan = ( .not.is_finite(val) .and. (.not.is_inf(val)) )
    nan = ((.not. is_inf(val)) .and. (.not. (val <= NAN_INT .and. val >= -NAN_INT))) .or. nan
  end function is_nan_int
  pure elemental function is_inf_real( val )result(inf)
    real(DP), intent(in) :: val
    logical :: inf
    inf = ( abs(val) > NAN_REAL )
  end function is_inf_real
  pure elemental function is_finite_real( val ) result(fin)
    real(DP), intent(in) :: val
    logical :: fin
    fin = (val <= NAN_REAL .and. val >= -NAN_REAL )
  end function is_finite_real
  pure elemental function is_nan_real( val )result(nan)
    real(DP), intent(in) :: val
    logical :: nan
    nan = ( .not.is_finite(val) .and. (.not.is_inf(val)) )
    nan = ((.not. is_inf(val)) .and. (.not. (val <= NAN_REAL .and. val >= -NAN_REAL))) .or. nan
  end function is_nan_real





  !! allocate arrays.
  !! check if array is already allocated, and has the given dimensions.
  !! If not, allocate
  subroutine allocate_int1d( dim1, array, src_val )
    integer, intent(in) :: dim1
    integer, allocatable, intent(inout) :: array(:)
    integer, intent(in) :: src_val
    if( allocated(array)) then
       if( size(array, 1) == dim1 ) return
       deallocate( array )
    end if
    allocate( array(1:dim1), source=src_val )
  end subroutine allocate_int1d
  subroutine allocate_int2d( dim1, dim2, array, src_val )
    integer, intent(in) :: dim1
    integer, intent(in) :: dim2
    integer, allocatable, intent(inout) :: array(:,:)
    integer, intent(in) :: src_val
    if( allocated(array)) then
       if( size(array, 1) == dim1 .and. &
            size(array, 2) == dim2 ) return
       deallocate( array )
    end if
    allocate( array(1:dim1, 1:dim2), source=src_val )
  end subroutine allocate_int2d
  subroutine allocate_real1d( dim1, array, src_val )
    integer, intent(in) :: dim1
    real(DP), allocatable, intent(inout) :: array(:)
    real(DP), intent(in) :: src_val
    if( allocated(array)) then
       if( size(array, 1) == dim1 ) return
       deallocate( array )
    end if
    allocate( array(1:dim1), source=src_val )
  end subroutine allocate_real1d
  subroutine allocate_real2d( dim1, dim2, array, src_val )
    integer, intent(in) :: dim1
    integer, intent(in) :: dim2
    real(DP), allocatable, intent(inout) :: array(:,:)
    real(DP), intent(in) :: src_val
    if( allocated(array)) then
       if( size(array, 1) == dim1 .and. &
            size(array, 2) == dim2 ) return
       deallocate( array )
    end if
    allocate( array(1:dim1, 1:dim2), source=src_val )
  end subroutine allocate_real2d
  subroutine allocate_real3d( dim1, dim2, dim3, array, src_val )
    integer, intent(in) :: dim1
    integer, intent(in) :: dim2
    integer, intent(in) :: dim3
    real(DP), allocatable, intent(inout) :: array(:,:,:)
    real(DP), intent(in) :: src_val
    if( allocated(array)) then
       if( size(array, 1) == dim1 .and. &
            size(array, 2) == dim2 .and. &
            size(array, 3) == dim3 ) return
       deallocate( array )
    end if
    allocate( array(1:dim1, 1:dim2, 1:dim3), source=src_val )
  end subroutine allocate_real3d
  subroutine allocate_str1d( dim1, strlen, array, src_val )
    integer, intent(in) :: dim1
    integer, intent(in) :: strlen
    character(len=strlen), allocatable, intent(inout) :: array(:)
    character(len=strlen), intent(in) :: src_val
    if( allocated(array)) then
       if( size(array, 1) == dim1 ) return
       deallocate( array )
    end if
    allocate( array(1:dim1), source=src_val )
  end subroutine allocate_str1d





  !! functions
  !! calling size for unallocated stuff can give undefined (random) result, so wrap them
  !! to return size=0 for unallocated
  function lenstr_local( str )result(l)
    character(:), allocatable, intent(in) :: str
    integer :: l
    l = 0
    if( .not. allocated(str)) return
    l = len_trim( str )
  end function lenstr_local
  function size_i1d( i1d )result(l)
    integer, allocatable, intent(in) :: i1d(:)
    integer :: l
    l = 0
    if( .not. allocated(i1d)) return
    l = size( i1d )
  end function size_i1d
  function size_r1d( r1d )result(l)
    real(DP), allocatable, intent(in) :: r1d(:)
    integer :: l
    l = 0
    if( .not. allocated(r1d)) return
    l = size( r1d )
  end function size_r1d
  function size_r2d( r2d, ax )result(l)
    real(DP), allocatable, intent(in) :: r2d(:,:)
    integer, intent(in) :: ax
    integer :: l
    l = 0
    if( .not. allocated(r2d)) return
    l = size( r2d, ax )
  end function size_r2d



end module units


#ifdef DEBUG
#include "artn_debug.f90"
#endif
