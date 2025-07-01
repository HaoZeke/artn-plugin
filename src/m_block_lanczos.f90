!
!> @author
!!  Matic Poberznik, 
!!  Miha Gunde, 
!!  Nicolas Salles,
!!  Antoine Jay
!!
!> @brief
!!   Carry on the lanczos procedure for ARTn Algorithm
!
module m_block_lanczos

  use d_artn_data, only: natoms
  use h_artn_precision, only: DP
  use h_artn_units, only: NAN_REAL
  use m_artn_tools, only: random_array
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


  !! block_lanczos.f90
  !..............................................................................
  !> @fn block_lanczos( disp_code, displ_vec, if_pos )result(ierr)
  !!
  !> @brief
  !!   carry on the lanczos procedure 
  !!
  !> @param[out]   disp_code    ARTN step
  !> @param[out]   displ_vec    Atomic displacement 
  !> @param[out]   if_pos       mask for atomic displacement or not 
  !> @return       ierr         integer error code
  interface block_lanczos
    module procedure  block_lanczos
  end interface
  interface
     module function block_lanczos( disp_code, displ_vec, if_pos )result(ierr)
       integer, intent(out) :: disp_code
       real(DP), intent(out) :: displ_vec(3,natoms)
       INTEGER,          INTENT(IN)    :: if_pos(3,natoms)    !  coordinates fixed by engine
       integer :: ierr
     end function block_lanczos
  end interface

  !! lanczos.f90
  !................................................................................
  !> @fn lanczos( nat, v_in, pushdir, force, ilanc, nlanc, lowest_eigval, lowest_eigvec, displ_vec )
  !!
  !> @brief
  !!   Lanczos subroutine for the ARTn algorithm
  !!
  !> @par Purpose
  !!  ============
  !> The idea is to overwrite the 'force' with the vector of desired move,
  !! according to Lanczos diagonalisation algorithm. \n The array 'force' (input)
  !! contains the real forces on structure.
  !!
  !> @param [in]      nat              number of atoms
  !> @param [in]      v_in            Input lanczos vector: only used in first step of each lanczos call
  !> @param [in]      pushdir         List of Direction of push on atoms
  !> @param [in]      force            array of Forces on the atoms
  !> @param [in,out]   ilanc           current step of lanczos
  !> @param [in,out]   nlanc        maximal number of Lanczos steps, at convergence gets overwritten with ilanc value
  !> @param [in,out]   lowest_eigval   Lowest eigenvalue obtained by lanczos algo
  !> @param [in,out]   lowest_eigvec   Lowest eigenvector obtained by lanczos algo
  !> @param [out]     displ_vec       The displacement to perform for next step
  !!
  !> @ingroup Control Block
  !!
  interface lanczos
    module procedure lanczos
  end interface
  interface
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


  !> @brief 
  !!   reset lanczos parameter for the next lanczos step
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

  !> @brief
  !!   Deallocate lanzcos's arrays
  subroutine destroy_lanczos()
    if( allocated(old_lanczos_vec) ) deallocate(old_lanczos_vec)
    if( allocated(v_in) ) deallocate(v_in)
    if( allocated(H) ) deallocate(H)
    if( allocated(Vmat) ) deallocate(Vmat)
    if( allocated(force_old)) deallocate(force_old)
  end subroutine destroy_lanczos

end module m_block_lanczos



