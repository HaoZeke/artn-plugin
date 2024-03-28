submodule( m_tools )random_routines
  use precision, only: DP
  implicit none
contains


  !......................................................
  !> @author
  !!   Matic Poberznik
  !!   Miha Gunde
  !!   Nicolas Salles

  !> @brief
  !!   provide a 3 random number \f$ \in [-0.5:0.5] \f$ with norm < 0.25
  !
  !! @param[inout] vec     output vector
  !
  !> @note
  !!   the random vector is inside a cercle of radius 0.5
  !!   because x, y, z \f$ \in [-.5:.5] \f$
  !
  module subroutine random_displacement( vec )
    !
    implicit none

    real(DP), intent(inout ) :: vec(3)

    real(DP) :: dr, randvec(3)
    real(DP), external :: dnrm2

    RDM:DO
       CALL RANDOM_NUMBER( randvec )
       vec(:) = (/ 0.5_DP - randvec(1), 0.5_DP - randvec(2), 0.5_DP - randvec(3) /)
       dr = dnrm2( 3, vec, 1 )
       IF ( dr < 0.25_DP ) RETURN
    ENDDO RDM

  end subroutine random_displacement


  !......................................................
  !> @author
  !!   Matic Poberznik
  !!   Miha Gunde
  !!   Nicolas Salles

  !> @brief
  !!   provide a random displacement to the atom's ID neighbors relative to the
  !!   threshold distance Rcut
  !
  !> @param[in]    nat     number of atom
  !> @param[in]    id      atom's Id
  !> @param[in]    rcut    distance threshold
  !> @param[out]   vec     output displacement
  !
  module subroutine neigh_random_displacement( nat, id, rcut, vec )
    !
    use units, only : unconvert_length
    use m_artn_data, only: lat, tau_step
    use artn_params, only: push_ids
    implicit none

    integer, intent( in ) :: id, nat
    real(DP), intent( in ) :: rcut
    real(DP), intent( out ) :: vec(3,nat)

    integer :: na
    real(DP) :: x0(3), dr(3), d, rc
    real(DP), external :: dnrm2

    !
    ! -- WARNING : The position and lattice are stil in engine units
    !       we unconvert the rcut which should be in
    !
    rc = unconvert_length( rcut )

    x0 = tau_step(:,id)
    DO na = 1,nat
       IF( id == na)cycle
       !IF( ANY(push_ids == na) )cycle
       dr(:) = tau_step(:,na) - x0(:)

       CALL pbc( dr, lat)
       d = dnrm2(3,dr,1)
       IF( d <= rc )THEN
          ! found an atom within dist_thr
          call random_displacement( vec(:,na))
          !print*, id, na, d, "neigh random disp:", vec(:,na)
       ENDIF
    ENDDO


  end subroutine neigh_random_displacement




  !..................................................
  !> @brief
  !!   make real(DP) random array normalized with a possibility to
  !!   give a bias to the randomness
  !
  !> @note NOT USED!
  !
  !> @param[in]      n     length of the arrays
  !> @param[inout]   v     array has to be random
  !> @param[in]      bias  specific direction use to orient the randomization (optional)
  !
  MODULE SUBROUTINE random_array( n, v, bias )
    implicit none

    integer, intent( in ) :: n
    real(DP), intent( out ) :: v(*)
    real(DP), intent( in ), optional :: bias(*)

    integer :: i
    REAL(DP) :: vnorm, vbias(n), rand
    ! real(DP), external :: dsum

    ! ...BIAS OPTION
    vbias = 1.0_DP
    if( present(bias) )then
      do i = 1,n
         vbias(i) = bias(i)
      enddo
    endif

    ! ...Random Vector
    DO i = 1, n
       !! Antoine update
       CALL RANDOM_NUMBER( rand )
       v( i ) = (0.5_DP - rand)*vbias( i )
    ENDDO

    ! normalize
    !vnorm = 1.0_DP / sqrt(dsum(n,v))
    vnorm = 1.0_DP / norm2(v(1:n))
    DO i = 1,n
       v(i) = v(i) * vnorm
    ENDDO

  END SUBROUTINE random_array


end submodule random_routines
