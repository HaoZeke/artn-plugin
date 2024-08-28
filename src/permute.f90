submodule( m_tools )permutation_routines
  use precision, only: DP
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
  !! Wrapper for permute_int1d, corder should contain fortran-style indices (start at 1)
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void permute_int1d( const int dim1, int *const array, const int* order );
  !!~~~~~~~~~~~~~~~~~~~~~~
  subroutine permute_int1d_c( cdim1, carray, corder )bind(C, name="permute_int1d")
    use, intrinsic :: iso_c_binding, only: c_int
    implicit none
    integer( c_int ), value, intent(in) :: cdim1
    integer(c_int), intent(inout) :: carray(cdim1)
    integer(c_int), intent(in) :: corder(cdim1)
    integer :: array(cdim1), order(cdim1)
    array = int(carray); order = int(corder)
    call permute_int1d( int(cdim1), array, order )
    carray = int(array, c_int)
  end subroutine permute_int1d_c



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
  !! Wrapper for unpermute_int1d, corder shoudl contain fortran-style indices (start at 1)
  !!~~~~~~~~~~~~~~~{.c}
  !! void unpermute_int1d( const int dim1, int *const array, const int* order );
  !!~~~~~~~~~~~~~~~
  subroutine unpermute_int1d_c( cdim1, carray, corder )bind(C, name="unpermute_int1d")
    use, intrinsic :: iso_c_binding, only: c_int
    implicit none
    integer( c_int ), value, intent(in) :: cdim1
    integer(c_int), intent(inout) :: carray(cdim1)
    integer(c_int), intent(in) :: corder(cdim1)
    integer :: array(cdim1), order(cdim1)
    array = int(carray); order = int(corder)
    call unpermute_int1d( int(cdim1), array, order )
    carray = int(array, c_int)
  end subroutine unpermute_int1d_c




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
  !! Wrapper for permute_real2d, corder should contain fortran-style indices (start at 1)
  !!~~~~~~~~~~~~~~~~~~~{.c}
  !! void permute_real2d( const int dim1, double * const array, const int * order );
  !!~~~~~~~~~~~~~~~~~~~
  subroutine permute_real2d_c( cdim1, carray, corder )bind(C,name="permute_real2d")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    integer( c_int ), value, intent(in) :: cdim1
    real( c_double ), intent(inout) :: carray(3, cdim1)
    integer( c_int ), intent(in) :: corder(cdim1)
    real(DP), dimension(3,cdim1) :: array
    integer, dimension(cdim1) :: order
    array = real( carray, DP ); order = int( corder )
    call permute_real2d( int(cdim1), array, order )
    carray = real( array, c_double )
  end subroutine permute_real2d_c



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

  !> @details
  !! Wrapper for unpermute_real2d, corder should contain fortran-style indices (start at 1)
  !!~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void unpermute_real2d( const int dim1, double * const array, const int * order );
  !!~~~~~~~~~~~~~~~~~~~~~~~~
  subroutine unpermute_real2d_c( cdim1, carray, corder )bind(C,name="unpermute_real2d")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    integer( c_int ), value, intent(in) :: cdim1
    real( c_double ), intent(inout) :: carray(3, cdim1)
    integer( c_int ), intent(in) :: corder(cdim1)
    real(DP), dimension(3,cdim1) :: array
    integer, dimension(cdim1) :: order
    array = real( carray, DP ); order = int( corder )
    call unpermute_real2d( int(cdim1), array, order )
    carray = real( array, c_double )
  end subroutine unpermute_real2d_c


end submodule permutation_routines

