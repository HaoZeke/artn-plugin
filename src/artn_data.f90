module artn_data

  use units, only: DP
  !! datatypes
  integer, parameter, public :: &
       ARTN_DTYPE_UNKNOWN = -1, &
       ARTN_DTYPE_INT     = 0, &
       ARTN_DTYPE_REAL    = 1, &
       ARTN_DTYPE_BOOL    = 2, &
       ARTN_DTYPE_STR     = 3
  !! err codes
  integer, parameter, public :: &
       ARTN_ERR_EIGVAL_LOST = -2, &
       ARTN_ERR_SETUP       = -3, &
       ARTN_ERR_FILL_PARAM  = -4

  !! this type contains copies of all data that can be exchanged with pARTn,
  !! coming from another application which calls pARTn as library (ineractive).
  type :: t_artn_data

     !! input parameters
     integer :: &
          ninit, &
          nevalf_max, &
          lanczos_max_size, &
          lanczos_min_size, &
          neigen, &
          nperp, &
          nsmooth, &
          verbose, &
          zseed, &
          nnewchance, &
          nrelax_print, &
          restart_freq

     real(DP) :: &
          push_dist_thr, &
          forc_thr, &
          eigval_thr, &
          frelax_ene_thr, &
          delr_thr, &
          lanczos_eval_conv_thr, &
          etot_diff_limit, &
          push_step_size, &
          push_step_size_per_atom, &
          lanczos_disp, &
          eigen_step_size, &
          current_step_size, &
          push_over
     
     !! logicals are stored as integers with 3 possible values:
     !! value 1 represents .true.
     !! value 0 represents .false.
     !! value -1 represents undefined variable
     !! logical :: &
     integer :: &
          lrestart, &
          lrelax, &
          lpush_final, &
          lmove_nextmin, &
          lnperp_limitation, &
          lanczos_at_min, &
          lanczos_always_random
     

     integer, allocatable :: &
          nperp_limitation(:), &
          push_ids(:)

     real(DP), allocatable :: &
          push_add_const(:,:)
     !! need also: push_init


     character(:), allocatable :: &
          push_mode, &
          engine_units, &
          struc_format_out, &
          push_guess, &
          eigenvec_guess, &
          filout, &
          filin, &
          sadfname, &
          initpfname, &
          eigenfname, &
          restartfname, &
          converge_property, &
          prefix_min, &
          prefix_sad


     !! generated data

     ! integer ::
     ! real(DP) ::
     ! real(DP), allocatable ::
     ! integer, allocatable ::
     ! logical ::
     ! character(:), allocatable ::

     logical :: &
          has_error, &
          has_sad, &
          has_min1, &
          has_min2

     integer :: &
          err_code, &
          nevalf, &
          inewchance, &
          nat

     real(DP) :: &
          energy_init, &
          energy_latest, &
          energy_min1, &
          energy_min2, &
          energy_sad, &
          delr_init, &
          delr_latest, &
          delr_min1, &
          delr_min2, &
          delr_sad, &
          eigval_min1, &
          eigval_min2, &
          eigval_sad, &
          eigval_latest

     integer, allocatable :: &
          typ_latest(:), &
          typ_init(:), &
          typ_min1(:), &
          typ_min2(:), &
          typ_sad(:)

     real(DP), dimension(3,3) :: &
          lat

     real(DP), allocatable :: &
          coords_latest(:,:), &
          coords_init(:,:), &
          coords_min1(:,:), &
          coords_min2(:,:), &
          coords_sad(:,:)


   contains
     procedure :: get_datatype => t_artn_get_datatype
     procedure :: get_datarank => t_artn_get_datarank
     procedure :: get_datasize => t_artn_get_datasize
     procedure :: get_data     => t_artn_get_dataval
     procedure :: dump_input   => t_artn_dump_input
     procedure, private :: &
          set_data_int, set_data_real, set_data_logical, set_data_string, &
          set_data_int1d, set_data_int2d, set_data_real1d, set_data_real2d
     generic :: set_data       => &
          set_data_int, set_data_real, set_data_logical, set_data_string, &
          set_data_int1d, set_data_int2d, set_data_real1d, set_data_real2d
     ! procedure :: save_current_data  => t_artn_save_current_data
     final :: t_artn_data_destroy
  end type t_artn_data

  interface t_artn_data
     procedure t_artn_data_constructor
  end interface t_artn_data

contains

  !! allocate new t_artn_data pointer.
  !! The name is overloaded by type name.
  !! call as:
  !!
  !! type( t_artn_data ), pointer :: artn_data_ptr
  !!
  !! artn_data_ptr => t_artn_data()
  !!
  function t_artn_data_constructor()result(this)
    implicit none
    type( t_artn_data ), pointer :: this

    allocate( t_artn_data :: this)

    !! int
    this% ninit = -99
    this% nevalf_max = -99
    this% lanczos_max_size = -99
    this% lanczos_min_size = -99
    this% neigen = -99
    this% nperp = -99
    this% nsmooth = -99
    this% verbose = -99
    this% zseed = -99
    this% nnewchance = -99
    this% nrelax_print = -99
    this% restart_freq = -99

    !! real
    this% forc_thr                = 1e20
    this% push_dist_thr           = 1e20
    this% eigval_thr              = 1e20
    this% frelax_ene_thr          = 1e20
    this% delr_thr                = 1e20
    this% lanczos_eval_conv_thr   = 1e20
    this% etot_diff_limit         = 1e20
    this% push_step_size          = 1e20
    this% push_step_size_per_atom = 1e20
    this% lanczos_disp            = 1e20
    this% eigen_step_size         = 1e20
    this% current_step_size       = 1e20
    this% push_over               = 1e20


    !! integer representing logicals, initialize as undefined:
    this% lanczos_at_min        = -1
    this% lrestart              = -1
    this% lrelax                = -1
    this% lpush_final           = -1
    this% lmove_nextmin         = -1
    this% lnperp_limitation     = -1
    this% lanczos_always_random = -1

    !! output
    this% err_code = 0
    this% has_error = .false.
    this% has_min1 = .false.
    this% has_min2 = .false.
    this% has_sad = .false.
    this% eigval_min1 = 1e20
    this% eigval_min2 = 1e20
    this% eigval_sad = 1e20
    this% eigval_latest = 1e20
  end function t_artn_data_constructor

  subroutine t_artn_data_destroy( self )
    implicit none
    type( t_artn_data ), intent(inout) :: self

    if( allocated(self% nperp_limitation)) deallocate( self% nperp_limitation )
    if( allocated(self% push_ids)) deallocate( self% push_ids )
    if( allocated(self% push_add_const)) deallocate( self% push_add_const )

    !! strings
    if( allocated( self% push_mode))deallocate( self% push_mode )
    if( allocated( self% engine_units))deallocate( self% engine_units )
    if( allocated( self% struc_format_out))deallocate( self% struc_format_out )
    if( allocated( self% push_guess))deallocate( self% push_guess )
    if( allocated( self% eigenvec_guess))deallocate( self% eigenvec_guess )
    if( allocated( self% filout))deallocate( self% filout )
    if( allocated( self% filin))deallocate( self% filin )
    if( allocated( self% sadfname))deallocate( self% sadfname )
    if( allocated( self% initpfname))deallocate( self% initpfname )
    if( allocated( self% eigenfname))deallocate( self% eigenfname )
    if( allocated( self% restartfname))deallocate( self% restartfname )
    if( allocated( self% converge_property))deallocate( self% converge_property )
    if( allocated( self% prefix_min))deallocate( self% prefix_min )
    if( allocated( self% prefix_sad))deallocate( self% prefix_sad )

    !! generated data
    if( allocated( self% typ_latest   )) deallocate( self% typ_latest )
    if( allocated( self% coords_latest)) deallocate( self% coords_latest )

    if( allocated( self% typ_init     )) deallocate( self% typ_init )
    if( allocated( self% coords_init  )) deallocate( self% coords_init )

    if( allocated( self% typ_min1     )) deallocate( self% typ_min1 )
    if( allocated( self% coords_min1  )) deallocate( self% coords_min1 )

    if( allocated( self% typ_min2     )) deallocate( self% typ_min2 )
    if( allocated( self% coords_min2  )) deallocate( self% coords_min2 )

    if( allocated( self% typ_sad      )) deallocate( self% typ_sad )
    if( allocated( self% coords_sad   )) deallocate( self% coords_sad )

  end subroutine t_artn_data_destroy


  function t_artn_get_datatype( self, name )result( dtype )
    !! if desired data is not present in memory, give result
    !! of expected datatype for this variable name
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer :: dtype
    select case( name )
    case( &
         "ninit", &
         "nevalf_max", &
         "lanczos_max_size", &
         "lanczos_min_size", &
         "neigen", &
         "nperp", &
         "nsmooth", &
         "verbose", &
         "zseed", &
         "nnewchance", &
         "nrelax_print", &
         "restart_freq", &

         "nperp_limitation", &

         "err_code", "nevalf", "nat", "inewchance", &
         "typ_init", "typ_latest", "typ_min1", "typ_min2", "typ_sad" &

         ); dtype = ARTN_DTYPE_INT
    case( &
         "push_dist_thr", &
         "forc_thr", &
         "eigval_thr", &
         "frelax_ene_thr", &
         "delr_thr", &
         "lanczos_eval_conv_thr", &
         "etot_diff_limit", &
         "push_step_size", &
         "push_step_size_per_atom", &
         "lanczos_disp", &
         "eigen_step_size", &
         "current_step_size", &
         "push_over", &
         "lat", &
         "energy_init", "energy_latest", "energy_min1", "energy_min2", "energy_sad", &
         "delr_init", "delr_latest", "delr_min1", "delr_min2", "delr_sad", &
         "eigval_min1", "eigval_min2", "eigval_sad", "eigval_latest", &
         "coords_init", "coords_latest", "coords_min1", "coords_min2", "coords_sad" &
         ); dtype = ARTN_DTYPE_REAL
    case( &
         "lrestart", &
         "lrelax", &
         "lpush_final", &
         "lmove_nextmin", &
         "lnperp_limitation", &
         "lanczos_at_min", &
         "lanczos_always_random", &
         "has_error", "has_sad", "has_min1", "has_min2" &
       ); dtype = ARTN_DTYPE_BOOL
    case( &
         "push_mode", &
         "engine_units", &
         "struc_format_out", &
         "push_guess", &
         "eigenvec_guess", &
         "filout", &
         "filin", &
         "sadfname", &
         "initpfname", &
         "eigenfname", &
         "restartfname", &
         "converge_property", &
         "prefix_min", &
         "prefix_sad" &
         ); dtype = ARTN_DTYPE_STR
    case default
       !! unknown name
       dtype = ARTN_DTYPE_UNKNOWN
    end select
  end function t_artn_get_datatype

  function t_artn_get_datarank( self, name )result( drank )
    !! if desired data is not present in memory, give result
    !! of expected datarank for this variable name
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer :: drank
    select case( name )
    case( &
                                !! int
         "ninit", &
         "nevalf_max", &
         "lanczos_max_size", &
         "lanczos_min_size", &
         "neigen", &
         "nperp", &
         "nsmooth", &
         "verbose", &
         "zseed", &
         "nnewchance", &
         "nrelax_print", &
         "restart_freq", &
                                !! real
         "push_dist_thr", &
         "forc_thr", &
         "eigval_thr", &
         "frelax_ene_thr", &
         "delr_thr", &
         "lanczos_eval_conv_thr", &
         "etot_diff_limit", &
         "push_step_size", &
         "push_step_size_per_atom", &
         "lanczos_disp", &
         "eigen_step_size", &
         "current_step_size", &
         "push_over", &
                                !! logical
         "lrestart", &
         "lrelax", &
         "lpush_final", &
         "lmove_nextmin", &
         "lnperp_limitation", &
         "lanczos_at_min", &
         "lanczos_always_random", &
                                !! str
         "push_mode", &
         "engine_units", &
         "struc_format_out", &
         "push_guess", &
         "eigenvec_guess", &
         "filout", &
         "filin", &
         "sadfname", &
         "initpfname", &
         "eigenfname", &
         "restartfname", &
         "converge_property", &
         "prefix_min", &
         "prefix_sad", &

                                !! generated
         "err_code", &
         "nevalf", &
         "nat", &
         "inewchance", &
         "energy_init", "energy_latest", "energy_min1", "energy_min2", "energy_sad", &
         "delr_init", "delr_latest", "delr_min1", "delr_min2", "delr_sad", &
         "eigval_min1", "eigval_min2", "eigval_sad", "eigval_latest", &
         "has_error", "has_sad", "has_min1", "has_min2" &
         ); drank = 0

    case( &
         !! int 1D
         "nperp_limitation", &
         "push_ids", &

         !! str
         ! "push_mode", &
         ! "engine_units", &
         ! "struc_format_out", &
         ! "push_guess", &
         ! "eigenvec_guess", &
         ! "filout", &
         ! "filin", &
         ! "sadfname", &
         ! "initpfname", &
         ! "eigenfname", &
         ! "restartfname", &
         ! "converge_property", &
         ! "prefix_min", &
         ! "prefix_sad" &

         !! generated
         "typ_latest", "typ_init", "typ_min1", "typ_min2", "typ_sad" &
         ); drank = 1

    case( &
         !! real 2D
         "lat", &
         "coords_init", "coords_latest", "coords_min1", "coords_min2", "coords_sad" &
         ); drank = 2

    case default
       !! unknown name
       drank = -1
    end select
  end function t_artn_get_datarank

  function t_artn_get_datasize( self, name, dsize )result( ierr )
    !! return c_ptr to array containing number of elements along
    !! each rank (dimension) of data which is present in memory.
    !! If data is not set, return nonnegative ierr.
    use iso_c_binding, only: c_ptr, c_null_ptr, c_loc
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer, allocatable, intent(out) :: dsize(:)
    integer :: ierr
    integer :: drank

    ierr = -1
    drank = self% get_datarank(name)

    !! error in rank
    if( drank < 0 ) return

    allocate( dsize(1:drank), source=0 )
    ierr = 0

    !! rank 0 have no size
    if( drank == 0 ) return

    select case( name )
       !    !! rank 0
       ! case( 'ninit' )
       !    ierr = 0
    case( "nperp_limitation" ); dsize(1) = size_i1d_local( self% nperp_limitation )

    !! strings: return their length
    ! case( "push_mode" ); dsize(1) = lenstr_local( self% push_mode )
    ! case( "engine_units" ); dsize(1) = lenstr_local( self% engine_units )
    ! case( "struc_format_out" ); dsize(1) = lenstr_local( self% struc_format_out )
    ! case( "push_guess" ); dsize(1) = lenstr_local( self% push_guess )
    ! case( "eigenvec_guess" ); dsize(1) = lenstr_local( self% eigenvec_guess )
    ! case( "filout" ); dsize(1) = lenstr_local( self% filout )
    ! case( "filin" ); dsize(1) = lenstr_local( self% filin )
    ! case( "sadfname" ); dsize(1) = lenstr_local( self% sadfname )
    ! case( "initpfname" ); dsize(1) = lenstr_local( self% initpfname )
    ! case( "eigenfname" ); dsize(1) = lenstr_local( self% eigenfname )
    ! case( "restartfname" ); dsize(1) = lenstr_local( self% restartfname )
    ! case( "converge_property" ); dsize(1) = lenstr_local( self% converge_property )
    ! case( "prefix_min" ); dsize(1) = lenstr_local( self% prefix_min )
    ! case( "prefix_sad" ); dsize(1) = lenstr_local( self% prefix_sad )

    case( "typ_init" ); dsize(1) = size_i1d_local( self% typ_init )
    case( "typ_latest" ); dsize(1) = size_i1d_local( self% typ_latest )
    case( "typ_min1" ); dsize(1) = size_i1d_local( self% typ_min1 )
    case( "typ_min2" ); dsize(1) = size_i1d_local( self% typ_min2 )
    case( "typ_sad" ); dsize(1) = size_i1d_local( self% typ_sad )

    case( "lat" ); dsize(1) = 3; dsize(2) = 3
    case( "coords_init" )
       dsize(1) = size_r2d_local( self% coords_init, 1)
       dsize(2) = size_r2d_local( self% coords_init, 2)
    case( "coords_latest" )
       dsize(1) = size_r2d_local( self% coords_latest, 1)
       dsize(2) = size_r2d_local( self% coords_latest, 2)
    case( "coords_min1" )
       dsize(1) = size_r2d_local( self% coords_min1, 1)
       dsize(2) = size_r2d_local( self% coords_min1, 2)
    case( "coords_min2" )
       dsize(1) = size_r2d_local( self% coords_min2, 1)
       dsize(2) = size_r2d_local( self% coords_min2, 2)
    case( "coords_sad" )
       dsize(1) = size_r2d_local( self% coords_sad, 1)
       dsize(2) = size_r2d_local( self% coords_sad, 2)

    case default
       !! some different error
       ierr = -2
    end select
  end function t_artn_get_datasize

  function t_artn_get_dataval( self, name )result( dval )
    !! return C_ptr to desired data value. If data does not exist,
    !! or is not allocated, return null pointer
    use iso_c_binding, only: c_ptr, c_null_ptr, c_int, c_double, c_bool, c_loc
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    type( c_ptr ) :: dval
    integer, pointer :: iptr, i1ptr(:)
    real( c_double ), pointer :: rptr, r2ptr(:,:)
    logical( c_bool ), pointer :: lptr

    dval = c_null_ptr
    select case( name )
       !! input vars, rank-0 INT
    case( "ninit" )
       allocate( iptr, source = int(self% ninit,c_int) ); dval = c_loc( iptr )
    case( "nevalf_max" )
       allocate( iptr, source = int(self% nevalf_max,c_int) ); dval = c_loc( iptr )
    case( "lanczos_max_size" )
       allocate( iptr, source = int(self% lanczos_max_size,c_int) ); dval = c_loc( iptr )
    case( "lanczos_min_size" )
       allocate( iptr, source = int(self% lanczos_min_size,c_int) ); dval = c_loc( iptr )
    case( "neigen" )
       allocate( iptr, source = int(self% neigen,c_int) ); dval = c_loc( iptr )
    case( "nperp" )
       allocate( iptr, source = int(self% nperp,c_int) ); dval = c_loc( iptr )
    case( "nsmooth" )
       allocate( iptr, source = int(self% nsmooth,c_int) ); dval = c_loc( iptr )
    case( "verbose" )
       allocate( iptr, source = int(self% verbose,c_int) ); dval = c_loc( iptr )
    case( "zseed" )
       allocate( iptr, source = int(self% zseed,c_int) ); dval = c_loc( iptr )
    case( "nnewchance" )
       allocate( iptr, source = int(self% nnewchance,c_int) ); dval = c_loc( iptr )
    case( "nrelax_print" )
       allocate( iptr, source = int(self% nrelax_print,c_int) ); dval = c_loc( iptr )

       !! rank-0 REAL

       !! rank-1 INT
    case( 'nperp_limitation' )
       if( .not. allocated( self% nperp_limitation) ) return
       allocate( i1ptr, source = int(self% nperp_limitation,c_int) ); dval = c_loc( i1ptr(1) )

       !! generated data
    case( "has_error" )
       allocate( lptr, source = logical(self% has_error, c_bool) ); dval = c_loc( lptr )
    case( "has_sad" )
       allocate( lptr, source = logical(self% has_sad, c_bool) ); dval = c_loc( lptr )
    case( "has_min1" )
       allocate( lptr, source = logical(self% has_min1, c_bool) ); dval = c_loc( lptr )
    case( "has_min2" )
       allocate( lptr, source = logical(self% has_min2, c_bool) ); dval = c_loc( lptr )

    case( "err_code" )
       allocate( iptr, source = int(self% err_code, c_int) ); dval = c_loc( iptr )
    case( "nevalf" )
       allocate( iptr, source = int(self% nevalf, c_int) ); dval = c_loc( iptr )
    case( "nat" )
       allocate( iptr, source = int(self% nat, c_int) ); dval = c_loc( iptr )
    case( "inewchance" )
       allocate( iptr, source = int(self% inewchance, c_int) ); dval = c_loc( iptr )

    case( "energy_init" )
       allocate( rptr, source = real( self% energy_init, c_double )); dval = c_loc(rptr)
    case( "energy_latest" )
       allocate( rptr, source = real( self% energy_latest, c_double )); dval = c_loc(rptr)
    case( "energy_min1" )
       allocate( rptr, source = real( self% energy_min1, c_double )); dval = c_loc(rptr)
    case( "energy_min2" )
       allocate( rptr, source = real( self% energy_min2, c_double )); dval = c_loc(rptr)
    case( "energy_sad" )
       allocate( rptr, source = real( self% energy_sad, c_double )); dval = c_loc(rptr)

    case( "delr_init" )
       allocate( rptr, source = real( self% delr_init, c_double )); dval = c_loc(rptr)
    case( "delr_latest" )
       allocate( rptr, source = real( self% delr_latest, c_double )); dval = c_loc(rptr)
    case( "delr_min1" )
       allocate( rptr, source = real( self% delr_min1, c_double )); dval = c_loc(rptr)
    case( "delr_min2" )
       allocate( rptr, source = real( self% delr_min2, c_double )); dval = c_loc(rptr)
    case( "delr_sad" )
       allocate( rptr, source = real( self% delr_sad, c_double )); dval = c_loc(rptr)

    case( "eigval_latest" )
       allocate( rptr, source = real( self% eigval_latest, c_double )); dval = c_loc(rptr)
    case( "eigval_min1" )
       allocate( rptr, source = real( self% eigval_min1, c_double )); dval = c_loc(rptr)
    case( "eigval_min2" )
       allocate( rptr, source = real( self% eigval_min2, c_double )); dval = c_loc(rptr)
    case( "eigval_sad" )
       allocate( rptr, source = real( self% eigval_sad, c_double )); dval = c_loc(rptr)

    case( "typ_latest" )
       if( .not. allocated( self% typ_latest) ) return
       allocate( i1ptr, source = int(self% typ_latest,c_int)); dval = c_loc( i1ptr(1) )
    case( "typ_init" )
       if( .not. allocated( self% typ_init) ) return
       allocate( i1ptr, source = int(self% typ_init,c_int)); dval = c_loc( i1ptr(1) )
    case( "typ_min1" )
       if( .not. allocated( self% typ_min1) ) return
       allocate( i1ptr, source = int(self% typ_min1,c_int)); dval = c_loc( i1ptr(1) )
    case( "typ_min2" )
       if( .not. allocated( self% typ_min2) ) return
       allocate( i1ptr, source = int(self% typ_min2,c_int)); dval = c_loc( i1ptr(1) )
    case( "typ_sad" )
       if( .not. allocated( self% typ_sad) ) return
       allocate( i1ptr, source = int(self% typ_sad,c_int)); dval = c_loc( i1ptr(1) )

    case( "lat" )
       allocate( r2ptr, source = real( self% lat, c_double )); dval = c_loc( r2ptr(1,1) )

    case( "coords_init" )
       if( .not. allocated(self% coords_init) ) return
       allocate( r2ptr, source = real(self% coords_init, c_double) ); dval = c_loc( r2ptr(1,1) )
    case( "coords_latest" )
       if( .not. allocated(self% coords_latest) ) return
       allocate( r2ptr, source = real(self% coords_latest, c_double) ); dval = c_loc( r2ptr(1,1) )
    case( "coords_min1" )
       if( .not. allocated(self% coords_min1) ) return
       allocate( r2ptr, source = real(self% coords_min1, c_double) ); dval = c_loc( r2ptr(1,1) )
    case( "coords_min2" )
       if( .not. allocated(self% coords_min2) ) return
       allocate( r2ptr, source = real(self% coords_min2, c_double) ); dval = c_loc( r2ptr(1,1) )
    case( "coords_sad" )
       if( .not. allocated(self% coords_sad) ) return
       allocate( r2ptr, source = real(self% coords_sad, c_double) ); dval = c_loc( r2ptr(1,1) )

    end select


  end function t_artn_get_dataval


  function set_data_int( self, name, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "ninit"            ); self% ninit = int( val )
    case( "nevalf_max"       ); self% nevalf_max = int( val )
    case( "lanczos_max_size" ); self% lanczos_max_size = int( val )
    case( "lanczos_min_size" ); self% lanczos_min_size = int( val )
    case( "neigen"           ); self% neigen = int( val )
    case( "nperp"            ); self% nperp = int( val )
    case( "nsmooth"          ); self% nsmooth = int( val )
    case( "verbose"          ); self% verbose = int( val )
    case( "zseed"            ); self% zseed = int( val )
    case( "nnewchance"       ); self% nnewchance = int( val )
    case( "nrelax_print"     ); self% nrelax_print = int( val )
    case default;            ierr = -1
    end select
  end function set_data_int
  function set_data_int1d( self, name, dim, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    integer, dimension(dim), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "nperp_limitation" )
       !! if already exists, overwrite with new
       if( allocated(self% nperp_limitation) ) deallocate( self% nperp_limitation )
       allocate( self% nperp_limitation, source = int(val) )
    case default; ierr = -1
    end select
  end function set_data_int1d
  function set_data_int2d( self, name, dim1, dim2, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer, intent(in) :: dim1, dim2
    integer, dimension(dim1, dim2), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    ! case( "some_int2d_var" )
    !    !! if already exists, overwrite with new
    !    if( size(var, 1) ... )
    !    if( allocated(self% var) ) deallocate( self% var )
    !    allocate( self% var, source = int(val) )
    case default; ierr = -1
    end select
  end function set_data_int2d
  function set_data_real( self, name, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    real, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "forc_thr" ); self% forc_thr = real( val )
    case( "push_dist_thr" ); self% push_dist_thr = real( val )
    case( "eigval_thr" ); self% eigval_thr = real( val )
    case( "frelax_ene_thr" ); self% frelax_ene_thr = real( val )
    case( "delr_thr" ); self% delr_thr = real( val )
    case( "lanczos_eval_conv_thr" ); self% lanczos_eval_conv_thr = real( val )
    case( "etot_diff_limit" ); self% etot_diff_limit = real( val )
    case( "push_step_size" ); self% push_step_size = real( val )
    case( "push_step_size_per_atom" ); self% push_step_size_per_atom = real( val )
    case( "lanczos_disp" ); self% lanczos_disp = real( val )
    case( "eigen_step_size" ); self% eigen_step_size = real( val )
    case( "current_step_size" ); self% current_step_size = real( val )
    case( "push_over" ); self% push_over = real( val )
    case default; ierr = -1
    end select
  end function set_data_real
  function set_data_real1d( self, name, dim, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    real, dimension(dim), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    ! case( "var" )
    !    if( allocated( self% var)) deallocate( self% var )
    !    allocate( self% var, source = real(val) )
    case default; ierr = -1
    end select
  end function set_data_real1d
  function set_data_real2d( self, name, dim1, dim2, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    integer, intent(in) :: dim1, dim2
    real, dimension(dim1, dim2), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
       ! case( "var" )
       !    if( allocated( self% var)) deallocate( self% var )
       !    allocate( self% var, source = real(val) )
    case default; ierr = -1
    end select
  end function set_data_real2d
  function set_data_logical( self, name, val ) result( ierr )
    !! logical input is stored as integers:
    !! val = .false. is stored as integer 0
    !! val = .true. is stored as integer 1
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    logical, intent(in) :: val
    integer :: ierr
    integer :: ival
    ierr = 0
    ival = 0
    if( val ) ival = 1
    select case( name )
    case( "lrestart"              ); self% lrestart = ival
    case( "lrelax"                ); self% lrelax = ival
    case( "lpush_final"           ); self% lpush_final = ival
    case( "lmove_nextmin"         ); self% lmove_nextmin = ival
    case( "lnperp_limitation"     ); self% lnperp_limitation = ival
    case( "lanczos_at_min"        ); self% lanczos_at_min = ival
    case( "lanczos_always_random" ); self% lanczos_always_random = ival
    case default;                 ierr = -1
    end select
  end function set_data_logical
  function set_data_string( self, name, val )result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    ! case( "prefix_sad" )
    !    if( allocated(self% prefix_sad        )) deallocate( self% prefix_sad )
    !    allocate( self% prefix_sad        , source = trim(val) )

    ! case( "push_mode" )
    !    if( allocated( self% push_mode        ))deallocate( self% push_mode )
    !    allocate( self% push_mode         , source = trim(val) )

    ! case( "engine_units" )
    !    if( allocated( self% engine_units     ))deallocate( self% engine_units )
    !    allocate( self% engine_units      , source = trim(val) )

    ! case( "struc_format_out" )
    !    if( allocated( self% struc_format_out ))deallocate( self% struc_format_out )
    !    allocate( self% struc_format_out  , source = trim(val) )

    ! case( "push_guess" )
    !    if( allocated( self% push_guess       ))deallocate( self% push_guess )
    !    allocate( self% push_guess        , source = trim(val) )

    ! case( "eigenvec_guess" )
    !    if( allocated( self% eigenvec_guess   ))deallocate( self% eigenvec_guess )
    !    allocate( self% eigenvec_guess    , source = trim(val) )

    ! case( "filout" )
    !    if( allocated( self% filout           ))deallocate( self% filout )
    !    allocate( self% filout            , source = trim(val) )

    ! case( "filin" )
    !    if( allocated( self% filin            ))deallocate( self% filin )
    !    allocate( self% filin             , source = trim(val) )

    ! case( "sadfname" )
    !    if( allocated( self% sadfname         ))deallocate( self% sadfname )
    !    allocate( self% sadfname          , source = trim(val) )

    ! case( "initpfname" )
    !    if( allocated( self% initpfname       ))deallocate( self% initpfname )
    !    allocate( self% initpfname        , source = trim(val) )

    ! case( "eigenfname" )
    !    if( allocated( self% eigenfname       ))deallocate( self% eigenfname )
    !    allocate( self% eigenfname        , source = trim(val) )

    ! case( "restartfname" )
    !    if( allocated( self% restartfname     ))deallocate( self% restartfname )
    !    allocate( self% restartfname      , source = trim(val) )

    ! case( "converge_property" )
    !    if( allocated( self% converge_property))deallocate( self% converge_property )
    !    allocate( self% converge_property , source = trim(val) )

    ! case( "prefix_min" )
    !    if( allocated( self% prefix_min       ))deallocate( self% prefix_min )
    !    allocate( self% prefix_min        , source = trim(val) )


    case( "prefix_sad"         ); call local_set_str( self% prefix_sad        , val )
    case( "push_mode"          ); call local_set_str( self% push_mode         , val )
    case( "engine_units"       ); call local_set_str( self% engine_units      , val )
    case( "struc_format_out"   ); call local_set_str( self% struc_format_out  , val )
    case( "push_guess"         ); call local_set_str( self% push_guess        , val )
    case( "eigenvec_guess"     ); call local_set_str( self% eigenvec_guess    , val )
    case( "filout"             ); call local_set_str( self% filout            , val )
    case( "filin"              ); call local_set_str( self% filin             , val )
    case( "sadfname"           ); call local_set_str( self% sadfname          , val )
    case( "initpfname"         ); call local_set_str( self% initpfname        , val )
    case( "eigenfname"         ); call local_set_str( self% eigenfname        , val )
    case( "restartfname"       ); call local_set_str( self% restartfname      , val )
    case( "converge_property"  ); call local_set_str( self% converge_property , val )
    case( "prefix_min"         ); call local_set_str( self% prefix_min        , val )



    case default; ierr = -1
    end select
  end function set_data_string




  function t_artn_dump_input( self, fname ) result( ierr )
    implicit none
    class( t_artn_data ), intent(inout) :: self
    character(*), intent(in) :: fname
    integer :: ierr

    character(:), allocatable :: f
    integer :: u0, ios
    integer :: dt(8)

    ierr = 0

    !! rename to some default name
    if( fname == "default_filename" ) then
       allocate( f, source = "artn_tmpinp.in")
    else
       allocate( f, source = fname )
    end if

    open(newunit=u0, file=f, status="replace", iostat=ios )
    if( ios /= 0 ) then
       write(*,*) "PROBLEM WITH OPENING FILE FOR INPUT DUMP:",f
       ierr = -1
       return
    end if

    !! get date and time
    call date_and_time( values = dt )
    !! write the namelist for input manually, since there could be unallocated things ...
    write(u0, *) "!! This input file was written by the function t_artn_data_dump_input(),"
    write(u0, "(1x,a,1x,i0,a1,i0,a1,i0,1x,a,1x,i0.2,a1,i0.2,a1,i0.2//)") "!! launched on:", &
         dt(3),".",dt(2),".",dt(1),"at:",dt(5),":",dt(6),":",dt(7)

    !! begin writing the namelist
    write(u0, *) "&ARTN_PARAMETERS"

    !! check all possible params

    !! if param is defined, print it

    if( self% ninit            .ne. -99 ) write(u0, '(3x,a,1x,i0)') "ninit            =", self% ninit
    if( self% nevalf_max       .ne. -99 ) write(u0, '(3x,a,1x,i0)') "nevalf_max       =", self% nevalf_max
    if( self% lanczos_max_size .ne. -99 ) write(u0, '(3x,a,1x,i0)') "lanczos_max_size =", self% lanczos_max_size
    if( self% lanczos_min_size .ne. -99 ) write(u0, '(3x,a,1x,i0)') "lanczos_min_size =", self% lanczos_min_size
    if( self% neigen           .ne. -99 ) write(u0, '(3x,a,1x,i0)') "neigen           =", self% neigen
    if( self% nperp            .ne. -99 ) write(u0, '(3x,a,1x,i0)') "nperp            =", self% nperp
    if( self% nsmooth          .ne. -99 ) write(u0, '(3x,a,1x,i0)') "nsmooth          =", self% nsmooth
    if( self% verbose          .ne. -99 ) write(u0, '(3x,a,1x,i0)') "verbose          =", self% verbose
    if( self% zseed            .ne. -99 ) write(u0, '(3x,a,1x,i0)') "zseed            =", self% zseed
    if( self% nnewchance       .ne. -99 ) write(u0, '(3x,a,1x,i0)') "nnewchance       =", self% nnewchance
    if( self% nrelax_print     .ne. -99 ) write(u0, '(3x,a,1x,i0)') "nrelax_print     =", self% nrelax_print
    if( self% restart_freq     .ne. -99 ) write(u0, '(3x,a,1x,i0)') "restart_freq     =", self% restart_freq


    if( .not.(self% forc_thr                > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "forc_thr                =", self% forc_thr
    if( .not.(self% push_dist_thr           > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "push_dist_thr           =", self% push_dist_thr
    if( .not.(self% eigval_thr              > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "eigval_thr              =", self% eigval_thr
    if( .not.(self% frelax_ene_thr          > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "frelax_ene_thr          =", self% frelax_ene_thr
    if( .not.(self% delr_thr                > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "delr_thr                =", self% delr_thr
    if( .not.(self% lanczos_eval_conv_thr   > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "lanczos_eval_conv_thr   =", self% lanczos_eval_conv_thr
    if( .not.(self% etot_diff_limit         > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "etot_diff_limit         =", self% etot_diff_limit
    if( .not.(self% push_step_size          > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "push_step_size          =", self% push_step_size
    if( .not.(self% push_step_size_per_atom > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "push_step_size_per_atom =", self% push_step_size_per_atom
    if( .not.(self% lanczos_disp            > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "lanczos_disp            =", self% lanczos_disp
    if( .not.(self% eigen_step_size         > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "eigen_step_size         =", self% eigen_step_size
    if( .not.(self% push_over               > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "push_over               =", self% push_over
    if( .not.(self% current_step_size       > 1e19 ) )&
         write(u0, '(3x,a,1x,g0.6)') "current_step_size       =", self% current_step_size

    if( self% lanczos_at_min        == 0 ) write(u0, "(3x,a)" ) "lanczos_at_min        = .false."
    if( self% lanczos_at_min        == 1 ) write(u0, "(3x,a)" ) "lanczos_at_min        = .true."
    if( self% lrestart              == 0 ) write(u0, "(3x,a)" ) "lrestart              = .false."
    if( self% lrestart              == 1 ) write(u0, "(3x,a)" ) "lrestart              = .true."
    if( self% lrelax                == 0 ) write(u0, "(3x,a)" ) "lrelax                = .false."
    if( self% lrelax                == 1 ) write(u0, "(3x,a)" ) "lrelax                = .true."
    if( self% lpush_final           == 0 ) write(u0, "(3x,a)" ) "lpush_final           = .false."
    if( self% lpush_final           == 1 ) write(u0, "(3x,a)" ) "lpush_final           = .true."
    if( self% lmove_nextmin         == 0 ) write(u0, "(3x,a)" ) "lmove_nextmin         = .false."
    if( self% lmove_nextmin         == 1 ) write(u0, "(3x,a)" ) "lmove_nextmin         = .true."
    if( self% lnperp_limitation     == 0 ) write(u0, "(3x,a)" ) "lnperp_limitation     = .false."
    if( self% lnperp_limitation     == 1 ) write(u0, "(3x,a)" ) "lnperp_limitation     = .true."
    if( self% lanczos_always_random == 0 ) write(u0, "(3x,a)" ) "lanczos_always_random = .false."
    if( self% lanczos_always_random == 1 ) write(u0, "(3x,a)" ) "lanczos_always_random = .true."

    if( allocated( self% prefix_sad       )) &
         write(u0, "(3x,a,a,a)") "prefix_sad        = '", self% prefix_sad,"'"
    if( allocated (self% push_mode        )) &
         write(u0, "(3x,a,a,a)") "push_mode         = '", self% push_mode,"'"
    if( allocated (self% engine_units     )) &
         write(u0, "(3x,a,a,a)") "engine_units      = '", self% engine_units, "'"
    if( allocated (self% struc_format_out )) &
         write(u0, "(3x,a,a,a)") "struc_format_out  = '", self% struc_format_out, "'"
    if( allocated (self% push_guess       )) &
         write(u0, "(3x,a,a,a)") "push_guess        = '", self% push_guess, "'"
    if( allocated (self% eigenvec_guess   )) &
         write(u0, "(3x,a,a,a)") "eigenvec_guess    = '", self% eigenvec_guess, "'"
    if( allocated (self% filout           )) &
         write(u0, "(3x,a,a,a)") "filout            = '", self% filout, "'"
    if( allocated (self% filin            )) &
         write(u0, "(3x,a,a,a)") "filin             = '", self% filin, "'"
    if( allocated (self% sadfname         )) &
         write(u0, "(3x,a,a,a)") "sadfname          = '", self% sadfname, "'"
    if( allocated (self% initpfname       )) &
         write(u0, "(3x,a,a,a)") "initpfname        = '", self% initpfname, "'"
    if( allocated (self% eigenfname       )) &
         write(u0, "(3x,a,a,a)") "eigenfname        = '", self% eigenfname, "'"
    if( allocated (self% restartfname     )) &
         write(u0, "(3x,a,a,a)") "restartfname      = '", self% restartfname, "'"
    if( allocated (self% converge_property)) &
         write(u0, "(3x,a,a,a)") "converge_property = '", self% converge_property, "'"
    if( allocated (self% prefix_min       )) &
         write(u0, "(3x,a,a,a)") "prefix_min        = '", self% prefix_min, "'"


    if( allocated( self% nperp_limitation) ) write(u0, '(3x,a,*(i0,:,",",1x))') &
         "nperp_limitation = ", self% nperp_limitation
    if( allocated( self% push_ids ) ) write(u0,'(3x,a,*(i0,:,",",1x))') &
         "push_ids = ", self% push_ids

    !! this could be moved to file (like push_guess and friends)?
    ! if( allocated( self% push_add_const ) ) 


    write(u0, *) "/"

    close(u0, status="keep" )
    deallocate( f )
  end function t_artn_dump_input


  !! local functions
  !! calling size for unallocated stuff can give undefined (random) result, so wrap them
  function lenstr_local( str )result(l)
    character(:), allocatable, intent(in) :: str
    integer :: l
    l = 0
    if( .not. allocated(str)) return
    l = len_trim( str )
  end function lenstr_local
  function size_i1d_local( i1d )result(l)
    integer, allocatable, intent(in) :: i1d(:)
    integer :: l
    l = 0
    if( .not. allocated(i1d)) return
    l = size( i1d )
  end function size_i1d_local
  function size_i2d_local( i2d, ax )result(l)
    integer, allocatable, intent(in) :: i2d(:,:)
    integer, intent(in) :: ax
    integer :: l
    l = 0
    if( .not. allocated(i2d)) return
    l = size( i2d, ax )
  end function size_i2d_local
  function size_r1d_local( r1d )result(l)
    real(DP), allocatable, intent(in) :: r1d(:)
    integer :: l
    l = 0
    if( .not. allocated(r1d)) return
    l = size( r1d )
  end function size_r1d_local
  function size_r2d_local( r2d, ax )result(l)
    real(DP), allocatable, intent(in) :: r2d(:,:)
    integer, intent(in) :: ax
    integer :: l
    l = 0
    if( .not. allocated(r2d)) return
    l = size( r2d, ax )
  end function size_r2d_local

  subroutine local_set_str( str, val )
    character(:), allocatable, intent(inout) :: str
    character(*), intent(in) :: val
    if( allocated( str ) ) deallocate( str )
    allocate( str, source = val )
  end subroutine local_set_str



end module artn_data
