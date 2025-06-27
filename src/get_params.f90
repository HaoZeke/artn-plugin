submodule( artn_params )get_params
  use m_error
  use h_artn_units
  use m_artn_tools
  use h_artn_precision
  use, intrinsic :: iso_c_binding
  implicit none


  !!====================================
  !! functionality to extract the user-accessible variables from artn_params_mod.
  !! The user-accessible variables are the ones defined in
  !! artn_parameters namelist, plus push_init, eigenvec_init, and filin
  !!====================================

contains

  !! Getter routines for variables in artn_params, the generic routine name is `get_param` for all types

  !! fortran version

  !! integer
  module subroutine get_param_int( name, val, ierr )
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "verbose"          ); val = verbose
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

  !! real
  module subroutine get_param_real( name, val, ierr )
    !! return unconverted values
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    integer, intent(out) :: ierr
    real(DP) :: converted_val
    ierr = 0
    !! get the converted value
    select case( name )
    case( "push_dist_thr"           ); converted_val = push_dist_thr
    case( "forc_thr"                ); converted_val = forc_thr
    case( "eigval_thr"              ); converted_val = eigval_thr
    case( "delr_thr"                ); converted_val = delr_thr
    case( "lanczos_eval_conv_thr"   ); converted_val = lanczos_eval_conv_thr
    case( "push_step_size"          ); converted_val = push_step_size
    case( "push_step_size_per_atom" ); converted_val = push_step_size_per_atom
    case( "lanczos_disp"            ); converted_val = lanczos_disp
    case( "eigen_step_size"         ); converted_val = eigen_step_size
    case( "etot_diff_limit"         ); converted_val = etot_diff_limit
    case( "alpha_mix_cr"            ); converted_val = alpha_mix_cr
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_real(): "//name )
       call err_write(__FILE__,__LINE__)
       return
    end select
    !! unconvert
    val = unconvert_param( name, converted_val, ierr )
    if( ierr /= 0 ) then
       !! error when units are not set
       call err_write(__FILE__,__LINE__)
       return
    end if
  end subroutine get_param_real

  !! bool
  module subroutine get_param_bool( name, val, ierr )
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "lpush_final"           ); val = lpush_final
    case( "lrestart"              ); val = lrestart
    case( "lrelax"                ); val = lrelax
    case( "lmove_nextmin"         ); val = lmove_nextmin
    case( "lserialize_output"     ); val = lserialize_output
    case( "lanczos_at_min"        ); val = lanczos_at_min
    case( "lanczos_always_random" ); val = lanczos_always_random
    case( "lnperp_limitation"     ); val = lnperp_limitation
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_bool(): "//name )
    end select
  end subroutine get_param_bool

  !! string
  module subroutine get_param_str( name, val, ierr )
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "engine_units"      ); allocate( val, source = trim(engine_units) )
    case( "push_mode"         ); allocate( val, source = trim(push_mode) )
    case( "converge_property" ); allocate( val, source = trim(converge_property) )
    case( "push_guess"        ); allocate( val, source = trim(push_guess) )
    case( "eigenvec_guess"    ); allocate( val, source = trim(eigenvec_guess) )
    case( "filin"             ); allocate( val, source = trim(filin) )
    case( "filout"            ); allocate( val, source = trim(filout) )
    case( "initpfname"        ); allocate( val, source = trim(initpfname) )
    case( "eigenfname"        ); allocate( val, source = trim(eigenfname) )
    case( "restartfname"      ); allocate( val, source = trim(restartfname) )
    case( "struc_format_out"  ); allocate( val, source = trim(struc_format_out) )
    case( "prefix_min"        ); allocate( val, source = trim(prefix_min) )
    case( "prefix_sad"        ); allocate( val, source = trim(prefix_sad) )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_str(): "//name )
    end select
  end subroutine get_param_str

  !! integer 1D
  module subroutine get_param_int1d( name, val, ierr )
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: val(:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "push_ids"         ); allocate(val, source = push_ids )
    case( "nperp_limitation" ); allocate(val, source = nperp_limitation )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_int1d(): "//name )
    end select
  end subroutine get_param_int1d

  !! real 2D
  module subroutine get_param_real2d( name, val, ierr )
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:,:)
    integer, intent(out) :: ierr
    ierr = 0
    select case( name )
    case( "push_add_const" ); allocate( val, source = push_add_const )
    ! case( "push_init" ); allocate( val, source = push_init )
    ! case( "eigenvec_init" ); allocate( val, source = eigenvec_init )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in get_param_real2d(): "//name )
    end select
  end subroutine get_param_real2d




  module subroutine artn_list_extract_param()
    write(*,*) "List of parameters which can be extracted:"
    write(*,'(3x, "name                   :",3x,a8,3x,a4,3x,a)') "type", "rank", "size"
    write(*,*) repeat('=',80)
    write(*,'(3x, "alpha_mix_cr           :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "converge_property      :",3x,a8,3x,a4,3x,a)') "string", "0", "any"
    write(*,'(3x, "delr_thr               :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenfname             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigen_step_size        :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenvec_guess         :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigenvec_init          :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,nat); python [nat,3]"
    write(*,'(3x, "eigval_thr             :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "engine_units           :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "etot_diff_limit        :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "filout                 :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "filin                  :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "forc_thr               :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "initpfname             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "lanczos_always_random  :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lanczos_at_min         :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lanczos_disp           :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "lanczos_eval_conv_thr  :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "lanczos_max_size       :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "lanczos_min_size       :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "lmove_nextmin          :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lnperp_limitation      :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lpush_final            :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lrelax                 :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "lrestart               :",3x,a8,3x,a4,3x,a)') "logical", "0", "0"
    write(*,'(3x, "nevalf_max             :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "neigen                 :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "ninit                  :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nnewchance             :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nperp                  :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nperp_limitation       :",3x,a8,3x,a4,3x,a)') "integer", "1", "any"
    write(*,'(3x, "nrelax_print           :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "nsmooth                :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "push_add_const         :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (4,nat); python [nat,4]"
    write(*,'(3x, "push_dist_thr          :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_guess             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "push_ids               :",3x,a8,3x,a4,3x,a)') "integer", "1", ".le. natoms"
    write(*,'(3x, "push_init              :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,nat); python [nat,3]"
    write(*,'(3x, "push_mode              :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 5"
    write(*,'(3x, "push_over              :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_step_size         :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_step_size_per_atom:",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "prefix_sad             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "prefix_min             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "restart_freq           :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "restartfname           :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "struc_format_out       :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 10"
    write(*,'(3x, "verbose                :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
    write(*,'(3x, "zseed                  :",3x,a8,3x,a4,3x,a)') "integer", "0", "0"
  end subroutine artn_list_extract_param

end submodule get_params
