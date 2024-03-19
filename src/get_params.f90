submodule( artn_params )get_params
  use m_error
  use units
  !! routines to extract the user-accessible variables from artn_params_mod
  implicit none
contains


  !! helper functions
  module function get_param_dtype( name )result( dtype )
    !! return value of expected data type of variable <name>, even if variable is not set
    character(*), intent(in) :: name
    integer :: dtype
  end function get_param_dtype

  module function get_param_drank( name )result( drank )
    !! return value of expected rank of variable <name>, even if variable is not set
    character(*), intent(in) :: name
    integer :: drank
  end function get_param_drank

  module subroutine get_param_dsize( name, drank, dsize, ierr )
    !! return actual size of variable <name>, if varibale not allocated return negative ierr
    character(*), intent(in) :: name
    integer, intent(in) :: drank
    integer, dimension(drank), intent(out) :: dsize
    integer, intent(out) :: ierr
  end subroutine get_param_dsize


  !! fortran version
  module subroutine get_param_int( name, val, ierr )
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "ninit"            ); val = ninit
    case( "neigen"           ); val = neigen
    case( "nperp"            ); val = nperp
    case( "lanczos_max_size" ); val = lanczos_max_size
    case( "lanczos_min_size" ); val = lanczos_min_size
    case( "nsmooth"          ); val = nsmooth
    case( "nevalf_max"       ); val = nevalf_max
    case( "zseed"            ); val = zseed
    case( "nnewchance"       ); val = nnewchance
    case( "nrelax_print"     ); val = nrelax_print
    case( "restart_freq"     ); val = restart_freq
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_int(): "//name )
    end select
  end subroutine get_param_int
  module subroutine get_param_real( name, val, ierr )
    !! return unconverted values
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer, intent(out) :: ierr
    real(DP) :: unconverted_val
    ierr = 0
    !! get the unconverted value
    select case( name )
    case( "push_dist_thr"           ); unconverted_val = push_dist_thr
    case( "forc_thr"                ); unconverted_val = forc_thr
    case( "eigval_thr"              ); unconverted_val = eigval_thr
    case( "delr_thr"                ); unconverted_val = delr_thr
    case( "lanczos_eval_conv_thr"   ); unconverted_val = lanczos_eval_conv_thr
    case( "push_step_size"          ); unconverted_val = push_step_size
    case( "push_step_size_per_atom" ); unconverted_val = push_step_size_per_atom
    case( "lanczos_disp"            ); unconverted_val = lanczos_disp
    case( "eigen_step_size"         ); unconverted_val = eigen_step_size
    case( "etot_diff_limit"         ); unconverted_val = etot_diff_limit
    case( "alpha_mix_cr"            ); unconverted_val = alpha_mix_cr
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_real(): "//name )
       call err_write(__FILE__,__LINE__)
       return
    end select
    !! unconvert
    val = unconvert_param( name, unconverted_val, ierr )
    if( ierr /= 0 ) then
       call err_write(__FILE__,__LINE__)
       return
    end if
  end subroutine get_param_real
  module subroutine get_param_bool( name, val, ierr )
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_bool(): "//name )
    end select
  end subroutine get_param_bool
  module subroutine get_param_str( name, val, ierr )
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_str(): "//name )
    end select
  end subroutine get_param_str

end submodule get_params
