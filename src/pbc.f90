submodule(m_artn_tools)pbc_routines
  implicit none

contains

  !> @author
  !!  Matic Poberznik
  !!  Miha Gunde
  !!  Nicolas Salles

  !> @brief
  !!   A function that takes into account periodic boundary conditions,
  !!   based on the pbc function of the contraints_module of QE
  !!
  !> @param [inout] vec   input vector in atomic units
  !> @param [in]    at    lattice vectors in columns, at(:,1)=a, at(:,2)=b, at(:,3)=c
  !> @param [in]    bg    inverse lattice
  !
  module SUBROUTINE pbc( vec, at, bg )
    IMPLICIT none
    ! -- ARGUMENTS
    REAL(DP), INTENT(INOUT) :: vec(3) !> input vector in atomic units
    REAL(DP), INTENT(IN) :: at(3,3)   !> lattice vectors in columns
    REAL(DP), INTENT(IN) :: bg(3,3) !> inverse of at(3,3)
    ! -- LOCAL VARIABLES
    integer :: i
    !
    ! convert to crystal coords
    vec(:) = matmul(bg(:,:),vec(:))

    ! move the vector to [-0.5 : 0.5]
    do i = 1, 3
       if( vec(i) .gt. 0.5_dp ) vec(i) = vec(i) - 1.0_dp
       if( vec(i) .le. -0.5_dp) vec(i) = vec(i) + 1.0_dp
    end do

    ! convert back to cartesian coordinates
    vec(:) = matmul(at(:,:), vec(:))
    !
  END SUBROUTINE pbc


  !> @author
  !!  Matic Poberznik
  !!  Miha Gunde
  !!  Nicolas Salles

  !> @brief
  !!   A function that takes into account periodic boundary conditions,
  !!   based on the pbc function of the contraints_module of QE
  !
  function fpbc( vec, at )RESULT( res )
    IMPLICIT none

    REAL(DP), INTENT(IN)  :: vec(3) ! input vector in atomic units
    REAL(DP), INTENT(IN)  :: at(3,3)   ! lattice vectors
    REAL(DP)              :: res(3)   ! lattice vectors

    REAL(DP)                :: bg(3,3) ! inverse of at(3,3)
    !
    ! calculate the reciprocal lattice parameters of at
    !
    CALL invmat3x3(at,bg)
    !
    ! convert to crystal coords: U = R.B^-1
    res(:) = matmul(vec(:),bg(:,:))
    ! move the vector to original box
    res(:) = res(:) - anint(res(:))
    ! convert back to cartesian coordinates: R = B.U ???
    res(:) = matmul(at(:,:), res(:))
    !
  END function fpbc



  !> @author
  !!  Matic Poberznik
  !!  Miha Gunde
  !!  Nicolas Salles

  !> @brief
  !!   Subroutine that calculates the inverse of a 3x3 matrix
  !!
  !> @param [in]  mat   Matrix to inverse
  !> @param [out] inv   Inverse of the Matrix
  !
  MODULE SUBROUTINE invmat3x3(mat,inv)
    IMPLICIT none

    REAL(DP), INTENT(IN) :: mat(3,3)
    REAL(DP), INTENT(OUT) :: inv(3,3)
    !
    REAL(DP) :: det, invdet
    !
    det = 0.0_DP
    !
    ! calculate the determinant ...
    !
    det = det + mat(1,1)*mat(2,2)*mat(3,3) &
         + mat(1,2)*mat(2,3)*mat(3,1) &
         + mat(1,3)*mat(2,1)*mat(3,2) &
         - mat(1,3)*mat(2,2)*mat(3,1) &
         - mat(1,2)*mat(2,1)*mat(3,3) &
         - mat(1,1)*mat(2,3)*mat(3,2)
    ! invert the determinant
    invdet = 1/det
    ! calculate the inverse matrix
    inv(1,1) = invdet  * ( mat(2,2)*mat(3,3) - mat(2,3)*mat(3,2) )
    inv(2,1) = -invdet * ( mat(2,1)*mat(3,3) - mat(2,3)*mat(3,1) )
    inv(3,1) = invdet  * ( mat(2,1)*mat(3,2) - mat(2,2)*mat(3,1) )
    inv(1,2) = -invdet * ( mat(1,2)*mat(3,3) - mat(1,3)*mat(3,2) )
    inv(2,2) = invdet  * ( mat(1,1)*mat(3,3) - mat(1,3)*mat(3,1) )
    inv(3,2) = -invdet * ( mat(1,1)*mat(3,2) - mat(1,2)*mat(3,1) )
    inv(1,3) = invdet  * ( mat(1,2)*mat(2,3) - mat(1,3)*mat(2,2) )
    inv(2,3) = -invdet * ( mat(1,1)*mat(2,3) - mat(1,3)*mat(2,1) )
    inv(3,3) = invdet  * ( mat(1,1)*mat(2,2) - mat(1,2)*mat(2,1) )
    !
  END SUBROUTINE invmat3x3



end submodule pbc_routines
