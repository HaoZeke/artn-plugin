submodule( m_artn_option ) nextmin
  use h_artn_precision, only: DP
  implicit none
contains

  !> @brief
  !!   Load the structure corresponding to min furthest from initial configuration,
  !!   into the engine arrays.
  !> @note
  !!   Called in LCONV block in artn()
  !!
  !! @param[in] nat :: number of atoms
  !! @param[out] typ :: atomic types
  !! @param[out] pos :: atomic positions
  !! @param[in] order :: atomic indices
  module subroutine move_nextmin( nat, typ, pos, order )
  !subroutine move_nextmin( nat, typ, pos, order )
    !use h_artn_precision, only: DP
    use d_artn_params, only: lpush_final
    use d_artn_data, only: delr_min1, delr_min2
    use d_artn_data, only: typ_min1, tau_min1
    use d_artn_data, only: typ_min2, tau_min2
    implicit none
    integer, intent(in) :: nat
    integer, intent(out) :: typ(nat)
    real(DP), intent(out) :: pos(3, nat)
    integer, intent(in) :: order(nat)

    !! if there is no final push, this routine is useless
    if( .not. lpush_final ) return

    !! load structure of min which has higher delr
    ! write(*,*) "in nextmin",delr_min1, delr_min2
    if( delr_min1 > delr_min2 ) then
       write(*,*) "load min1"
       !! load min1
       typ(:) = typ_min1( order(:) )
       pos(:,:) = tau_min1(:, order(:) )
    else
       write(*,*) "load min2"
       !! load min2
       typ(:) = typ_min2( order(:) )
       pos(:,:) = tau_min2(:, order(:) )
    end if

  end subroutine move_nextmin


end submodule nextmin
