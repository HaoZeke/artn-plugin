submodule( artn_params ) get_runparam_routines
  use precision
  use m_error
  implicit none

contains

  !! Getter routines for variables in artn_params, labelled as run_params
  !! The generic routine name is `get_runparam`

  !! the runparams have good value only during the run, not before or after clean()

  !! integer
  module subroutine get_runparam_int( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "VOID" ); val = VOID
    case( "INIT" ); val = INIT
    case( "PERP" ); val = PERP
    case( "EIGN" ); val = EIGN
    case( "LANC" ); val = LANC
    case( "RELX" ); val = RELX
    case( "OVER" ); val = OVER
    case( "SMTH" ); val = SMTH
    case( "iartn"      ); val = iartn
    case( "istep"      ); val = istep
    case( "iinit"      ); val = iinit
    case( "iperp"      ); val = iperp
    case( "ieigen"     ); val = ieigen
    case( "irelax"     ); val = irelax
    case( "iover"      ); val = iover
    case( "inewchance" ); val = inewchance
    case( "ismooth"    ); val = ismooth
    case( "nlanc"      ); val = nlanc
    case( "ifound"     ); val = ifound
    case( "isearch"    ); val = isearch
    case( "ifails"     ); val = ifails
    case( "nperp_step" ); val = nperp_step
    case( "nmin"       ); val = nmin
    case( "nsaddle"    ); val = nsaddle
    case( "fpush_factor" ); val = fpush_factor
    case( "called_from"  ); val = called_from
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_int(): "//name )
       val = NAN_INT
    end select
  end subroutine get_runparam_int

  !! real
  module subroutine get_runparam_real( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_real(): "//name )
       val = NAN_REAL
    end select
  end subroutine get_runparam_real

  !! bool
  module subroutine get_runparam_bool( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "linit"            ); val = linit
    case( "lperp"            ); val = lperp
    case( "leigen"           ); val = leigen
    case( "llanczos"         ); val = llanczos
    case( "lbasin"           ); val = lbasin
    case( "lpush_over"       ); val = lpush_over
    case( "lrelax"           ); val = lrelax
    case( "in_lanczos_at_min"); val = in_lanczos_at_min
    case( "lbackward"        ); val = lbackward
    case( "lend"             ); val = lend
    case( "luser_choose_per_atom" ); val = luser_choose_per_atom
    case( "lserialize_input"  ); val = lserialize_input
    case( "lserialize_output" ); val = lserialize_output
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_bool(): "//name )
    end select
  end subroutine get_runparam_bool

  !! string
  module subroutine get_runparam_str( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "error_message" ); allocate( val, source=trim(error_message) )
    case( "errmsg" ); allocate( val, source=errmsg )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_str(): "//name )
    end select
  end subroutine get_runparam_str

  !! real 1D -- even if there are no real 1D variables, at least the routine
  !! is there to return error if called somehow.
  module subroutine get_runparam_real1d( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_real1d(): "//name )
       allocate( val(0) )
    end select
  end subroutine get_runparam_real1d

  !! real 2D
  module subroutine get_runparam_real2d( name, val, ierr )
    implicit none
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:,:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "push"                ); allocate( val, source=push )
    case( "eigenvec"            ); allocate( val, source=eigenvec )
    case( "push_initial_vector" ); allocate( val, source=push_initial_vector )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_runparam_real2d(): "//name )
    end select
  end subroutine get_runparam_real2d


end submodule get_runparam_routines
