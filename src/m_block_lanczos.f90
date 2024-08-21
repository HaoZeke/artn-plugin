module m_block_lanczos


  use m_artn_data, only: natoms
  use precision, only: DP
  use units, only: NAN_REAL
  use m_tools, only: random_array
  implicit none

  private
  public :: reset_lanczos_params
  public :: block_lanczos, ilanc, old_lanczos_vec, a1
  public :: lowest_eigval
  public :: destroy_lanczos
  ! public :: H, Vmat !! needed only by restart

  integer, save :: ilanc = 0      !< @brief global, current lanczos iteration step
  REAL(DP), save, protected :: a1 = 0.0_DP   !< @brief dot product between previous and actual min lanczos vector
  REAL(DP), save :: old_lowest_eigval = NAN_REAL   !< @brief eigenvalue of the last lanczos computation
  REAL(DP), save :: lowest_eigval = NAN_REAL       !< @brief current lowest eigenvalue obtained by lanczos
  REAL(DP), ALLOCATABLE, save :: old_lanczos_vec(:,:) !< @brief Store the previous lanczos vec
  REAL(DP), ALLOCATABLE, save :: v_in(:,:)            !< @brief first lanczos eigenvector
  REAL(DP), ALLOCATABLE :: force_old(:,:)             !< @brief force in the previous step

  !
  REAL(DP), ALLOCATABLE, save :: H(:,:)       !< @brief tridiagonal matrix
  REAL(DP), ALLOCATABLE, save :: Vmat(:,:,:)  !< @brief matrix containing the laczos vectors



  interface
     module function block_lanczos( disp_code, displ_vec, if_pos )result(ierr)
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       INTEGER,          INTENT(IN)    :: if_pos(3,natoms)    !  coordinates fixed by engine
       integer :: ierr
     end function block_lanczos

     module subroutine lanczos( nat, v_in, pushdir, force, &
          ilanc, nlanc, lowest_eigval, lowest_eigvec, displ_vec )
       integer,                    intent(in)    :: nat
       real(dp), dimension(3,nat), intent(in)    :: v_in
       real(dp), dimension(3,nat), intent(in)    :: pushdir
       real(dp), dimension(3,nat), intent(in)    :: force
       integer,                    intent(inout) :: ilanc
       integer,                    intent(inout) :: nlanc
       real(dp),                   intent(inout) :: lowest_eigval
       real(dp), dimension(3,nat), intent(inout) :: lowest_eigvec
       real(dp), dimension(3,nat), intent(out)   :: displ_vec
     end subroutine lanczos
  end interface

contains


  subroutine reset_lanczos_params()
    !! could be bind(C) if needed?
    ilanc = 0
    a1 = 0.0_DP
    old_lowest_eigval = NAN_REAL
    lowest_eigval = NAN_REAL
    if( allocated(old_lanczos_vec) ) old_lanczos_vec = 0.0_DP
    if( allocated(v_in) ) v_in = 0.0_DP
    if( allocated(H) ) H = 0.0_DP
    if( allocated(Vmat) ) Vmat = 0.0_DP
    if( allocated(force_old)) force_old = 0.0_DP
  end subroutine reset_lanczos_params

  subroutine destroy_lanczos()
    if( allocated(old_lanczos_vec) ) deallocate(old_lanczos_vec)
    if( allocated(v_in) ) deallocate(v_in)
    if( allocated(H) ) deallocate(H)
    if( allocated(Vmat) ) deallocate(Vmat)
    if( allocated(force_old)) deallocate(force_old)
  end subroutine destroy_lanczos

end module m_block_lanczos
