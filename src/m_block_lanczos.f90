module m_block_lanczos


  use precision, only: DP
  use m_tools, only: random_array
  implicit none


  !! global counter for lanczos iteration steps
  integer, save, public :: ilanc = 0

  interface
     module function block_lanczos( disp_code, displ_vec, if_pos )result(ierr)
       use artn_params, only: natoms
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


end module m_block_lanczos
