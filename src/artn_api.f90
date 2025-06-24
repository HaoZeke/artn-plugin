module artn_api2



  !! make the DP precision of pARTn available with this module
  use m_artn_precision, only: DP

  !! the datainfo functions
  use m_datainfo, only: artn_dtype => get_artn_dtype
  use m_datainfo, only: artn_drank => get_artn_drank
  use m_datainfo, only: artn_dsize => get_artn_dsize
  use m_datainfo, only: ARTN_DTYPE_UNKNOWN, &
                        ARTN_DTYPE_INT, &
                        ARTN_DTYPE_REAL, &
                        ARTN_DTYPE_BOOL, &
                        ARTN_DTYPE_STR

  !! make the set/get functions available from this module.
  !! NOTE: the expected precision is DP for these, and no checks
  !! for correct dtype/drank/dsize are done.
  use artn_params, only: set_param, get_param
  use artn_params, only: set_runparam, get_runparam
  use artn_params, only: dump_input, dump_data, read_datadump
  use m_artn_data, only: set_data, get_data
  use m_artn_step, only: artn_step, artn_step_reset
  use m_setup_artn, only: setup_artn, clean_artn
  use m_fire, only: fire_set, fire_get
  use m_fire, only: artn_fire_dtype => fire_dtype
  use m_error, only: get_error

  implicit none

  private
  !! make some stuff public
  public :: DP
  public :: ARTN_DTYPE_UNKNOWN, &
            ARTN_DTYPE_INT, &
            ARTN_DTYPE_REAL, &
            ARTN_DTYPE_BOOL, &
            ARTN_DTYPE_STR
  public :: artn_create, artn_destroy
  public :: artn_set, artn_extract
  public :: artn_merr
  public :: artn_dtype, artn_drank, artn_dsize
  public :: artn_fire_dtype
  public :: set_param, get_param, set_runparam, get_runparam, set_data, get_data
  public :: dump_input, dump_data, read_datadump
  public :: artn_step, artn_step_reset
  public :: setup_artn, clean_artn
  public :: fire_set, fire_get
  public :: get_error




  !> @defgroup group_artn_set
  !> @{

  !> @details
  !! The preferred way to set input parameters is through artn_set,
  !! which also does checks on data type, rank, and size.
  !! It also converts the data to proper precision.
  !!
  !! @code{.f90}
  !!     ! signature:
  !!     ! subroutine artn_set( name, val, ierr )
  !!     !
  !!     ! description:
  !!     ! name : character(*), name of variable
  !!     ! val  : the value to set
  !!     ! ierr [optional] : integer, negative on error, zero otherwise
  !!     use artn_api2, only: artn_set
  !!     call artn_set( "engine_units", "lammps/metal")
  !!     call artn_set( "forc_thr", 0.02 )
  !!     call artn_set( "push_ids", [23, 25, 68] )
  !! @endcode
  interface artn_set
     !> @cond SKIP
     module procedure :: set_star
     module procedure :: set_int1d, set_real2d, set_real2d_dp
     !> @endcond
  end interface artn_set
  !> @}



  !> @defgroup group_artn_extract
  !> @{

  !> @details
  !! The preferred way to extract generated data from pARTn is through artn_extract,
  !! which checks the proper datatypes, and performs allocation where needed, and converts
  !! the precision.
  !!
  !! @code{.f90}
  !!     ! signature:
  !!     ! function artn_extract( name, val ) result( ierr )
  !!     !
  !!     ! description:
  !!     ! name : character(*), name of variable
  !!     ! val  : the obtained value
  !!     ! ierr : integer, negative on error, zero otherwise
  !!     use artn_api2, only: artn_extract
  !!     integer :: ierr
  !!     real, allocatable :: coords_saddle(:,:)
  !!     ierr = artn_extract( "tau_sad", coords_saddle )
  !!     if( ierr /= 0 ) then
  !!        ! there is an error
  !!     endif
  !! @endcode
  interface artn_extract
     !> @cond SKIP
     module procedure :: extract_int, extract_real, extract_bool, extract_str
     module procedure :: extract_int1d, extract_real2d
     module procedure :: extract_real_dp, extract_real2d_dp
     !> @endcond
  end interface artn_extract
  !> @}

contains

  !> @defgroup group_artn_create
  !> @{

  !> @details
  !! Prepare pARTn to be called through the API:
  !!   set some variables to avoid reading/writing to files.
  !!
  !! This is not strictly needed to execute, but take care when omitting it.
  !!
  !! Example:
  !! @code{.f90}
  !!  use artn_api2, only: artn_create
  !!  integer :: ierr
  !!  ierr = artn_create()
  !! @endcode
  !!
  !! C-wrapper:
  !! @code{.c}
  !!  #include artn.h
  !!  int ierr = artn_create()
  !! @endcode
  function artn_create()result( ierr )
    use artn_params, only: called_from, filin, verbose, struc_format_out
    use units, only: CALLER_IS_API, NAN_STR
    implicit none
    integer :: ierr

    ierr = 0

    !! set called_from value. This is only for convenience,
    !! it triggers an additional test when combining set_param() and read from file.
    called_from = CALLER_IS_API

    !! modify input filename to undefined str.
    !! This makes pARTn not read from file, but instead expect params to be
    !! set through set_params().
    filin = NAN_STR

    !! modify default verbose to zero
    verbose = 0

    !! modify default struc_format_out to 'none'
    struc_format_out = 'none'

    ! write(*,*) "CF", called_from
  end function artn_create
  !> @details
  !! C-wrapper
  function artn_create_c()result(cerr)bind(C,name="artn_create")
    use, intrinsic :: iso_c_binding, only: c_int
    integer( c_int ) :: cerr
    cerr = int( artn_create(), kind=c_int )
  end function artn_create_c
  !> @}



  !> @details
  !! Destroy all data and parameters to free the memory from artn.
  !! After this call, data/params cannot be extracted anymore.
  subroutine artn_destroy()bind(C,name="artn_destroy")
    !! deallocate params and data, unlink pointers, etc.
    !! call all the reset() routines
    use artn_params, only: reset_params, destroy_runparams
    use m_setup_artn, only: clean_artn, reset_runparams
    use m_artn_data, only: destroy_data
    use m_block_lanczos, only: destroy_lanczos
    use m_artn_step, only: artn_step_reset

    call clean_artn()
    call reset_params()
    call reset_runparams()
    call destroy_runparams()
    call destroy_data()
    call destroy_lanczos()
    call artn_step_reset()
  end subroutine artn_destroy



  !> @cond SKIP
  subroutine artn_merr( file, linenr )
    use m_error, only: err_write, merr
    use, intrinsic :: iso_fortran_env, only: stdout => output_unit
    implicit none
    character(*), intent(in) :: file
    integer, intent(in) :: linenr
    write(stdout, *) repeat("=",40)
    write(stdout,"(a,1x,a,1x,a,1x,i0)") ">> API call to err_write called from:",trim(file),"line:",linenr
    call err_write( file, linenr )
  end subroutine artn_merr
  !! C-wrapper
  subroutine artn_cmerr( cfile, linenr )bind(C, name="artn_merr")
    use m_error, only: err_write, merr
    use m_tools, only: c2f_char
    use, intrinsic :: iso_c_binding, only: c_char, c_int
    use, intrinsic :: iso_fortran_env, only: stdout => output_unit
    implicit none
    character(len=1, kind=c_char), intent(in) :: cfile(*)
    integer(c_int), intent(in), value :: linenr
    character(:), allocatable :: file
    allocate( file, source=c2f_char(cfile))
    call artn_merr( file, int(linenr) )
    deallocate( file )
  end subroutine artn_cmerr

  !> @endcond


  !> @cond SKIP

  !! Set a value to user parameter <name>. These routines are overloaded with a
  !! generic call: `artn_set()`.
  !!
  !! The `ierr` is optional, it has nonzero value on error.
  !!
  subroutine set_star( name, val, ierr )
    use artn_params, only: set_param
    use m_error, only: err_set, err_write, merr, err_caller
    implicit none
    character(*),      intent(in) :: name
    class(*),          intent(in) :: val
    integer, optional, intent(out) :: ierr
    integer :: ferr
    character(len=256) :: msg
    !! check expected dtyp
    ferr = check_dtyp( name, val, msg )
    if( ferr /= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! check expected drank
    ferr = check_drank( name, 0, msg )
    if( ferr/= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! set the param
    select type( val )
    type is( integer  ); ferr = set_param( name, val )
    type is( real     ); ferr = set_param( name, real(val, DP) )
    type is( real(DP) ); ferr = set_param( name, val )
    type is( logical  ); ferr = set_param( name, val )
    type is( character(*) ); ferr = set_param( name, val )
    class default
       call err_set( -999, __FILE__,__LINE__,msg="class(*) type of <val> unknown for name: "//name )
       call merr(__FILE__,__LINE__,kill=.true.)
    end select
    if( ferr /= 0 ) call err_caller( __FILE__, __LINE__)
    if( present(ierr))ierr = ferr
  end subroutine set_star
  subroutine set_int1d( name, val, ierr )
    use artn_params, only: set_param
    use m_error, only: err_set, err_write, err_caller
    implicit none
    character(*),      intent(in) :: name
    integer,           intent(in) :: val(:)
    integer, optional, intent(out) :: ierr
    integer :: ferr
    character(len=256) :: msg
    !! check expected dtyp
    ferr = check_dtyp( name, val(1), msg )
    if( ferr /= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! check expected drank
    ferr = check_drank( name, 1, msg )
    if( ferr/= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! set the param
    ferr = set_param( name, size(val), val )
    if( ferr /= 0 ) call err_caller( __FILE__, __LINE__)
    if( present(ierr))ierr = ferr
  end subroutine set_int1d
  subroutine set_real2d( name, val, ierr )
    use artn_params, only: set_param
    use m_error, only: err_set, err_write, err_caller
    implicit none
    character(*),      intent(in) :: name
    real,              intent(in) :: val(:,:)
    integer, optional, intent(out) :: ierr
    integer :: ferr
    character(len=256) :: msg
    !! check expected dtyp
    ferr = check_dtyp( name, val(1,1), msg )
    if( ferr /= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! check expected drank
    ferr = check_drank( name, 2, msg )
    if( ferr/= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! set the param
    ferr = set_param( name, size(val,1), size(val,2), real(val, DP) )
    if( ferr /= 0 ) call err_caller( __FILE__, __LINE__)
    if( present(ierr))ierr = ferr
  end subroutine set_real2d
  subroutine set_real2d_dp( name, val, ierr )
    use artn_params, only: set_param
    use m_error, only: err_set, err_write, err_caller
    implicit none
    character(*),      intent(in) :: name
    real(DP),          intent(in) :: val(:,:)
    integer, optional, intent(out) :: ierr
    integer :: ferr
    character(len=256) :: msg
    !! check expected dtyp
    ferr = check_dtyp( name, val(1,1), msg )
    if( ferr /= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! check expected drank
    ferr = check_drank( name, 2, msg )
    if( ferr/= 0 ) then
       call err_set(ferr, __FILE__, __LINE__, msg=trim(msg))
       if( present(ierr)) then; ierr = ferr
       else; call err_write(__FILE__,__LINE__)
       end if
       return
    end if
    !! set the param
    ferr = set_param( name, size(val,1), size(val,2), real(val, DP) )
    if( ferr /= 0 ) call err_caller( __FILE__, __LINE__)
    if( present(ierr))ierr = ferr
  end subroutine set_real2d_dp
  !> @endcond


  !> @cond SKIP

  !! Functions to extract data generated by ARTn.
  !! Overloaded by the generic `artn_extract()`.
  !! The `ierr` has negative value on error.
  ! function extract_star( name, val )result(ierr)
  !   use m_artn_data, only: get_data
  !   use m_error, only: err_set
  !   implicit none
  !   character(*), intent(in) :: name
  !   class(*), intent(out) :: val
  !   integer :: ierr
  !   character(len=256) :: msg
  !   real(DP) :: dval
  !   !! check expected dtyp
  !   ierr = check_dtyp( name, val, msg )
  !   if( ierr /= 0 ) then
  !      call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
  !      return
  !   end if
  !   !! check expected drank
  !   ierr = check_drank( name, 0, msg )
  !   if( ierr /= 0 ) then
  !      call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
  !      return
  !   end if
  !   !! get value
  !   select type( val )
  !   type is( integer )
  !      val = -999
  !      call get_data( name, val, ierr )
  !   type is( real )
  !      val = -9999.9
  !      call get_data( name, dval, ierr )
  !      val = real( dval )
  !   type is( logical )
  !      call get_data( name, val, ierr )
  !   type is( character(*) )
  !      if( len_trim(val) == 0 ) then
  !         !! non-allocated character
  !      end if
  !      call get_data( name, val, ierr )
  !   end select
  ! end function extract_star
  function extract_int( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    integer, intent(out) :: val
    integer :: ierr
    character(len=256) :: msg
    val = -999
    !! check expected dtyp
    ierr = check_dtyp( name, val, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, val, ierr )
  end function extract_int
  function extract_real( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    real, intent(out) :: val
    real(DP) :: dval
    integer :: ierr
    character(len=256) :: msg
    val = -999.9
    !! check expected dtyp
    ierr = check_dtyp( name, val, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, dval, ierr )
    if( ierr /= 0 ) return
    val = real(dval)
  end function extract_real
  function extract_real_dp( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    real(DP), intent(out) :: val
    real(DP) :: dval
    integer :: ierr
    character(len=256) :: msg
    val = -999.9_dp
    !! check expected dtyp
    ierr = check_dtyp( name, val, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, dval, ierr )
    if( ierr /= 0 ) return
    val = real(dval, DP)
  end function extract_real_dp
  function extract_bool( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    logical, intent(out) :: val
    integer :: ierr
    character(len=256) :: msg
    !! check expected dtyp
    ierr = check_dtyp( name, val, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, val, ierr )
  end function extract_bool
  function extract_str( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    character(:), allocatable, intent(out) :: val
    integer :: ierr
    character(len=256) :: msg
    !! check expected dtyp
    ierr = check_dtyp( name, "x", msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, val, ierr )
  end function extract_str
  function extract_int1d( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: val(:)
    integer :: ierr
    character(len=256) :: msg
    !! check expected dtyp
    ierr = check_dtyp( name, 1, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 1, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, val, ierr )
  end function extract_int1d
  function extract_real2d( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    real, allocatable, intent(out) :: val(:,:)
    integer :: ierr
    character(len=256) :: msg
    real(DP), allocatable :: dval(:,:)
    !! check expected dtyp
    ierr = check_dtyp( name, 1.0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 2, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, dval, ierr )
    if( ierr /= 0 ) return
    allocate( val, source=real(dval) )
    deallocate(dval)
  end function extract_real2d
  function extract_real2d_dp( name, val )result(ierr)
    use m_artn_data, only: get_data
    use m_error, only: err_set
    implicit none
    character(*), intent(in) :: name
    real(DP), allocatable, intent(out) :: val(:,:)
    integer :: ierr
    character(len=256) :: msg
    real(DP), allocatable :: dval(:,:)
    !! check expected dtyp
    ierr = check_dtyp( name, 1.0, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! check expected drank
    ierr = check_drank( name, 2, msg )
    if( ierr /= 0 ) then
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg))
       return
    end if
    !! get value
    call get_data( name, dval, ierr )
    if( ierr /= 0 ) return
    allocate( val, source=real(dval, DP) )
    deallocate(dval)
  end function extract_real2d_dp
  !> @endcond




  !> @cond SKIP

  !! local helper functions

  !! check the expected dtype of <name>, and compare with <val> which
  !! can be anything. If expected dtype matches the type of <val>, return no error.
  !! Otherwise write error message `msg` and negative ierr.
  function check_dtyp( name, val, msg )result(ierr)
    use m_error
    use m_datainfo
    implicit none
    character(*), intent(in) :: name
    class(*), intent(in) :: val
    character(len=256), intent(out) :: msg
    integer :: ierr, mval
    integer :: exp_dtyp
    ierr = 0
    mval = 999  !! whatever, just not equal to any ARTN_DTYPE_*
    exp_dtyp = get_artn_dtype( trim(name) )
    select type( val )
    type is( integer )
       if( exp_dtyp /= ARTN_DTYPE_INT ) mval = ARTN_DTYPE_INT
    type is( real )
       if( exp_dtyp /= ARTN_DTYPE_REAL ) mval = ARTN_DTYPE_REAL
    type is( real(DP) )
       if( exp_dtyp /= ARTN_DTYPE_REAL ) mval = ARTN_DTYPE_REAL
    type is( logical )
       if( exp_dtyp /= ARTN_DTYPE_BOOL ) mval = ARTN_DTYPE_BOOL
    type is( character(*) )
       if( exp_dtyp /= ARTN_DTYPE_STR ) mval = ARTN_DTYPE_STR
    class default
       ierr = -9
    end select

    if( ierr == -9 ) then
       write(*,*) "SEVERE ERROR IN CHECK_DTYP, class(*) type unknown!"
       call merr(__FILE__,__LINE__,kill=.true.)
    end if

    if( mval /= 999 ) then
       msg = "wrong datatype for name: "//trim(name)//&
            ". Expected: "//trim(get_dtype_str(exp_dtyp))//&
            "; got: "//trim(get_dtype_str(mval))//". Check variable name?"
       ierr = ERR_DTYPE
    end if
  end function check_dtyp

  function check_drank( name, got_rank, msg )result(ierr)
    use m_datainfo
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: got_rank !! the rank of input
    character(len=256), intent(out) :: msg
    integer :: ierr
    integer :: artn_rank
    ierr = 0
    msg=""
    !! get rank of artn variable
    artn_rank = get_artn_drank(trim(name))
    if( artn_rank /= got_rank ) then
       ierr = -1
       write(msg, "(a,1x,a,a,1x,i0,1x,a,1x,i0)") &
            "Wrong datarank for name:",trim(name),". Expected:", artn_rank, "; got:", got_rank
    end if

  end function check_drank
  !> @endcond


  !! dump_input

  !! serialize

  !! read_generated



end module artn_api2
