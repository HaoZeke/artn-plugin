submodule( artn_params )set_params

  use m_error
  use units
  use precision
  !> @details
  !! Routines for setting and getting the variables which are accessible to the user
  !! from input file, stored in artn_params_mod.
  !!
  implicit none
contains

  !! fortran versions, generic name is `set_param`
  !! Allow overwriting values which already exist.
  !! Where needed, convert units to ARTn internal units immediately (requires that units are known).
  !! return ierr=0 onnormal execution, negative value when error

  !! integer
  module function set_param_int( name, val )result(ierr)
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer :: ierr
    ierr = 0
    ! block
    !   character(len=128) :: msg
    !   character(:), allocatable :: str
    !   integer :: ios
    !   allocate( str, source=write_nml_string("artn_parameters",name,val))
    !   read( str, nml=artn_parameters, iostat=ios, iomsg=msg )
    !   write(*,*) "str:",trim(str), ios
    !   if( ios /= 0 ) then
    !      write(*,*) "Error set_param_int",name,val
    !      write(*,*) "nml string:",trim(str)
    !      write(*,*) trim(msg)
    !      stop "here"//__FILE__
    !   end if

    ! end block

    select case( name )
    case( "verbose"          ); verbose          = val
    case( "ninit"            ); ninit            = val
    case( "neigen"           ); neigen           = val
    case( "nperp"            ); nperp            = val
    case( "lanczos_max_size" ); lanczos_max_size = val
    case( "lanczos_min_size" ); lanczos_min_size = val
    case( "nsmooth"          ); nsmooth          = val
    case( "nevalf_max"       ); nevalf_max       = val
    case( "zseed"            ); zseed            = val
    case( "nnewchance"       ); nnewchance       = val
    case( "nrelax_print"     ); nrelax_print     = val
    case( "restart_freq"     ); restart_freq     = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_int(): "//name )
    end select
  end function set_param_int

  !! real
  module function set_param_real( name, val )result(ierr)
    use units, only: convert_param
    character(*), intent(in) :: name
    real(DP), intent(in) :: val
    integer :: ierr
    real(DP) :: converted_val
    ierr = 0
    !! convert if needed
    converted_val = convert_param( name, val, ierr )
    if( ierr /= 0 ) then
       !! error happens when units are not set
       call err_write(__FILE__,__LINE__)
       return
    end if
    select case( name )
    case( "push_dist_thr"           ); push_dist_thr           = converted_val
    case( "forc_thr"                ); forc_thr                = converted_val
    case( "eigval_thr"              ); eigval_thr              = converted_val
    case( "delr_thr"                ); delr_thr                = converted_val
    case( "lanczos_eval_conv_thr"   ); lanczos_eval_conv_thr   = converted_val
    case( "push_step_size"          ); push_step_size          = converted_val
    case( "push_step_size_per_atom" ); push_step_size_per_atom = converted_val
    case( "lanczos_disp"            ); lanczos_disp            = converted_val
    case( "eigen_step_size"         ); eigen_step_size         = converted_val
    case( "etot_diff_limit"         ); etot_diff_limit         = converted_val
    case( "alpha_mix_cr"            ); alpha_mix_cr            = converted_val
    case( "push_over"               ); push_over               = converted_val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_real(): "//name )
    end select
  end function set_param_real

  !! bool
  module function set_param_bool( name, val )result(ierr)
    character(*), intent(in) :: name
    logical, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "lrestart"          ); lrestart          = val
    case( "lrelax"            ); lrelax            = val
    case( "lpush_final"       ); lpush_final       = val
    case( "lmove_nextmin"     ); lmove_nextmin     = val
    case( "lserialize_output" ); lserialize_output = val
    case( "lnperp_limitation" ); lnperp_limitation = val
    case( "lanczos_at_min"    ); lanczos_at_min    = val
    case( "lanczos_always_random" ); lanczos_always_random = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_bool(): "//name )
    end select
  end function set_param_bool

  !! string
  module function set_param_str( name, val )result(ierr)
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer :: ierr
    logical :: lerror
    ierr = 0
    select case( name )
    case("engine_units")
       engine_units=val
       ! write(*,*) "engine_units:",engine_units
       !! make the units immediately
       call make_units( engine_units, lerror )
       if( lerror ) then
          ierr = ERR_UNITS
          call err_caller(__FILE__,__LINE__)
          return
       end if
    case("push_mode"        ); push_mode         = val
    case("converge_property"); converge_property = val
    case("push_guess"       ); push_guess        = val
    case("eigenvec_guess"   ); eigenvec_guess    = val
    case("filout"           ); filout            = val
    case("initpfname"       ); initpfname        = val
    case("eigenfname"       ); eigenfname        = val
    case("restartfname"     ); restartfname      = val
    case("struc_format_out" ); struc_format_out  = val
    case("filin"            ); filin             = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_str(): "//name )
    end select
  end function set_param_str

  !! integer 1D
  module function set_param_int1d( name, dim, val )result(ierr)
    use m_option, only: nperp_limitation_init
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    integer, intent(in) :: val(dim)
    integer :: ierr
    ierr = 0
    select case( name )
    case( "push_ids" )
       if( allocated( push_ids)) deallocate( push_ids )
       allocate( push_ids, source=val )
    case( "nperp_limitation" )
       if( allocated( nperp_limitation))deallocate( nperp_limitation )
       allocate( nperp_limitation, source=val)
       call nperp_limitation_init(.true.)
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_int1d(): "//name )
    end select
  end function set_param_int1d

  !! real 2D
  module function set_param_real2d( name, dim1, dim2, val )result(ierr)
    !! the dimension cannot be checked here, since nat is unknown.
    character(*), intent(in) :: name
    integer, intent(in) :: dim1, dim2
    real(DP), intent(in) :: val(dim1, dim2)
    integer :: ierr
    ierr = 0
    select case( name )
    case( "push_add_const" )
       if( allocated(push_add_const))deallocate( push_add_const )
       allocate( push_add_const, source=val )
    case( "push_init", "push" )
       !! overwrite push_mode
       push_mode = "input"
       if( allocated(push))deallocate(push)
       allocate( push, source=val )
    case( "eigenvec_init", "eigenvec" )
       !! overwrite eigenvec_guess
       eigenvec_guess = "input"
       if( allocated(eigenvec))deallocate(eigenvec)
       allocate( eigenvec, source=val )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_param_real2d(): "//name )
    end select
  end function set_param_real2d





  module subroutine artn_list_set()
    write(*,*) "List of variables which can be set into the module artn_params:"
    write(*,'(3x, "name                   :",3x,a8,3x,a4,3x,a)') "type", "rank", "size"
    write(*,*) repeat('=',80)
    write(*,'(3x, "alpha_mix_cr           :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "converge_property      :",3x,a8,3x,a4,3x,a)') "string", "0", "any"
    write(*,'(3x, "current_step_size      :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "delr_thr               :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenfname             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigen_step_size        :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenvec_guess         :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigenvec               :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,natoms); python [natoms,3]"
    write(*,'(3x, "eigval_thr             :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "engine_units           :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 256"
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
    write(*,'(3x, "push_add_const         :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (4,natoms); python [natoms,4]"
    write(*,'(3x, "push_dist_thr          :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_guess             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "push_ids               :",3x,a8,3x,a4,3x,a)') "integer", "1", ".le. natoms"
    write(*,'(3x, "push                   :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,natoms); python [natoms,3]"
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
  end subroutine artn_list_set

end submodule set_params


