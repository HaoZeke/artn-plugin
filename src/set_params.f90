submodule( artn_params )set_params

  use m_error
  use units
  !> @details
  !! Routines for setting and getting the variables which are accessible to the user
  !! from input file, and stored in artn_params_mod.
  !!
  implicit none
contains

  !! fortran versions
  !! Allow overwriting values which already exist.
  !! Where needed, convert units to ARTn internal units immediately (requires that units are known).
  !! return ierr=0 onnormal execution, negative value when error
  module function set_param_int( name, val )result(ierr)
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "ninit"            ); ninit = val
    case( "neigen"           ); neigen = val
    case( "nperp"            ); nperp = val
    case( "lanczos_max_size" ); lanczos_max_size = val
    case( "lanczos_min_size" ); lanczos_min_size = val
    case( "nsmooth"          ); nsmooth = val
    case( "nevalf_max"       ); nevalf_max = val
    case( "zseed"            ); zseed = val
    case( "nnewchance"       ); nnewchance = val
    case( "nrelax_print"     ); nrelax_print = val
    case( "restart_freq"     ); restart_freq = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_int(): "//name )
    end select
  end function set_param_int
  module function set_param_real( name, val )result(ierr)
    character(*), intent(in) :: name
    real(DP), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "push_dist_thr"           ); push_dist_thr = val
    case( "forc_thr"                ); forc_thr = convert_force( val )
    case( "eigval_thr"              ); eigval_thr = convert_hessian( val )
    case( "delr_thr"                ); delr_thr = val
    case( "lanczos_eval_conv_thr"   ); lanczos_eval_conv_thr = val
    case( "push_step_size"          ); push_step_size = convert_length( val )
    case( "push_step_size_per_atom" ); push_step_size_per_atom = convert_length( val )
    case( "lanczos_disp"            ); lanczos_disp = convert_length( val )
    case( "eigen_step_size"         ); eigen_step_size = convert_length( val )
    case( "etot_diff_limit"         ); etot_diff_limit = convert_energy( val )
    case( "alpha_mix_cr"            ); alpha_mix_cr = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_real(): "//name )
    end select
  end function set_param_real
  module function set_param_bool( name, val )result(ierr)
    character(*), intent(in) :: name
    logical, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "lrestart"          ); lrestart = val
    case( "lrelax"            ); lrelax = val
    case( "lpush_final"       ); lpush_final = val
    case( "lmove_nextmin"     ); lmove_nextmin = val
    case( "lserialize_output" ); lserialize_output = val
    case( "lnperp_limitation" ); lnperp_limitation = val
    case( "lanczos_at_min"    ); lanczos_at_min = val
    case( "lanczos_always_random" ); lanczos_always_random = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_bool(): "//name )
    end select
  end function set_param_bool
  module function set_param_str( name, val )result(ierr)
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case("engine_units")
       engine_units=val
       !! make the units immediately
       call make_units( engine_units )
    case("push_mode"        ); push_mode=val
    case("converge_property"); converge_property=val
    case("push_guess"       ); push_guess=val
    case("eigenvec_guess"   ); eigenvec_guess=val
    case("filout"           ); filout=val
    case("initpfname"       ); initpfname=val
    case("eigenfname"       ); eigenfname=val
    case("restartfname"     ); restartfname=val
    case("struc_format_out" ); struc_format_out=val
    case("filin"            ); filin=val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_str(): "//name )
    end select
  end function set_param_str


  !! c version
  module function set_cparam_int( cname, cval )result(cerr)bind(C)
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_string
    type( c_ptr ), value :: cname
    integer( c_int ), intent(in) :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    integer :: fval
    allocate( fname, source=c2f_string(cname))
    fval = int( cval )
    cerr = int( set_param_int(fname, fval), c_int)
    deallocate( fname )
  end function set_cparam_int
  module function set_cparam_real( cname, cval )result(cerr)bind(C)
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_string
    type( c_ptr ), value :: cname
    real( c_double ), intent(in) :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    real(DP) :: fval
    allocate( fname, source=c2f_string(cname))
    fval = real( cval, DP )
    cerr = int( set_param_real(fname, fval), c_int)
    deallocate( fname )
  end function set_cparam_real
  module function set_cparam_bool( cname, cval )result(cerr)bind(C)
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_string
    type( c_ptr ), value :: cname
    logical( c_bool ), intent(in) :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    logical :: fval
    allocate( fname, source=c2f_string(cname))
    fval = logical( cval )
    cerr = int( set_param_bool(fname, fval), c_int)
    deallocate( fname )
  end function set_cparam_bool
  module function set_cparam_str( cname, cval )result(cerr)bind(C)
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_string
    type( c_ptr ), value :: cname
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname, fval
    allocate( fname, source=c2f_string(cname) )
    allocate( fval, source=c2f_string(cval) )
    cerr = int( set_param_str( fname, fval), c_int)
    deallocate( fname, fval )
  end function set_cparam_str



end submodule set_params


