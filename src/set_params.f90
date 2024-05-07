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

  !! fortran versions
  !! Allow overwriting values which already exist.
  !! Where needed, convert units to ARTn internal units immediately (requires that units are known).
  !! return ierr=0 onnormal execution, negative value when error
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
          call err_set( ierr, __FILE__, __LINE__,msg="make_units fails!")
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





  !! c wrappers to the above routines:

  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_param_int( const char *name, const int cval );
  !!~~~~~~~~~~~~~~~~~~~~
  module function set_cparam_int( cname, cval )result(cerr)bind(C, name="set_param_int")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    integer :: fval
    allocate( fname, source=c2f_char(cname))
    fval = int( cval )
    cerr = int( set_param_int(fname, fval), c_int)
    deallocate( fname )
  end function set_cparam_int

  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_param_real( const char *name, const double cval );
  !!~~~~~~~~~~~~~~~~~~~~
  module function set_cparam_real( cname, cval )result(cerr)bind(C, name="set_param_real")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    real( c_double ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    real(DP) :: fval
    allocate( fname, source=c2f_char(cname))
    fval = real( cval, DP )
    cerr = int( set_param_real(fname, fval), c_int)
    deallocate( fname )
  end function set_cparam_real

  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_param_bool( const char *name, const bool cval );
  !!~~~~~~~~~~~~~~~~~~~~
  module function set_cparam_bool( cname, cval )result(cerr)bind(C, name="set_param_bool")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    logical( c_bool ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    logical :: fval
    allocate( fname, source=c2f_char(cname))
    fval = logical( cval )
    cerr = int( set_param_bool(fname, fval), c_int)
    deallocate( fname )
  end function set_cparam_bool

  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_param_str( const char *name, const char cval );
  !!~~~~~~~~~~~~~~~~~~~~
  module function set_cparam_str( cname, cval )result(cerr)bind(C, name="set_param_str")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    character(len=1, kind=c_char), intent(in) :: cval(*)
    integer( c_int ) :: cerr
    character(:), allocatable :: fname, fval
    allocate( fname, source=c2f_char(cname) )
    allocate( fval, source=c2f_char(cval) )
    cerr = int( set_param_str( fname, fval), c_int)
    deallocate( fname, fval )
  end function set_cparam_str


  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.c}
  !! int set_param( const char * const name, const int crank, const int* csize, const void *cval );
  !!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function set_cparam( cname, crank, csize, cval ) result(cerr)bind(C,name="set_param")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char, c2f_string
    use m_datainfo
    implicit none
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer( c_int ), value :: crank
    integer( c_int ), dimension(crank) :: csize
    type( c_ptr ), value :: cval
    integer( c_int ) :: cerr
    character(:), allocatable :: fname
    ! integer( c_int ), pointer :: dsize(:)
    real( c_double ), pointer :: rptr, r2ptr(:,:)
    integer( c_int ), pointer :: iptr, i1ptr(:)
    logical( c_bool ), pointer :: bptr
    character(:), allocatable :: strval
    character(len=128) :: msg
    integer :: dtype, drank

    cerr = 0_c_int
    allocate( fname, source=c2f_char(cname))
    ! write(*,*) "got cname:", fname
    ! write(*,*) "got crank:",crank
    ! write(*,*) "got csize:",csize

    dtype = get_artn_dtype( fname )
    drank = get_artn_drank( fname )

    !! check if input rank and expected rank are equal
    if( int(crank) .ne. drank ) then
       write(msg, '(a,1x,i0,1x,a,1x,i0)') ". Expected:", drank, "Got:", int(crank)
       call err_set(ERR_DRANK, __FILE__, __LINE__, msg="Invalid data rank for name: "//fname//trim(msg) )
       call err_write(__FILE__,__LINE__ )
       cerr = int( ERR_DRANK, c_int )
       return
    end if

    !! the size can only be checked once artn main routine is called (need info of nat)

    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, iptr )
          ! write(*,*) iptr
          cerr = int( set_param_int( fname, int(iptr)), c_int )
       case( 1 )
          call c_f_pointer( cval, i1ptr, shape=[csize] )
          ! write(*,*) i1ptr
          cerr = int( set_param_int1d(fname, csize(1), int(i1ptr) ), c_int)
       case default
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__,__LINE__,msg="unsupported data rank for name: "//fname )
          return
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call c_f_pointer( cval, rptr )
          ! write(*,*) rptr
          cerr = int( set_param_real(fname, real(rptr, DP) ), c_int)
       case( 2 )
          call c_f_pointer( cval, r2ptr, shape=[csize] )
          ! write(*,*) r2ptr
          cerr = int( set_param_real2d( fname, csize(1), csize(2), real(r2ptr, DP) ), c_int )
       case default
          write(msg, "(i0)") drank
          cerr = int( ERR_DTYPE, c_int )
          call err_set( int(cerr), __FILE__, __LINE__, msg="unsupported data rank for name: "//fname )
          return
       end select

    case( ARTN_DTYPE_BOOL )
       call c_f_pointer( cval, bptr )
       ! write(*,*) bptr
       cerr = int( set_param_bool(fname, logical(bptr)), c_int)

    case( ARTN_DTYPE_STR )
       allocate(strval, source = c2f_string(cval))
       ! write(*,*) strval
       cerr = int( set_param_str( fname, strval), c_int )

    case default
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg="unknown variable name: "//fname )
       cerr = int( ERR_VARNAME, c_int )
       return
    end select

    deallocate( fname )
  end function set_cparam


  subroutine artn_list_set()bind(C,name="artn_list_set")
    write(*,*) "List of variables which can be set into the t_artn_data:"
    write(*,'(3x, "name                   :",3x,a8,3x,a4,3x,a)') "type", "rank", "size"
    write(*,*) repeat('=',80)
    write(*,'(3x, "alpha_mix_cr           :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "converge_property      :",3x,a8,3x,a4,3x,a)') "string", "0", "any"
    write(*,'(3x, "current_step_size      :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "delr_thr               :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenfname             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigen_step_size        :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "eigenvec_guess         :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "eigenvec               :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,nat); python [nat,3]"
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
    write(*,'(3x, "push_add_const         :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (4,nat); python [nat,4]"
    write(*,'(3x, "push_dist_thr          :",3x,a8,3x,a4,3x,a)') "real", "0","0"
    write(*,'(3x, "push_guess             :",3x,a8,3x,a4,3x,a)') "string", "0", ".le. 255"
    write(*,'(3x, "push_ids               :",3x,a8,3x,a4,3x,a)') "integer", "1", ".le. natoms"
    write(*,'(3x, "push                   :",3x,a8,3x,a4,3x,a)') "real", "2", "fortran (3,nat); python [nat,3]"
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


