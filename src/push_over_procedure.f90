submodule( m_tools )push_over_routine
  use precision, only: DP
  implicit none
contains

  !> @brief
  !!    Perform the push over the saddle point
  !
  !> @param[inout] iover         iterator of push_over
  !> @param[in]    nat           number of atoms
  !> @param[out]   pos           atomic position
  !> @param[in]    v0            Vector defining the push over
  !> @param[in]    push_factor   +/- 1 depending the sens of the push
  !> @param[out]   order         atoms engine order
  !> @param[out]   displ_vec     displacement vector
  !> @param[out]   lstop         flag to stop the computation
  !
  MODULE SUBROUTINE Push_Over_Procedure( iover, nat, pos, v0, push_factor, order, displ_vec, lstop )
    !
    use precision, only : DP
    use artn_params, only : eigen_step_size, push_over, tau_saddle
    use m_error
    implicit none

    integer, intent(inout) :: iover
    integer, intent(in)    :: nat, order(nat)
    integer, intent(in)   :: push_factor
    real(DP), intent(in)   :: v0(3,nat)
    real(DP), intent(out)  :: pos(3,nat), displ_vec(3,nat)
    logical, intent(out) :: lstop !! unused?

    real(DP) :: coeff

    lstop = .false.

    iover = iover + 1
    IF( iover > 1 )THEN
       pos(:,:) = tau_saddle(:,order(:))  ! no conversion needed

       !! this IF should never be entered, if yes, is a bug.
       call merr(__FILE__, __LINE__, kill=.true.)
    ENDIF
    ! Decrease the push_over factor from 0.8^(iover-1)
    coeff = push_over * 0.8**(iover-1)
    displ_vec(:,:) = real(push_factor, DP) * v0(:,:) * eigen_step_size * coeff

  END SUBROUTINE Push_Over_Procedure

end submodule push_over_routine
