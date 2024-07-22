submodule( m_tools )compute_delr_r
  use precision, only : DP
  implicit none
contains


  !> @brief
  !!   compute the displacement vector for each atom with respect to old_pos
  !
  !> @param[in]  nat       number of atoms
  !! @param[in]  pos       actual position of atoms in 3 dimension
  !! @param[in]  old_pos   reference atomic position
  !! @param[in]  lat       box parameters
  !! @param[out] delr      displacement of each atom
  !
  module subroutine compute_delr_vec( nat, pos, old_pos, lat, delr )
    !
    use m_tools, only: pbc
    implicit none

    INTEGER, intent( in ) :: nat
    REAL(DP), intent( in ) :: pos(3,nat), lat(3,3)
    REAL(DP), intent( in ) :: old_pos(3,nat)
    REAL(DP), intent( out ) :: delr(3,nat)

    integer :: i
    REAL(DP) :: r(3)

    delr = 0.0_DP
    do i = 1, nat
       r = pos(:,i) - old_pos(:,i)
       call pbc( r, lat )
       delr(:,i) = r(:)
    enddo

  end subroutine compute_delr_vec


end submodule compute_delr_r
