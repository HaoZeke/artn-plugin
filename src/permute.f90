submodule( m_tools )permutation_routines
  use m_artn_precision, only: DP
  implicit none
contains

  !> @details
  !! Permute a 1d array into order.
  !! "order" contains indices in fortran format (start at 1)
  module subroutine permute_int1d( dim1, array, order )
    implicit none
    integer, intent(in) :: dim1
    integer, intent(inout) :: array(dim1)
    integer, intent(in) :: order(dim1)
    array(:) = array( order(:) )
  end subroutine permute_int1d



  !> @details
  !! Inverse permute a 1d array into order.
  !! "order" contains indices in fortran format (start at 1)
  module subroutine unpermute_int1d( dim1, array, order)
    implicit none
    integer, intent(in) :: dim1
    integer, intent(inout) :: array(dim1)
    integer, intent(in) :: order(dim1)
    array( order(:) ) = array(:)
  end subroutine unpermute_int1d



  !> @details
  !! Permute a 2D array(3, dim1) into order, along the second axis (size dim1).
  !! The order should contain fortran-style indices (start at 1).
  module subroutine permute_real2d( dim1, array, order )
    implicit none
    integer, intent(in) :: dim1
    real(DP), intent(inout) :: array( 3, dim1 )
    integer, intent(in) :: order(dim1)
    array(:,:) = array(:, order )
  end subroutine permute_real2d




  !> @details
  !! Inverse permute 2D real array(3,dim1) along second axis.
  !! Order should contain fortran-style indices (start at 1)
  module subroutine unpermute_real2d( dim1, array, order )
    implicit none
    integer, intent(in) :: dim1
    real(DP), intent(inout) :: array( 3, dim1 )
    integer, intent(in) :: order(dim1)
    array(:, order) = array(:, :)
  end subroutine unpermute_real2d


end submodule permutation_routines

