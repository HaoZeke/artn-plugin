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

     module subroutine reset_setup()
     end subroutine reset_setup

  end interface

contains


  subroutine setup_artn2( nat, lerror )
    use m_artn_report, only: write_initial_report, reset_report_params
    use m_artn_data, only: eigen_step
    use m_artn_data, only: destroy_data
    use m_block_lanczos, only: reset_lanczos_params
    implicit none
    integer,      intent(in)  :: nat
    logical,      intent(out) :: lerror

    integer :: ierr

    lerror=.false.

    write(*,*) "called setup"
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
    !! reset the error status
    !!
    call reset_error()

    !!
    !! initialise/read the input params
    !!
    ierr = init_user_params( nat )
    if( ierr /= 0 ) then
       lerror = .true.
       ! call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    !! at this point, all user input should be allocated and good values set.


    !!
    !! allocate runtime arrays
    !!

    ! could be in start_guess
    call allocate_var( 3, nat, push, 0.0_DP )
    call allocate_var( 3, nat, eigenvec, 0.0_DP )

    ! fill_params?

    ! ??
    ! call allocate_var( 300, 3, elements, "XXX" )

    !! should move to data
    ! call allocate_var( 3, nat, eigen_sad, 0.0_DP )
    ! call allocate_var( 3, nat, tau_sad, 0.0_DP )
    call allocate_var( 3, nat, force_old, 0.0_DP )
    call allocate_var( 3, nat, eigen_step, 0.0_DP )




    !!
    ! call reset_runparams()

    !!
    !! (re)set runtime defaults where needed
    !!

    !! block flags
    call reset_blockflags()
    !!
    !! set the lend flag
    !!
    lend = .false.

    !! counters
    call local_counters_zero()

    !! other run params
    fpush_factor      = 1
    push_over         = 1.0_DP
    nperp_step        = 1
    neigen            = 1
    debrief = 0.0_DP
    error_message = ''
    artn_resume = ''

    !! report
    call reset_report_params()

    !! lanczos
    nlanc = lanczos_max_size
    call reset_lanczos_params()



    !! find nmin, nsad
    nmin = read_counter_file( trim(prefix_min)//"counter" )
    nsaddle = read_counter_file( trim(prefix_sad)//"counter" )


    !!
    !! check param consistency
    !!
    call check_artn_params( nat, lerror )
    if( lerror ) then
       call err_write( __FILE__, __LINE__ )
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if



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
  !! At the end of this function, all user parameters will have a sensible value.
  function init_user_params( nat )result(ierr)
    use m_tools, only: to_lower, initialize_random_seed
    use m_option, only: nperp_limitation_init
    implicit none
    integer,      intent(in)  :: nat
    integer :: ierr

    character(len=128) :: msg
    character(:), allocatable :: fname
    logical :: lerror, readfile, read_serial


    !! allocate arrays which can be read from input.
    !! These might have been set before simulation box and `nat` was known, therefore the size
    !! of arrays can be anything. Make check here.

    !! check push_ids, expected (1:nat)
    if( .not.allocated(push_ids) ) then
       allocate( push_ids(1:nat), source = 0)
    else
       !! push_ids has always contiguous values, can copy and resize
       call resize1d_int( nat, push_ids, 0 )
    end if

    !! check push_add_const, expected (1:4, 1:nat)
    if( .not. allocated(push_add_const) ) then
       !! allocate new
       allocate( push_add_const(1:4,1:nat), source=0.0_DP)
    else
       !! push_add_const can have non-contiguous values, cannot copy and resize.
       !! check size1
       if( size(push_add_const,1) .ne. 4 ) then
          ierr = ERR_SIZE
          msg = "push_add_const has wrong size in dim1, got:"
          write(msg,"(a,1x,i0,1x,a)") trim(msg),size(push_add_const,1),"expected: 4"
          call err_set(ierr, __FILE__,__LINE__,msg=trim(msg) )
          return
       end if
       !! check size2
       if( size(push_add_const,2) .ne. nat ) then
          ierr = ERR_SIZE
          msg = "push_add_const has wrong size in dim2, got:"
          write(msg,"(a,1x,i0,1x,a,1x,i0)") trim(msg),size(push_add_const,2),"expected:",nat
          call err_set(ierr, __FILE__,__LINE__,msg=trim(msg) )
          return
       end if
    end if

    !! push

    !! eigenvec

    !! nperp_limitation, expected (1:any)
    if( .not. allocated(nperp_limitation)) then
       allocate( nperp_limitation(1:10), source=-2)
       ! call allocate_var( 10, nperp_limitation, -2 )
    end if



    !! determine if read from file, and which filename:
    readfile = .false.
    !! `filin` is defined, read from there
    if( defined_var(filin) ) then
       readfile = .true.
       allocate( fname, source = filin )
    end if
    !! inquire for serialized input with name = `serial_input_fname`
    !! if it exist, it has priority over `filin`
    inquire( file=serial_input_fname, exist=read_serial, name=msg )
    if( read_serial ) then
       readfile = .true.
       lserialize_input = .true.
       if( allocated(fname))deallocate(fname)
       allocate(fname, source=trim(msg))
    end if


    if( readfile ) then
       !
       write(*,*) "we read params from file: ",fname
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

    !! finally check undefined, set default values which are already in the units of artn
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


    !! nperp_limitation initialize
    call nperp_limitation_init( lnperp_limitation )

    !! set initial random seed
    call initialize_random_seed( zseed )

    ierr = 0

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
    logical :: overwrite_vars

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
          if( allocated(overwrite_msg))deallocate(overwrite_msg)
          allocate( overwrite_msg, source=amsg)
          deallocate(amsg)
       end if
    end if
    !!
    !! read artn_parameters namelist
    !! this overwrites anything already set in the params!
    !! Including engine_units
    !!
    ierr = read_params_namelist( u0 )
    if( ierr /= 0 ) then
       call err_write(__FILE__,__LINE__)
       call err_set(ierr,__FILE__,__LINE__,msg="got error from read_params_namelist")
       return
    end if
    close( u0, status = "keep" )

    ierr = 0

  end function read_param_file




  subroutine reset_params()bind(C, name="reset_params")
    !!
    !! undefine the user params, set the initial values from artn_params_mod
    !!
    implicit none

    verbose     = 2
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

    !! deallocate?
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
    !! do not touch the counters of multiple explorations :: isearch, ifound, ifails
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


  !> @details
  !! read namelist from opened file.
  !! Strategy: read single line from input file, then try reading nml=artn_parameters
  !! from this line. Advantage is that we know in advance which variable
  !! will be read next, so can check allocation, make proper converisons, etc.
  !! Make special cases for reading the params which need conversion.
  !! This is to avoid multiple conversion if the value is already set.
  !! --- 'make_units' is called here.
  function read_params_namelist( u0 )result(ierr)
    use, intrinsic :: iso_fortran_env, only: io_end=>iostat_end
    use m_tools, only: parser, to_lower
    implicit none
    integer, intent(in) :: u0
    integer :: ierr

    integer :: i, ios
    character(len=500) :: line, str, msg
    integer :: nwords
    character(:), allocatable :: words(:), words1(:)
    logical :: lerror
    integer :: tmpint

    ierr = 0

    !! rewind file
    rewind(u0)
    i = 0
    do while( i < 100 )
       !! read line
       read(u0, "(a500)", iostat=ios) line
       !! reach end of file
       if( ios == io_end ) exit

       line = trim(adjustl(line))
       !! skip commented lines
       if( line(1:1) == "!") cycle

       !! skip empty lines
       if(len_trim(line) .le. 2) cycle

       !! parse the line for '=', to get the variable name
       nwords = parser( trim(line), "=", words )
       if( nwords .le. 1 ) cycle

       !! write nml string containing whole current line
       str = "&artn_parameters "//trim(line)//" /"


       !!---
       !! things to do before reading the value::
       !! parse the first word for '(' which might be present in lines like: "push_add_const(:,idx)"
       nwords = parser(trim(words(1)), "(", words1 )
       !!
       select case( to_lower(words1(1)))
       case( "nevalf_max" )
          !! save the current value (it could already be set from engine)
          tmpint = nevalf_max
       case( "elements" )
          !! overwrite previously set values (if any)
          if(allocated(elements))deallocate(elements)
          allocate(elements(1:300),source="XXX")
       end select

       !! read value from nml string
       read( str, nml=artn_parameters, iostat = ios, iomsg = msg )

       !! check for error in reading value
       if( ios /= 0 ) then
          ierr = ERR_OTHER
          call err_set(ERR_OTHER, __FILE__,__LINE__,msg=trim(msg))
          write(*,*) "line:",line
          write(*,*) "str:",trim(str)
          backspace(u0)
          read(u0, '(a)')line
          write(*,*) "error reading:",trim(line)
          return
       end if

       !!---
       !! things to do after reading the value ::
       !!
       !! variables which need conversion:: only convert if variable has
       !! been actually read, this is to avoid converting multiple times
       select case( to_lower(words(1)) )
       case( "nevalf_max" )
          !! take the more stringent nevalf_max between input and saved
          nevalf_max = min( nevalf_max, tmpint )
       case( "engine_units" )
          !! make units immediately
          engine_units = to_lower( engine_units )
          call make_units( engine_units, lerror )
          if( lerror ) then
             ierr = ERR_UNITS
             call err_write( __FILE__,__LINE__)
             call merr(__FILE__,__LINE__,kill=.true.)
             return
          end if
       case( "forc_thr" ); forc_thr = convert_param( "forc_thr", forc_thr, ierr )
       case( "eigval_thr" ); eigval_thr = convert_param( "eigval_thr", eigval_thr, ierr )
       case( "etot_diff_limit" ); etot_diff_limit = convert_param( "etot_diff_limit", etot_diff_limit, ierr )
       case( "push_step_size" ); push_step_size = convert_param( "push_step_size", push_step_size, ierr )
       case( "push_step_size_per_atom" )
          push_step_size_per_atom = convert_param( "push_step_size_per_atom", push_step_size_per_atom, ierr )
       case( "eigen_step_size" ); push_step_size = convert_param( "push_step_size", push_step_size, ierr )
       case( "lanczos_disp" ); lanczos_disp = convert_param("lanczos_disp", lanczos_disp, ierr )
       case default
       end select
       !! error after reading (in conversion)
       if( ierr /= 0) then
          call err_write(__FILE__,__LINE__)
          return
       end if

       i = i + 1
    end do

  end function read_params_namelist


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
    integer :: ios, i
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

       case default
          msg=trim(msg)//new_line("a")//to_lower(words(1))
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

  subroutine resize1d_int( dim, array, src )
    !! resize 1d array to (dim). If array is allocated, copy the common
    !! elements into the new array after resize.
    implicit none
    integer, intent(in) :: dim
    integer, allocatable, intent(inout) :: array(:)
    integer, intent(in) :: src

    integer, allocatable :: tmp(:)
    integer :: size1, i1

    !! array is allocated, check its size
    !! keep original size
    size1 = size(array, 1)
    !! check against wanted dimensions
    if( size1 /= dim ) then
       !! make tmp copy
       call move_alloc( array, tmp )
       !! allocate array to the desired dimension
       allocate(array(1:dim), source=src)
       !! copy the common elements to new array
       i1 = min(size1, dim)
       array(1:i1) = tmp(1:i1)
       !! deallocate tmp
       deallocate( tmp )
    end if
  end subroutine resize1d_int


  !> @details
  !! reset the setup status flag
  module subroutine reset_setup()
    isetup = 0
  end subroutine reset_setup

end module m_setup_artn

