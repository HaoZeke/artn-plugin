submodule( m_tools )random_routines
  use precision, only: DP
  implicit none
contains


  !> @details
  !! initialize random number generator, modified from:
  !! https://gcc.gnu.org/onlinedocs/gcc-4.9.1/gfortran/RANDOM_005fSEED.html
  !!
  !! Seed the random number generator with sequence generated from zseed.
  !! If on input `zseed = 0` then a new, repeatable seed sequence is generated.
  !! On output, `zseed` has value of actual seed used (single value), which can be
  !! used to reproduce the actual sequence of seed elements.
  module subroutine initialize_random_seed( zseed )
    use iso_fortran_env, only: int64
    implicit none
    integer, intent(inout) :: zseed

    integer, allocatable :: seed(:)
    integer :: i, n
    integer(int64) :: t

    if( zseed == 0 ) then
       !! generate seed from system clock
       call system_clock(t)
       t = mod( t, int(huge(0), int64) )
       zseed = int( t )
    end if

    !! get size
    call random_seed(size = n)
    allocate(seed(n))

    !! put first element of seed
    seed(1) = lcg( int(zseed, int64) )
    do i = 2, n
       !! other elements of seed are function of preceding seed element
       seed(i) = lcg( int(seed(i-1), int64) )
    end do

    call random_seed(put=seed)
  contains
    ! This simple PRNG might not be good enough for real work, but is
    ! sufficient for seeding a better PRNG.
    function lcg(s)
      integer :: lcg
      integer(int64) :: s
      if (s == 0) then
         s = 104729
      else
         s = mod(s, 4294967296_int64)
      end if
      s = mod(s * 279470273_int64, 4294967291_int64)
      lcg = int(mod(s, int(huge(0), int64)), kind(0))
    end function lcg
  end subroutine initialize_random_seed


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
    real(DP) :: x0(3), dr(3), d, rc, invlat(3,3)

    !
    ! -- WARNING : The position and lattice are stil in engine units
    !       we unconvert the rcut which should be in
    !
    rc = unconvert_length( rcut )

    x0 = tau_step(:,id)
    call inverse3x3(lat, invlat)
    DO na = 1,nat
       IF( id == na)cycle
       !IF( ANY(push_ids == na) )cycle
       dr(:) = tau_step(:,na) - x0(:)

       CALL pbc( dr, lat, invlat )
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
