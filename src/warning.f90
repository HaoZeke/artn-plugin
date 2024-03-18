submodule( artn_params )warning_r
  implicit none


contains


  !
  !---------------------------------------------------------------------------
  !> @brief
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !
  module SUBROUTINE warning_nothing( u0, STEP, text )
    integer, intent( in ) :: u0
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    1 format(*(A))

  END SUBROUTINE warning_nothing

  !> @brief
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !> @param[in]   intv   vector of integer
  !
  module SUBROUTINE warning_int( u0, STEP, text, intv )
    !
    integer, intent( in ) :: u0, intv(:)
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    WRITE( u0,2 ) "* => ", intv
    1 format(*(A))
    2 format(A,*(1x,i0))

  END SUBROUTINE warning_int


  !> @brief
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !> @param[in]   realv   vector of real
  !
  module SUBROUTINE warning_real( u0, STEP, text, realv )
    integer, intent( in ) :: u0
    REAL(DP), intent( in ) :: realv(:)
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    WRITE( u0,2 ) "* => ", realv
    1 format(*(A))
    2 format(A,*(1x,f12.6))

  END SUBROUTINE warning_real


  !> @brief
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !> @param[in]   charv   vector of character
  !
  module SUBROUTINE warning_char( u0, STEP, text, charv )
    integer, intent( in ) :: u0
    character(*), intent( in ) :: charv(:)
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    WRITE( u0,1 ) "* => ", charv
    1 format(*(A))

  END SUBROUTINE warning_char


end submodule warning_r
