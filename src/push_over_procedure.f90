submodule( m_artn )push_over_routine
  use h_artn_precision, only: DP
  implicit none
contains

  !> @brief
  !!    Perform the push over the saddle point
  !
  !> @param[in]    nat           number of atoms
  !> @param[in]    v0            Vector defining the push over
  !> @param[in]    push_factor   +/- 1 depending the sens of the push
  !> @param[out]   displ_vec     displacement vector
  !> @param[out]   lstop         flag to stop the computation
  !
  MODULE SUBROUTINE Push_Over_Procedure( nat, v0, push_factor, displ_vec )
    !
    use h_artn_precision, only : DP
    use d_artn_params, only : eigen_step_size, push_over
    use m_error
    implicit none

    integer, intent(in)    :: nat
    integer, intent(in)   :: push_factor
    real(DP), intent(in)   :: v0(3,nat)
    real(DP), intent(out)  :: displ_vec(3,nat)

    !! push_over is user-input value
    !! push_factor is integer +/- 1
    !! eigen_step_size is user-input value
    !! v0 is eigenvector
    displ_vec(:,:) = real(push_factor, DP) * v0(:,:) * eigen_step_size * push_over * 0.8_DP

  END SUBROUTINE Push_Over_Procedure

end submodule push_over_routine
