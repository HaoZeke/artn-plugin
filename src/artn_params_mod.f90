!
!! Group definition for all the code
!
!> @defgroup ARTn ARTn algorithm
!>    Main routine of the ARTn algorithm
!>
!> @defgroup Control Routine Control
!>    Routine allows to control the work flow
!>
!> @defgroup Block ARTn block
!>    Computation block
!>
!> @defgroup Interface Routine Interface
!>    Interface with E/F engine
!>



!> @author Matic Poberznik
!! @author Miha Gunde
!! @author Nicolas Salles
!! @author Antoine Jay
!
!8888> @namespace artn_params
!
!> @brief
  !!  This module contains the variables accessible from the input, and
  !! the runtime variables (flags, counters, push, eigenvec) used in the ARTn plugin
!
!> @ingroup ARTn
!
MODULE artn_params
  !
  ! use artn_data, only: t_artn_data
  USE precision, ONLY : DP
  use units, only: NAN_INT, NAN_REAL, NAN_STR, CALLER_IS_ENGINE
  IMPLICIT NONE


  !!=========
  !! all variables in this module have attribute SAVE

  SAVE

  !!=========





  !!===========================
  !! variables accessible to user
  !!===========================


  !! all should be initialised with a value already here

  !!---------------------
  !! integer do not need conversion, can be initialised to default value directly
  INTEGER :: verbose          = 2       !< @brief Verbose Level
  INTEGER :: zseed            = 0       !< @brief random number generator seed
  INTEGER :: nperp            = -1      !< @brief number of perp-relax iterations to perform
  INTEGER :: nevalf_max       = NAN_INT !< @brief max nr steps. Must be < max_step of the F engine to have an effect
  INTEGER :: ninit            = 3       !< @brief number of initial pushes before lanczos start
  INTEGER :: neigen           = 1       !< @brief number of steps made with eigenvector before perp relax
  INTEGER :: lanczos_max_size = 16 !< @brief size of the lanczos tridiagonal matrix
  INTEGER :: lanczos_min_size = 3  !< @brief minimal size of lanzos matrix (use with care)
  INTEGER :: nsmooth          = 0  !< @brief number of smoothing steps from push to eigenvec
  INTEGER :: nnewchance       = 0  !< @brief number of new attemps after loosing eigenvalue
  INTEGER :: nrelax_print     = 5  !< @brief print at every nrelax step
  INTEGER :: restart_freq     = 0  !< @brief Frequency to write the restart_file: 0=never, 1=every step, 2=macro step
  !!---------------------


  !! default value definitions in ARTn internal units
  REAL(DP), PARAMETER :: &
       def_push_dist_thr           = 0.0_DP,     &
       def_delr_thr                = 0.1_DP,     &
       def_forc_thr                = 0.001_DP,   &
       def_alpha_mix_cr            = 0.2_DP,     &
       def_eigval_thr              = -0.01_DP,   &
       def_push_step_size          = 0.4_DP,     &
       def_push_step_size_per_atom = 0.2_DP,     &
       def_eigen_step_size         = 0.4_DP,     &
       def_lanczos_disp            = 0.01_DP,    &
       def_lanczos_eval_conv_thr   = 0.01_DP,    &
       def_etot_diff_limit         = 80.0_DP

  INTEGER :: def_nperp_limitation(5) = [ 4, 8, 12, 16, -1 ] !< @brief  default values for nperp limitation evolution



  !!---------------------
  !! real that do not need conversion, initialise directly to default value
  REAL(DP) :: push_dist_thr = def_push_dist_thr !< @brief distance threshold for push mode "rad"
  REAL(DP) :: delr_thr      = def_delr_thr      !< @brief length Threshold to consider an atomic has moved
  REAL(DP) :: push_over     = 1.0_DP            !< @brief EigenVec fraction Push_over the saddle point for the relax
  REAL(DP) :: alpha_mix_cr  = def_alpha_mix_cr  !< @brief Mixing coeff used into convex region
  REAL(DP) :: lanczos_eval_conv_thr = def_lanczos_eval_conv_thr !< @brief threshold for convergence of eigenvalue in Lanczos
  !!---------------------




  !!---------------------
  !! real that need conversion, need to detect when undefined, to properly convert later,
  !! so initialize to NAN_REAL
  REAL(DP) :: forc_thr                = NAN_REAL !< @brief force criterion for the saddle point
  REAL(DP) :: eigval_thr              = NAN_REAL !< @brief threshold for eigenvalue
  REAL(DP) :: etot_diff_limit         = NAN_REAL !< @brief limit for energy difference, if above exit the research
  REAL(DP) :: push_step_size          = NAN_REAL !< @brief step size of inital push in units of positions
  REAL(DP) :: push_step_size_per_atom = NAN_REAL !< @brief step size of inital push per atom
  REAL(DP) :: eigen_step_size         = NAN_REAL !< @brief max step size for push with eigenvector
  REAL(DP) :: current_step_size       = NAN_REAL !< @brief controls the current size of eigenvector step
  REAL(DP) :: lanczos_disp            = NAN_REAL !< @brief step size in the lanczos algorithm
  !!---------------------




  !! string for which we want to check if they are defined or not
  CHARACTER(LEN=5)   :: push_mode      = NAN_STR !< @brief type of initial push (all , list or rad)
  CHARACTER(LEN=255) :: engine_units   = NAN_STR !< @brief variable contains the Engine[/units]
  CHARACTER(LEN=255) :: push_guess     = NAN_STR !< @brief user file where the initial push is defined
  CHARACTER(LEN=255) :: eigenvec_guess = NAN_STR !< @brief user file where the first vector of lanczos is defined

  !! other strings
  CHARACTER(LEN=255) :: filin        = 'artn.in'         !< @brief input file
  CHARACTER(LEN=255) :: filout       = 'artn.out'        !< @brief ouput file
  CHARACTER(LEN=255) :: initpfname   = 'initp'           !< @brief prefix for initial push file
  CHARACTER(LEN=255) :: eigenfname   = 'latest_eigenvec' !< @brief prefix for latest eigenvector file
  CHARACTER(LEN=255) :: restartfname = 'artn.restart'    !< @brief restart file
  CHARACTER(LEN=255) :: prefix_min   = 'min'             !< @brief prefix fore minimum configuration file
  CHARACTER(LEN=255) :: prefix_sad   = 'sad'             !< @brief prefix fore saddle configuration file
  CHARACTER(LEN=10)  :: struc_format_out = "xsf"  !< @brief output format for the configuration
  CHARACTER(:), ALLOCATABLE :: converge_property !< @brief way to compute the force convergence (MAXVAL or NORM)



  !! logical
  LOGICAL :: lmove_nextmin         = .false. !< @brief move the structure to further minimum after finish
  LOGICAL :: lnperp_limitation     = .true.  !< @brief Constrain on the nperp-relax above the inflection point
  LOGICAL :: lrestart              = .false. !< @brief restart calculation by reading artn.restart
  LOGICAL :: lpush_final           = .false. !< @brief push to adjacent minimum
  LOGICAL :: lanczos_always_random = .false. !< @brief always start lanczos with random vector
  LOGICAL :: lanczos_at_min        = .false. !< @brief Do lanczos when the new minima are reached to check EV
  LOGICAL :: lserialize_output     = .false. !< @brief flag if we are in serialize data mode

  INTEGER, ALLOCATABLE :: nperp_limitation(:)    !< @brief array of nperp values
  INTEGER, ALLOCATABLE :: push_ids(:)            !< @brief IDs of atoms to be pushed

  REAL(DP), ALLOCATABLE :: push_add_const(:,:)   !< @brief constraints on initial push
  REAL(DP), ALLOCATABLE :: push(:,:)             !< @brief initial push vector
  REAL(DP), ALLOCATABLE :: eigenvec(:,:)         !< @brief lanczos eigenvector

  CHARACTER(LEN=3), ALLOCATABLE :: elements(:)   !< @brief element names (needed if xsf)


  !!===========================
  !! define input namelist
  !!===========================
  !
  NAMELIST/artn_parameters/ &
       !! basic info
       engine_units, verbose, &

       !! FLAGS
       lrestart, lpush_final, lmove_nextmin, lserialize_output,&

       !! counter
       ninit, neigen, nperp, lanczos_max_size, lanczos_min_size, nsmooth, nevalf_max, &

       !! constrain
       push_mode, push_dist_thr, push_ids, push_add_const, &

       !! Threshold
       forc_thr, eigval_thr, delr_thr,  &
       lanczos_eval_conv_thr, converge_property,   &

       !! Displacement length
       push_step_size, push_step_size_per_atom, lanczos_disp, eigen_step_size, push_over, &
       elements, push_guess, eigenvec_guess,   &

       !! initial vectors
       push, eigenvec, &

       !! Filename and format
       filout, initpfname, eigenfname, restartfname,  &
       zseed, restart_freq, struc_format_out, prefix_min, prefix_sad, &

       ! -- OPTION
       nperp_limitation, lnperp_limitation, nnewchance, lanczos_at_min, &
       lanczos_always_random, etot_diff_limit, nrelax_print, alpha_mix_cr

  NAMELIST/artn_parameters/ &
       !! for testing
       current_step_size


  !!================== END of variables accessible to the user









  !!===========================
  !! runtime variables
  !!===========================





  CHARACTER(LEN=255) :: artn_resume !< @brief variable store the 2 minimum and saddle point configuration file


  !! type of move encoder values
  INTEGER, PARAMETER :: &
       VOID = 1, &  !! nothing
       INIT = 2, &  !! push with initial vector
       PERP = 3, &  !! perp relaxation
       EIGN = 4, &  !! push with eigenvector
       LANC = 5, &  !! lanczos
       RELX = 6, &  !! relaxation
       OVER = 7, &  !! push_over from SP
       SMTH = 8, &     !! smoothing steps
       RSET = 9
  CHARACTER(LEN=4) :: STR_MOVE(9)
  PARAMETER( STR_MOVE = [ 'void', 'init', 'perp', 'eign', 'lanc', 'relx', 'over', 'smth', 'rset'])
  !
  !! Control Flags -> set to false in flag_false()
  LOGICAL :: linit              !< @brief initial push OF THE MACROSTEP
  LOGICAL :: lperp              !< @brief perpendicular relax
  LOGICAL :: leigen             !< @brief push with lanczos eigenvector
  LOGICAL :: llanczos           !< @brief lanczos algorithm
  LOGICAL :: lbasin             !< @brief true while in basin
  LOGICAL :: lpush_over         !< @brief saddle point obtained
  LOGICAL :: lrelax             !< @brief start the relaxation to adjacent minima from the saddle point
  LOGICAL :: in_lanczos_at_min  !< @brief Set to true when lanczos loop is the one done at min

  !! other logicals
  LOGICAL :: lbackward = .true.  !< @brief start relax from SP in backward sense
  LOGICAL :: lend      = .false. !< @brief turn the flag to true when artn finishes, to know if we re-enter

  !
  ! counters -> set to zero by local_counters_zero()
  INTEGER :: iartn              !< @brief counter of current ARTn macro step
  INTEGER :: istep              !< @brief counter of current step
  INTEGER :: iinit              !< @brief counter of pushes made with initial push, before Lanczos
  INTEGER :: iperp              !< @brief number of steps in perpendicular relaxation
  INTEGER :: ieigen             !< @brief counter of pushes made with eigenvector
  INTEGER :: irelax             !< @brief counter of relaxation steps
  INTEGER :: iover              !< @brief number of push_over step
  INTEGER :: inewchance         !< @brief number of new attemps after loosing eigenvalue
  INTEGER :: ismooth            !< @brief counter of current smoothing step






  !!------------------
  !
  INTEGER :: nlanc              !< @brief number of lanczos iterations (after lanczos converge)
  !
  ! related to multiple explorations
  INTEGER :: ifound  = 0        !< @brief Number of saddle point found (only used in write_header_report)
  INTEGER :: isearch = 0        !< @brief Number of saddle point research, initialise here, implicit save!
  INTEGER :: ifails  = 0        !< @brief number of failures, initialize in setup_artn

  !
  ! optional staff
  INTEGER :: nperp_step  !< @brief  nperp_limitation step
  !
  !! output structure counter
  INTEGER :: nmin       !< @brief  count the number of minimum found
  INTEGER :: nsaddle    !< @brief  count the number of saddle point found
  !
  !! arrays that are needed by ARTn internally !
  REAL(DP), ALLOCATABLE :: delr_vec(:,:)         !< @brief displacement vector
  !
  !


  REAL(DP), ALLOCATABLE :: force_old(:,:)       !< @brief force in the previous step
  REAL(DP), ALLOCATABLE :: push_initial_vector(:,:)  !< @brief save the initial push
  !
  LOGICAL :: luser_choose_per_atom          !< @brief Flag to distinguish the 2 push_step_size definition
  INTEGER :: fpush_factor                  !< @brief internal factor for the final push direction

  ! array related to the report
  REAL(DP) :: debrief(8)                    !< @brief Array contains the values for the debrief output

  !
  CHARACTER(LEN=500)            :: error_message  !< @brief Variable to store the error message
  character(:), allocatable :: words(:) !< Use for parser : remove the worning

  LOGICAL :: lserialize_input  !< @brief flag if we are in serialize data mode
  character(*), parameter :: serial_input_fname="artn_serial_input"

  INTEGER :: called_from = CALLER_IS_ENGINE

  !!================== END of runtime variables






















  interface

     !! check_artn_params.f90
     module subroutine check_artn_params( nat, error )
       integer, intent(in) :: nat
       logical, intent(out) :: error
     end subroutine check_artn_params


     !! fill_param_step.f90
     module subroutine Fill_param_step( nat, box, order, ityp,  pos, etot, force, error )
       INTEGER, INTENT(IN) :: nat, order(nat), ityp(nat)
       REAL(DP), INTENT(IN) :: box(3,3), etot, pos(3,nat), force(3,nat)
       LOGICAL, INTENT(OUT) :: error
     end subroutine Fill_param_step


     !! set_param.f90
     module function set_param_int( name, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: val
       integer :: ierr
     end function set_param_int
     module function set_param_real( name, val )result(ierr)
       character(*), intent(in) :: name
       real(DP), intent(in) :: val
       integer :: ierr
     end function set_param_real
     module function set_param_bool( name, val )result(ierr)
       character(*), intent(in) :: name
       logical, intent(in) :: val
       integer :: ierr
     end function set_param_bool
     module function set_param_str( name, val )result(ierr)
       character(*), intent(in) :: name
       character(*), intent(in) :: val
       integer :: ierr
     end function set_param_str
     module function set_param_int1d( name, dim, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim
       integer, intent(in) :: val(dim)
       integer :: ierr
     end function set_param_int1d
     module function set_param_real2d( name, dim1, dim2, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim1, dim2
       real(DP), intent(in) :: val(dim1, dim2)
       integer :: ierr
     end function set_param_real2d


     !! get_params.f90
     module subroutine get_param_int( name, val, ierr )
       character(*), intent(in) :: name
       integer, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_param_int
     module subroutine get_param_real( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_param_real
     module subroutine get_param_bool( name, val, ierr )
       character(*), intent(in) :: name
       logical, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_param_bool
     module subroutine get_param_str( name, val, ierr )
       character(*), intent(in) :: name
       character(:), allocatable, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_param_str
     module subroutine get_param_int1d( name, val, ierr )
       character(*), intent(in) :: name
       integer, allocatable, intent(out) :: val(:)
       integer, intent(out) :: ierr
     end subroutine get_param_int1d
     module subroutine get_param_real2d( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), allocatable, intent(out) :: val(:,:)
       integer, intent(out) :: ierr
     end subroutine get_param_real2d

     !! set_runparam.f90
     module function set_runparam_int( name, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: val
       integer :: ierr
     end function set_runparam_int
     ! module function set_runparam_real( name, val )result(ierr)
     !   character(*), intent(in) :: name
     !   real(DP), intent(in) :: val
     !   integer :: ierr
     ! end function set_runparam_real
     module function set_runparam_bool( name, val )result(ierr)
       character(*), intent(in) :: name
       logical, intent(in) :: val
       integer :: ierr
     end function set_runparam_bool
     module function set_runparam_str( name, val )result(ierr)
       character(*), intent(in) :: name
       character(*), intent(in) :: val
       integer :: ierr
     end function set_runparam_str
     ! module function set_runparam_int1d( name, dim, val )result(ierr)
     !   character(*), intent(in) :: name
     !   integer, intent(in) :: dim
     !   integer, intent(in) :: val(dim)
     !   integer :: ierr
     ! end function set_runparam_int1d
     module function set_runparam_real1d( name, dim, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim
       real(DP), intent(in) :: val(dim)
       integer :: ierr
     end function set_runparam_real1d
     module function set_runparam_real2d( name, dim1, dim2, val )result(ierr)
       character(*), intent(in) :: name
       integer, intent(in) :: dim1, dim2
       real(DP), intent(in) :: val(dim1, dim2)
       integer :: ierr
     end function set_runparam_real2d

     !! get_runparam.f90
     module subroutine get_runparam_int( name, val, ierr )
       character(*), intent(in) :: name
       integer, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_runparam_int
     module subroutine get_runparam_real( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_runparam_real
     module subroutine get_runparam_bool( name, val, ierr )
       character(*), intent(in) :: name
       logical, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_runparam_bool
     module subroutine get_runparam_str( name, val, ierr )
       character(*), intent(in) :: name
       character(:), allocatable, intent(out) :: val
       integer, intent(out) :: ierr
     end subroutine get_runparam_str
     module subroutine get_runparam_real1d( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), allocatable, intent(out) :: val(:)
       integer, intent(out) :: ierr
     end subroutine get_runparam_real1d
     module subroutine get_runparam_real2d( name, val, ierr )
       character(*), intent(in) :: name
       real(DP), allocatable, intent(out) :: val(:,:)
       integer, intent(out) :: ierr
     end subroutine get_runparam_real2d


     !! serialize.f90
     module subroutine dump_input( fname )
       character(*), intent(in) :: fname
     end subroutine dump_input
     module subroutine dump_data( fname )
       character(*), intent(in) :: fname
     end subroutine dump_data
     module function read_datadump( fname )result(ierr)
       character(*), intent(in) :: fname
     end function read_datadump


  end interface



  !! Overload the fortran names with generic set_param.
  !! This cannot be done for C routines.
  interface set_param
     module procedure :: set_param_int, set_param_real, set_param_bool, set_param_str
     module procedure :: set_param_int1d, set_param_real2d
  end interface set_param

  !! Overload the fortran names with generic get_param.
  interface get_param
     module procedure :: get_param_int, get_param_real, get_param_bool, get_param_str
     module procedure :: get_param_int1d, get_param_real2d
  end interface get_param

  !! overload the fortran names with generic set_runparam
  interface set_runparam
     module procedure :: set_runparam_int, set_runparam_bool, set_runparam_str
     module procedure :: set_runparam_real1d, set_runparam_real2d
  end interface set_runparam

  !! overload the fortran names with generic get_runparam
  interface get_runparam
     module procedure :: get_runparam_int, get_runparam_bool, get_runparam_str
     module procedure :: get_runparam_real1d, get_runparam_real2d
  end interface get_runparam

CONTAINS



  !---------------------------------------------------------------------------
  !> @brief
  !!   turn off all the block flags
  !
  module subroutine flag_false()
    implicit none

    linit = .false.
    lperp = .false.
    leigen = .false.
    llanczos = .false.
    lbasin = .false.
    lpush_over = .false.
    lrelax = .false.
    !lsaddle = .false.
    lrestart = .false.
    in_lanczos_at_min = .false.

  end subroutine flag_false


  module subroutine reset_blockflags()
    !! put block flags to initial values
    !! NOTE: set all except lend
    linit             = .true.
    lperp             = .false.
    leigen            = .false.
    llanczos          = .false.
    lbasin            = .true.
    lpush_over        = .false.
    lrelax            = .false.
    in_lanczos_at_min = .false.
    lbackward         = .true.
  end subroutine reset_blockflags

END MODULE artn_params





