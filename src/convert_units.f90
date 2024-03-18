submodule( units ) convert_units
  implicit none
contains



  !......................................................................................
  ! FORCE

  !> @brief Convert the engine force to a.u.
  !> @param[in] f   force in engine unit
  !> @return a force in atomic units a.u.
  module elemental pure function convert_force( f )result( fau )
    real(DP), intent( in ) :: f
    real(DP) :: fau
    fau = f * F2au
  end function convert_force

  !> @brief Convert the force in a.u. in engine units
  !> @param [in] fau   force in a.u.
  !> @return a force in engine units
  module elemental pure function unconvert_force( fau )result( f )
    real(DP), intent( in ) :: fau
    real(DP) :: f
    f = fau * au2F
  end function unconvert_force



  !......................................................................................
  ! HESSIAN

  !> @brief Convert the engine hessian to a.u.
  !> @param [in] h   hessian in engine unit
  !> @return a hessain in atomic units a.u.
  module elemental pure function convert_hessian( h )result( hau )
    real(DP), intent( in ) :: h
    real(DP) :: hau
    hau = h * H2au
  end function convert_hessian

  !> @brief Convert the force in a.u. in engine units
  !> @param [in] hau   force in a.u.
  !> @return a force in engine units
  module elemental pure function unconvert_hessian( hau )result( h )
    real(DP), intent( in ) :: hau
    real(DP) :: h
    h = hau * au2H
  end function unconvert_hessian



  !......................................................................................
  ! LENGTH

    !> @brief Convert the engine length to a.u.
    !> @param [in] p   position in engine unit
    !> @return a position in a.u.
  module elemental pure function convert_length( p )result( pau )
    real(DP), intent( in ) :: p
    real(DP) :: pau
    pau = p * L2au
  end function convert_length

  !> @brief Convert the a.u. length to engine unit
  !> @param [in] pau   position in a.u.
  !> @return  position in engine units
  module elemental pure function unconvert_length( pau )result( p )
    real(DP), intent( in ) :: pau
    real(DP) :: p
    p = pau * au2L
  end function unconvert_length



  !......................................................................................
  ! ENERGY

  !> @brief Convert the engine energy to a.u.
  !> @param [in] e   enegy in engine unit
  !> @return an energy in a.u.
  module elemental pure function convert_energy( e )result( eau )
    real(DP), intent( in ) :: e
    real(DP) :: eau
    eau = e * E2au
  end function convert_energy

  !> @brief Convert the a.u. energy to engine unit
  !> @param [in] eau   energy in a.u.
  !> @return an energy in engine units
  module elemental pure function unconvert_energy( eau )result( e )
    real(DP), intent( in ) :: eau
    real(DP) :: e
    e = eau * au2E
  end function unconvert_energy



  !......................................................................................
  ! TIME

    !> @brief Convert the engine time to a.u.
    !> @param [in] t   time in engine unit
    !> @return a time in a.u.
  module elemental pure function convert_time( t )result( aut )
    real(DP), intent( in ) :: t
    real(DP) :: aut
    aut = t * T2au
  end function convert_time

    !> @brief Convert the a.u. TIME to engine unit
    !> @param [in] aut   time in a.u.
    !> @return a time in engine units
  module elemental pure function unconvert_time( aut )result( t )
    real(DP), intent( in ) :: aut
    real(DP) :: t
    t = aut * au2T
  end function unconvert_time


  !......................................................................................
  ! Return UNIT
  !> @brief Return the unit in character of the quantity received
  !> @param[in] quantity   (length, energy, force or hessian)
  !> @return correct unit in character
  module function unit_char( quantity )result( uchar )
    character(*), intent(in) :: quantity
    character(:), allocatable :: uchar

    select case( quantity )
      case( 'length' );  uchar = cL
      case( 'energy' );  uchar = cE
      case( 'force' );   uchar = cE//'/'//cL
      case( 'hessian' ); uchar = cE//'/'//cL//to2
    end select

  end function



end submodule convert_units
