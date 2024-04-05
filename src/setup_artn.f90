module m_setup_artn

  use precision, only: DP
  USE units
  USE artn_params
  use m_error
  implicit none


  integer, protected :: isetup=0

  interface

     !! start_guess.f90
     module function start_guess( nat, push, eigenvec )result(lerror)
       integer,  intent(in)  :: nat
       real(dp), intent(out) :: push(3,nat)
       real(dp), intent(out) :: eigenvec(3,nat)
       logical :: lerror
     end function start_guess

     !! push_init.f90
     module subroutine generate_push_init( nat, tau, lat, push_ids, dist_thr, add_const, step_size, mode, vector)
       integer,          intent(in)  :: nat
       real(dp),         intent(in)  :: tau(3,nat)
       real(dp),         intent(in)  :: lat(3,3)
       integer,          intent(in)  :: push_ids(nat)
       real(dp),         intent(in)  :: dist_thr
       real(dp),         intent(in)  :: add_const(4,nat)
       real(dp),         intent(in)  :: step_size
       character(*),     intent(in)  :: mode
       real(dp),         intent(out) :: vector(3,nat)
     end subroutine generate_push_init

     !! clean_artn.f90
     module subroutine clean_artn()bind(C,name="clean_artn")
     end subroutine clean_artn

  end interface

contains


  subroutine setup_artn2( nat, lerror )
    use m_artn_report, only: prev_push, prev_disp, write_initial_report
    use m_artn_data, only: eigen_step, force_step, tau_sad, tau_step, typ_step
    use m_artn_data, only: destroy_data
    implicit none
    integer,      intent(in)  :: nat
    logical,      intent(out) :: lerror

    integer :: ierr

    lerror=.false.

    ! write(*,*) "called setup"
    !!===============================================
    !! called for istep that is not zero, do nothing
    !!
    if( istep .ne. 0 ) return
    !!
    !!===============================================

    write(*,*) "enter setup2"
    call print_caller()

    !!
    !! destroy any previous data
    !!
    call destroy_data()
    !!
    !! call to clean?
    !!


    !!
    !! initialise/read the input params
    !!
    ierr = init_user_params( nat )
    if( ierr /= 0 ) then
       lerror = .true.
       ! call err_write(__FILE__,__LINE__)
       ! call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if



    !!
    !! allocate runtime arrays
    !!

    ! could be in start_guess
    call allocate_var( 3, nat, push, 0.0_DP )
    call allocate_var( 3, nat, eigenvec, 0.0_DP )

    ! fill_params?

    ! ??
    call allocate_var( 300, 3, elements, "XXX" )

    !! should move to data
    ! call allocate_var( 3, nat, eigen_sad, 0.0_DP )
    ! call allocate_var( 3, nat, tau_sad, 0.0_DP )
    call allocate_var( 3, nat, force_old, 0.0_DP )
    call allocate_var( 3, nat, eigen_step, 0.0_DP )

    !!
    !! set runtime defaults where needed
    !!
    prev_disp         = VOID
    prev_push         = VOID
    linit             = .true.
    lbasin            = .true.
    lbackward         = .true.
    lrelax            = .false.
    lend              = .false.

    call local_counters_zero()
    fpush_factor      = 1
    push_over         = 1.0_DP
    nperp_step        = 1
    neigen            = 1
    debrief = 0.0_DP
    error_message = ''
    artn_resume = ''


    !! find nmin, nsad
    nmin = read_counter_file( trim(prefix_min)//"counter" )
    nsaddle = read_counter_file( trim(prefix_sad)//"counter" )


    !!
    !! check param consistency
    !!


    !!
    !! write header/initial report
    !!
    CALL write_initial_report( filout )


    !!
    !! switch the isetup flag to 1
    !!
    isetup = 1


    write(*,*) "exit setup2"
  end subroutine setup_artn2
  !> @details C wrapper to setup_artn2
  !! C header
  !!~~~~~~~~~~~~~~~~~~~~~{.c}
  !! void setup_artn2( const int nat, const char *filnam, bool *cerror)
  !!~~~~~~~~~~~~~~~~~~~~~
  subroutine setup_artn2c( cnat, cerror )bind(C,name="setup_artn2")
    use, intrinsic :: iso_c_binding
    integer( c_int ), value :: cnat
    logical( c_bool), intent(out) :: cerror
    logical :: lerror
    call setup_artn2( int(cnat), lerror )
    cerror = logical(lerror, c_bool )
  end subroutine setup_artn2c




  !> @details
  !! initialise the user-input parameters.
  !! At the end of this function, all parameters will have a sensible value.
  function init_user_params( nat )result(ierr)
    use m_tools, only: to_lower, initialize_random_seed
    use m_option, only: nperp_limitation_init
    implicit none
    integer,      intent(in)  :: nat
    integer :: ierr

    integer :: u0, ios
    character(len=128) :: msg
    character(:), allocatable :: fname
    logical :: lerror


    !! allocate arrays which can be read from input
    !! NOTE:: maybe not the best,, these can change from one run to next
    call allocate_var( 4, nat, push_add_const, 0.0_DP )
    call allocate_var( nat, push_ids, 0 )
    !! push
    !! eigenvec
    write(*,*) "nperp_limitation is allocated:",allocated(nperp_limitation)
    if( .not. allocated(nperp_limitation)) then
       call allocate_var( 10, nperp_limitation, -2 )
       call nperp_limitation_init( lnperp_limitation )
    end if


    !! if( engine ) then
    !!    undef all except filin
    !!    read file
    !!    make units
    !!    convert
    !! endif
    ! if( called_from == CALLER_IS_ENGINE ) then
    if( defined_var(filin) ) then
       !
       write(*,*) "we read params from file"
       !
       ! which filename we read
       allocate( fname, source = filin )
       !
       ! read params from file
       !
       ierr = read_param_file( fname )
       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
          return
       end if

       deallocate( fname )
       !
    else
       write(*,*) "file for params not specified"
    end if

    !!
    !! make units (if already done, it will return without error)
    !!
    call make_units( engine_units, lerror )
    if( lerror ) then
       ierr = ERR_UNITS
       call err_write( __FILE__,__LINE__)
       ! call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    !! check undef, set default values which are already in the units of artn
    !! real
    if( .not. defined_var( forc_thr                )) forc_thr                = def_forc_thr
    if( .not. defined_var( eigval_thr              )) eigval_thr              = def_eigval_thr
    if( .not. defined_var( etot_diff_limit         )) etot_diff_limit         = def_etot_diff_limit
    if( .not. defined_var( push_step_size          )) push_step_size          = def_push_step_size
    if( .not. defined_var( push_step_size_per_atom )) push_step_size_per_atom = def_push_step_size_per_atom
    if( .not. defined_var( eigen_step_size         )) eigen_step_size         = def_eigen_step_size
    if( .not. defined_var( lanczos_disp            )) lanczos_disp            = def_lanczos_disp
    !! str
    if( .not. defined_var( push_mode )) push_mode = "all"
    !! converge_property is alocatable, cannot check with defined_var() ...
    if( .not. allocated(converge_property)) allocate( converge_property, source="maxval")


    !! set initial random seed
    call initialize_random_seed( zseed )
  end function init_user_params


  !> @details
  !! read parameters from file, immediately make units, and convert the
  !! defined parameters into artn units
  function read_param_file( fname )result(ierr)
    !! read file
    !! make units
    !! convert
    use m_tools, only: to_lower
    use m_artn_report, only: overwrite_msg
    implicit none
    character(*), intent(in) :: fname
    integer :: ierr

    integer :: ios, u0
    character(len=128) :: msg
    character(:), allocatable :: amsg
    logical :: lerror, overwrite_vars

    !!
    !! undef all input vars; might be there from previous run?
    !!
    !! NOTE: this should be done by clean, for params which need to be reset
    ! call undefine_params()

    !!
    !! open input file
    !!
    !!inquire( fname )
    open( newunit=u0, file=fname, status="old", action="read", iostat=ios, iomsg=msg )
    if( ios /= 0 ) then
       ierr = ERR_FILE
       error_message = trim(msg)
       call err_set(ERR_FILE, __FILE__, __LINE__, msg=trim(msg))
       return
    end if

    !!
    !! check if any variables from API will get overwritten by reading the input
    !! namelist from file
    !!
    if( called_from == CALLER_IS_API ) then
       overwrite_vars = check_namelist_variables(u0, amsg)
       if( overwrite_vars ) then
          !! set message into global
          allocate( overwrite_msg, source=amsg)
          deallocate(amsg)
       end if
    end if
    !!
    !! read artn_parameters namelist
    !! this overwrites anything already set in the params!
    !! Including engine_units
    !!
    read( u0, nml=artn_parameters, iostat=ios)
    IF( ios /= 0 ) THEN
       BACKSPACE(u0)
       READ(u0, '(a)' ) msg
       ierr = ERR_OTHER
       call err_set(ierr, __FILE__,__LINE__,msg="ERROR reading artn input: "//trim(msg) )
       RETURN
    END IF
    close( u0, status = "keep" )
    !!
    !! make units
    !!
    engine_units = to_lower( engine_units )
    call make_units( engine_units, lerror )
    if( lerror ) then
       ierr = ERR_UNITS
       call err_write( __FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if
    !!
    !! immediately convert units of the defined values.
    !! Do not touch the undefined.
    !!
    if( defined_var( forc_thr ) ) &
         forc_thr        = convert_param( "forc_thr", forc_thr )

    if( defined_var( eigval_thr ) ) &
         eigval_thr      = convert_param( "eigval_thr", eigval_thr )

    if( defined_var( etot_diff_limit ) ) &
         etot_diff_limit = convert_param( "etot_diff_limit", etot_diff_limit )

    if( defined_var( push_step_size ) ) &
         push_step_size  = convert_param( "push_step_size", push_step_size )

    if( defined_var( push_step_size_per_atom ) ) &
         push_step_size_per_atom = convert_param( "push_step_size_per_atom", push_step_size_per_atom )

    if( defined_var( eigen_step_size ) ) &
         eigen_step_size = convert_param( "eigen_step_size", eigen_step_size )

    if( defined_var( lanczos_disp ) ) &
         lanczos_disp    = convert_param( "lanczos_disp", lanczos_disp )

    ierr = 0

  end function read_param_file




  subroutine reset_params()bind(C, name="reset_params")
    !!
    !! undefine the user params, set the initial values from artn_params_mod
    !!
    implicit none

    verbose     = 0
    zseed       = 0
    nperp       = -1
    nevalf_max  = NAN_INT
    ninit       = 3
    neigen      = 1
    lanczos_max_size = 16
    lanczos_min_size = 3
    nsmooth          = 0
    nnewchance       = 0
    nrelax_print     = 5
    restart_freq     = 0

    push_dist_thr = def_push_dist_thr
    delr_thr      = def_delr_thr
    push_over     = 1.0_DP
    alpha_mix_cr  = def_alpha_mix_cr
    lanczos_eval_conv_thr = def_lanczos_eval_conv_thr

    forc_thr                = NAN_REAL
    eigval_thr              = NAN_REAL
    etot_diff_limit         = NAN_REAL
    push_step_size          = NAN_REAL
    push_step_size_per_atom = NAN_REAL
    eigen_step_size         = NAN_REAL
    lanczos_disp            = NAN_REAL

    push_mode      = NAN_STR
    engine_units   = NAN_STR
    push_guess     = NAN_STR
    eigenvec_guess = NAN_STR
  end subroutine reset_params


  !> @details read the counter
  function read_counter_file( fname )result( number )
    implicit none
    character(*), intent(in) :: fname
    integer :: number

    logical :: file_exists
    character(20) :: dum
    integer :: u0, ios
    character(len=128) :: msg

    !! if file does not exist, return 0
    number = 0

    inquire( file=fname, exist=file_exists )
    if( file_exists ) then
       open(newunit=u0, file=fname, action="read", status="old", iostat=ios, iomsg=msg)
       if( ios/=0) then
          !! should not happen
          call err_set( ERR_OTHER, __FILE__,__LINE__,msg=msg)
          call err_write(__FILE__, __LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if
       read(u0,*) dum, dum, number
       close(u0, status="keep")
    end if
  end function read_counter_file



  !> @brief
  !!   set all counters used locally in single ARTn run to zero
  subroutine local_counters_zero()
    use m_block_lanczos, only: ilanc
    implicit none
    iartn             = 0
    istep             = 0
    iinit             = 0
    iperp             = 0
    ilanc             = 0
    ieigen            = 0
    irelax            = 0
    iover             = 0
    inewchance        = 0
    ismooth           = 0
  end subroutine local_counters_zero


  subroutine print_caller()bind(C)
    use artn_params, only: called_from
    write(*,*) ":: caller is:",called_from
  end subroutine print_caller


  function check_namelist_variables( u0, out_msg )result(will_overwrite)
    !! check which variables are present in the namelist artn_parameters contained
    !! in the file opened at unit=u0.
    !! Return message containing the info about variables whose value will get overwritten
    !! by reading the namelist.
    !!
    !! @param[in] u0 :: opened file unit
    !! @param[out] out_msg :: message about which valeus will get overwritten
    use, intrinsic :: iso_fortran_env, only: io_end=>iostat_end
    use m_tools, only: parser, to_lower
    implicit none
    integer, intent(in) :: u0
    character(:), intent(out), allocatable :: out_msg
    logical :: will_overwrite

    character(*), parameter :: info="aa"
    character(len=500) :: line
    character(len=600) :: msg
    logical :: eof
    integer :: ios, i, n_var
    integer :: nwords
    character(:), allocatable :: words(:)

    msg = ""
    eof = .false.

    !! read each line of file:
    !! to avoid infinite do loop, limit the max number of read lines
    i = 0
    do while( i < 100 )
       read(u0, "(a500)", iostat=ios) line
       !! reach end of file
       if( ios == io_end ) exit

       !! parse the line
       nwords = parser( trim(line), "=", words )
       if( nwords .le. 1 ) cycle

       !! check if variable already defined
       select case( to_lower(words(1)) )
       case("lrestart"          ); msg=trim(msg)//new_line("a")//"lrestart"
       case("lpush_final"       ); msg=trim(msg)//new_line("a")//"lpush_final"
       case("lmove_nextmin"     ); msg=trim(msg)//new_line("a")//"lmove_nextmin"
       case("lserialize_output" ); msg=trim(msg)//new_line("a")//"lserialize_output"
       case("ninit"             ); msg=trim(msg)//new_line("a")//"ninit"
       case("neigen"            ); msg=trim(msg)//new_line("a")//"neigen"
       case("nperp"             ); msg=trim(msg)//new_line("a")//"nperp"
       case("lanczos_max_size"  ); msg=trim(msg)//new_line("a")//"lanczos_max_size"
       case("lanczos_min_size"  ); msg=trim(msg)//new_line("a")//"lanczos_min_size"
       case("nsmooth"           ); msg=trim(msg)//new_line("a")//"nsmooth"
       case("nevalf_max"        ); msg=trim(msg)//new_line("a")//"nevalf_max"
       case("push_dist_thr"     ); msg=trim(msg)//new_line("a")//"push_dist_thr"
       case("push_ids"          ); msg=trim(msg)//new_line("a")//"push_ids"
       case("push_add_const"    ); msg=trim(msg)//new_line("a")//"push_add_const"
       case("delr_thr"          ); msg=trim(msg)//new_line("a")//"delr_thr"
       case("converge_property" ); msg=trim(msg)//new_line("a")//"converge_property"
       case("push_over"         ); msg=trim(msg)//new_line("a")//"push_over"
       case("elements"          ); msg=trim(msg)//new_line("a")//"elements"
       case("push"              ); msg=trim(msg)//new_line("a")//"push"
       case("eigenvec"          ); msg=trim(msg)//new_line("a")//"eigenvec"
       case("filout"            ); msg=trim(msg)//new_line("a")//"filout"
       case("initpfname"        ); msg=trim(msg)//new_line("a")//"initpfname"
       case("eigenfname"        ); msg=trim(msg)//new_line("a")//"eigenfname"
       case("restartfname"      ); msg=trim(msg)//new_line("a")//"restartfname"
       case("verbose"           ); msg=trim(msg)//new_line("a")//"verbose"
       case("zseed"             ); msg=trim(msg)//new_line("a")//"zseed"
       case("restart_freq"      ); msg=trim(msg)//new_line("a")//"restart_freq"
       case("struc_format_out"  ); msg=trim(msg)//new_line("a")//"struc_format_out"
       case("nnewchance"        ); msg=trim(msg)//new_line("a")//"nnewchance"
       case("lanczos_at_min"    ); msg=trim(msg)//new_line("a")//"lanczos_at_min"
       case("nrelax_print"      ); msg=trim(msg)//new_line("a")//"nrelax_print"
       case("alpha_mix_cr"      ); msg=trim(msg)//new_line("a")//"alpha_mix_cr"
       case("lanczos_always_random" ); msg=trim(msg)//new_line("a")//"lanczos_always_random"
       case("lanczos_eval_conv_thr" ); msg=trim(msg)//new_line("a")//"lanczos_eval_conv_thr"

       case("push_mode"         )
          if( defined_var(push_mode)) msg=trim(msg)//new_line("a")//"push_mode"
       case("engine_units"      )
          if(defined_var(engine_units)) msg=trim(msg)//new_line("a")//"engine_units"
       case("push_guess"        )
          if( defined_var(push_guess)) msg=trim(msg)//new_line("a")//"push_guess"
       case("eigenvec_guess"    )
          if(defined_var(eigenvec_guess)) msg=trim(msg)//new_line("a")//"eigenvec_guess"

       case("etot_diff_limit"   )
          if( defined_var(etot_diff_limit)) msg=trim(msg)//new_line("a")//"etot_diff_limit"
       case("push_step_size_per_atom" )
          if(defined_var(push_step_size_per_atom)) msg=trim(msg)//new_line("a")//"push_step_size_per_atom"
       case("push_step_size"    )
          if( defined_var(push_step_size)) msg=trim(msg)//new_line("a")//"push_step_size"
       case("eigen_step_size"   )
          if(defined_var(eigen_step_size)) msg=trim(msg)//new_line("a")//"eigen_step_size"
       case("lanczos_disp"      )
          if( defined_var(lanczos_disp)) msg=trim(msg)//new_line("a")//"lanczos_disp"
       case("eigval_thr"        )
          if( defined_var(eigval_thr) ) msg=trim(msg)//new_line("a")//"eigval_thr"
       case( "forc_thr" )
          if( defined_var(forc_thr) ) msg=trim(msg)//new_line("a")//"forc_thr"

       case( "nperp_limitation" )
          if( count(nperp_limitation .eq. -2) .ne. size(nperp_limitation)) then
             deallocate(nperp_limitation)
             allocate( nperp_limitation, source=def_nperp_limitation)
             msg = trim(msg)//new_line("a")//"nperp_limitation"
          end if

       end select

       i = i + 1
    end do

    !! write final message
    if( len_trim(msg) > 0 ) then
       msg = &
            "============"//&
            new_line("a")// &
            "INFO :: some values have been potentially overwritten by reading input file: "// &
            trim(msg)//new_line("a")//&
            "============"

    end if
    allocate( out_msg, source=trim(msg))

    !! rewind the file
    rewind(u0, iostat=ios)
    if( ios /= 0 ) then
       call err_set(ERR_OTHER,__FILE__,__LINE__,msg="rewind failed")
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
    end if


    !! set result
    will_overwrite = .false.
    if( len_trim(out_msg) > 0) will_overwrite = .true.
  end function check_namelist_variables

end module m_setup_artn

