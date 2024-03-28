module m_artn_data

  use precision, only: DP
  use units, only: NAN_REAL, NAN_INT
  implicit none

  save

  !! system properties
  INTEGER :: natoms = -10     !< @brief Number of atoms, to test coherence in structure between steps
  REAL(DP) :: lat(3,3)        !< @brief Box parameter
  logical :: has_error = .false.


  !! current step data
  INTEGER, ALLOCATABLE  :: typ_step(:)         !< @bried atomic types
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
  REAL(DP), ALLOCATABLE :: push_init(:,:)        !< @biref initial push vector
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



  !! tau
  REAL(DP), ALLOCATABLE :: tau_nextmin(:,:)      !< @brief coordinates of the new minimum




  !! eigenvec




  !
  ! stored total energies and energy differences
  REAL(DP) :: etot_final   !< @brief  the total energy of the next minimum along eigenvector
  REAL(DP) :: de_saddle    !< @brief  change in E from starting point
  REAL(DP) :: de_back      !< @brief  backward barrier
  REAL(DP) :: de_fwd       !< @brief  forward barrier


  interface

     !! save_step_data.f90
     module subroutine save_step_data( which, ierr )
       character(*), intent(in) :: which
       integer, intent(out), optional :: ierr
     end subroutine save_step_data

  end interface


contains


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

end module m_artn_data
