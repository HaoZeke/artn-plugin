module d_artn_data

  use h_artn_precision, only: DP
  use h_artn_units, only: NAN_REAL, NAN_INT
  implicit none

  save

  !! maximal length of filename string
  integer, parameter, private :: maxlen_fname=128

  !!========================
  !!
  !! All data stored here is in internal units of artn.
  !! The units should be converted at the moment of set_data/get_data
  !!
  !!========================

  !> @defgroup group_data
  !> @{

  !! system properties
  INTEGER :: natoms = -10     !< @brief Number of atoms, to test coherence in structure between steps
  REAL(DP) :: lat(3,3)        !< @brief lattice vectors in columns, lat(:,1)=v1, lat(:,2)=v2, lat(:,3)=v3
  logical :: has_error = .false.


  !! current step data
  integer :: nevalf
  INTEGER, ALLOCATABLE  :: typ_step(:)        !< @brief atomic types
  REAL(DP), ALLOCATABLE :: tau_step(:,:)      !< @brief current coordinates (restart)
  REAL(DP), ALLOCATABLE :: force_step(:,:)    !< @brief current force (restart)
  REAL(DP), ALLOCATABLE :: eigen_step(:,:)    !< @brief eigenvector value at current step (updated every step)
  REAL(DP) :: &
       etot_step = NAN_REAL, &  !< @brief total energy of the current step
       delr_step = NAN_REAL, &  !< @brief delr of current step
       eigval_step = NAN_REAL


  !! init state
  INTEGER,  ALLOCATABLE :: typ_init(:)
  REAL(DP), ALLOCATABLE :: tau_init(:,:)         !< @brief initial coordinates
  REAL(DP), ALLOCATABLE :: push_init(:,:)        !< @brief initial push vector
  real(DP) :: &
       etot_init = NAN_REAL, &
       delr_init = NAN_REAL


  !! saddle
  logical :: has_sad = .false.
  real(DP) :: &
       etot_sad = NAN_REAL, &
       delr_sad = NAN_REAL, &
       eigval_sad = NAN_REAL
  integer :: &
       nevalf_sad = -NAN_INT                   !< @brief number of force evaluations to reach saddle
  INTEGER, ALLOCATABLE  :: typ_sad(:)
  REAL(DP), ALLOCATABLE :: tau_sad(:,:)       !< @brief coordinates of saddle point
  REAL(DP), ALLOCATABLE :: eigen_sad(:,:)     !< @brief saddle point eigenvector
  character(len=maxlen_fname) :: fname_sad      !< @brief filename with saddle point (if saved)


  !! min1
  logical :: has_min1 = .false.
  real(DP) :: &
       etot_min1 = NAN_REAL, &
       delr_min1 = NAN_REAL, &
       eigval_min1 = NAN_REAL
  integer :: &
       nevalf_min1 = -NAN_INT
  INTEGER, ALLOCATABLE  :: typ_min1(:)
  REAL(DP), ALLOCATABLE :: tau_min1(:,:)
  character(len=maxlen_fname) :: fname_min1


  !! min2
  logical :: has_min2 = .false.
  real(DP) :: &
       etot_min2 = NAN_REAL, &
       delr_min2 = NAN_REAL, &
       eigval_min2 = NAN_REAL
  integer :: &
       nevalf_min2 = -NAN_INT
  INTEGER, ALLOCATABLE  :: typ_min2(:)
  REAL(DP), ALLOCATABLE :: tau_min2(:,:)
  character(len=maxlen_fname) :: fname_min2



  !! could be cleaned?
  REAL(DP), ALLOCATABLE :: tau_nextmin(:,:)      !< @brief coordinates of the new minimum






  !
  ! stored total energies and energy differences
  REAL(DP) :: etot_final   !< @brief  the total energy of the next minimum along eigenvector
  REAL(DP) :: de_saddle    !< @brief  change in E from starting point
  REAL(DP) :: de_back      !< @brief  backward barrier
  REAL(DP) :: de_fwd       !< @brief  forward barrier

  !> @}

  !! save_step_data.f90
  !..............................................................................
  !> @fn save_step_data( which, ierr )
  !!
  !> @brief 
  !!   Save on an array a selected "which" quantities 
  !!
  !> @param[in]     which    character, selected quantity (init, sad, min1, min2 )
  !> @param[out]    ierr     optional, integer error code
  !!
  interface save_step_data
    module procedure save_step_data
  end interface
  interface
     module subroutine save_step_data( which, ierr )
       character(*), intent(in) :: which
       integer, intent(out), optional :: ierr
     end subroutine save_step_data
  end interface

  !> @cond SKIP
  interface
     !! set_data.f90
     module function set_data_int( name, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: val
       integer :: ierr
     end function set_data_int
     module function set_data_real( name, val )result(ierr)
       character(*), intent(in) :: name
       real(DP), intent(in) :: val
       integer :: ierr
     end function set_data_real
     module function set_data_bool( name, val )result(ierr)
       character(*), intent(in) :: name
       logical, intent(in) :: val
       integer :: ierr
     end function set_data_bool
     module function set_data_str( name, val )result(ierr)
       character(*), intent(in) :: name
       character(*), intent(in) :: val
       integer :: ierr
     end function set_data_str
     module function set_data_int1d( name, dim, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim
       integer, intent(in) :: val(dim)
       integer :: ierr
     end function set_data_int1d
     module function set_data_real1d( name, dim, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim
       real(DP), intent(in) :: val(dim)
       integer :: ierr
     end function set_data_real1d
     module function set_data_real2d( name, dim1, dim2, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim1, dim2
       real(DP), intent(in) :: val(dim1, dim2)
       integer :: ierr
     end function set_data_real2d


     !! get_data.f90
     module subroutine get_data_int( name, val, ierr )
       character(*), intent(in) :: name
       integer, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_data_int
     module subroutine get_data_real( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_data_real
     module subroutine get_data_bool( name, val, ierr )
       character(*), intent(in) :: name
       logical, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_data_bool
     module subroutine get_data_str( name, val, ierr )
       character(*), intent(in) :: name
       character(:), allocatable, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_data_str
     module subroutine get_data_int1d( name, val, ierr )
       character(*), intent(in) :: name
       integer, allocatable, intent(out) :: val(:)
       integer, intent(out) :: ierr
     end subroutine get_data_int1d
     module subroutine get_data_real2d( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), allocatable, intent(out) :: val(:,:)
       integer, intent(out) :: ierr
     end subroutine get_data_real2d


  end interface
  !> @endcond


  !> @fn artn_list_extract()
  !!
  !> @brief
  !! list the variables that can be extracted from d_artn_data
  interface artn_list_extract
    module procedure artn_list_extract
  end interface
  interface
     module subroutine artn_list_extract()
     end subroutine artn_list_extract
  end interface



  !> @defgroup setget_data
  !> @{

  !> @details
  !! Generic function for setting values to the `data` group of variables.
  !! Actual implementation in file: set_data.f90.
  !! The returned value `ierr` has value zero on normal execution, and negative
  !! on error.
  !!
  !! Fortran:
  !! @code{.f90}
  !!     ! signature:
  !!     ! function set_data( name, val ) result( ierr )
  !!     !
  !!     ! description:
  !!     ! name : character(*), name of variable
  !!     ! val  : the value to set
  !!     ! ierr : integer, negative on error, zero otherwise
  !!     use d_artn_data, only: set_data
  !!     integer :: ierr
  !!     ierr = set_data( "natoms", 123 )
  !! @endcode
  !!
  !! The C-wrapper has some additional arguments:
  !! @code{.c}
  !!     // signature:
  !!     // int set_data( const char * const name, const int rank, const int* size, const void *val );
  !!     //
  !!     // description:
  !!     // name  : string of variable name
  !!     // rank  : rank of data in `val`
  !!     // size  : array of size `rank`, each element is size of `val` on each dimension
  !!     // val   : ptr to data
  !!     #include artn.h
  !!     double eval2 = 0.8;
  !!     int ierr = set_data( "eigval_min2", 0, 0, &eval2 );
  !! @endcode

  interface set_data
     !> @cond SKIP
     module procedure :: set_data_int, set_data_real, set_data_str, set_data_bool
     module procedure :: set_data_int1d, set_data_real1d, set_data_real2d
     !> @endcond
  end interface set_data

  !> @details
  !! Generic routine for getting the `data` group variables.
  !! Actual implementation in file: get_data.f90.
  !!
  !! Fortran:
  !! @code{.f90}
  !!     ! signature:
  !!     ! subroutine get_data( name, val, ierr )
  !!     !
  !!     ! description:
  !!     ! name : character(*), name of variable
  !!     ! val  : the obtained value
  !!     ! ierr : integer, negative on error, zero otherwise
  !!     use d_artn_data, only: get_data
  !!     use h_artn_precision, only: DP
  !!     integer :: ierr
  !!     real(DP), allocatable :: pos_sad(:,:)
  !!     call get_data( "tau_sad", pos_sad, ierr )
  !! @endcode
  !!
  !! The C-wrapper:
  !! @code{.c}
  !!     // signature:
  !!     // int get_data( const char *name, void* val );
  !!     //
  !!     // description:
  !!     // name  : string of variable name
  !!     // val   : void ptr to obtained data
  !!     #include artn.h
  !!     void *c_val;
  !!     int ierr = get_data( "eigval_sad", &c_val );
  !!     // read the double value from void *
  !!     double eval_sad = *(double *) c_val;
  !! @endcode
  !!
  interface get_data
     !> @cond SKIP
     module procedure :: get_data_int, get_data_real, get_data_bool, get_data_str
     module procedure :: get_data_int1d, get_data_real2d
     !> @endcond
  end interface get_data

  !> @}


contains


  !> @brief
  !!   Deallocate the array of the module d_artn_data
  !!
  subroutine destroy_data()
    implicit none
    !! set values to nan, deallocate arrays

    !! int
    natoms = -10; nevalf_sad=-NAN_INT; nevalf_min1=-NAN_INT; nevalf_min2=-NAN_INT

    !! logical
    has_error=.false.; has_sad=.false.; has_min1=.false.;has_min2=.false.

    !! real
    etot_step=NAN_REAL; delr_step=NAN_REAL; eigval_step=NAN_REAL
    etot_init=NAN_REAL; delr_init=NAN_REAL
    etot_sad=NAN_REAL; delr_sad=NAN_REAL; eigval_sad=NAN_REAL
    etot_min1=NAN_REAL; delr_min1=NAN_REAL; eigval_min1=NAN_REAL
    etot_min2=NAN_REAL; delr_min2=NAN_REAL; eigval_min2=NAN_REAL

    !! alloc
    if(allocated(typ_step   )) deallocate( typ_step )
    if(allocated(tau_step   )) deallocate( tau_step )
    if(allocated(typ_init   )) deallocate( typ_init )
    if(allocated(tau_init   )) deallocate( tau_init )
    if(allocated(push_init  )) deallocate( push_init )
    if(allocated(force_step )) deallocate( force_step )
    if(allocated(eigen_step )) deallocate( eigen_step )
    if(allocated(typ_sad    )) deallocate( typ_sad )
    if(allocated(tau_sad    )) deallocate( tau_sad )
    if(allocated(eigen_sad  )) deallocate( eigen_sad )
    if(allocated(typ_min1   )) deallocate( typ_min1 )
    if(allocated(tau_min1   )) deallocate( tau_min1 )
    if(allocated(typ_min2   )) deallocate( typ_min2 )
    if(allocated(tau_min2   )) deallocate( tau_min2 )

  end subroutine destroy_data

end module d_artn_data
