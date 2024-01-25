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
!
!8888> @namespace artn_params
!
!> @brief
!!   This module contains all global variables that are used in the ARTn plugin
!
!> @note 
!!   List of routine in-module:
!!   - setup_artn()
!!   - fill_param_step()
!!   - warning_*
!!   - flag_false()
!!   - ran3()
!!   - dot_field()     NOT USED
!!   - random_array()  NOT USED
!!
!> @ingroup ARTn
!
MODULE artn_params
  !
  use artn_data, only: t_artn_data
  USE units, ONLY : DP
  IMPLICIT NONE 
  SAVE
  ! constants unit pipe
  INTEGER, PARAMETER :: iunartin     = 52   !< @brief fortran file unit for ARTn input file
  INTEGER, PARAMETER :: iunartout    = 53   !< @brief fortran file unit for ARTn output file
  INTEGER, PARAMETER :: iunartres    = 54   !< @brief fortran file unit for ARTn restart file
  INTEGER, PARAMETER :: iunstruct    = 556  !< @brief fortran file unit for writing the structure
  INTEGER, PARAMETER :: iunrestart   = 557  !< @brief fortran file unit for writing the structure
  INTEGER, PARAMETER :: ERRlog   = 888  !< @brief fortran file unit for writing the structure
  ! file names
  CHARACTER(LEN=255) :: filin        = 'artn.in'             !< @brief input file
  CHARACTER(LEN=255) :: filout       = 'artn.out'            !< @brief ouput file
  CHARACTER(LEN=255) :: initpfname   = 'initp'               !< @brief prefix used for the initial push file
  CHARACTER(LEN=255) :: eigenfname   = 'latest_eigenvec'     !< @brief prefix used for the latest eigenvector file store
  CHARACTER(LEN=255) :: restartfname = 'artn.restart'        !< @brief restart file
  CHARACTER(LEN=255) :: prefix_min   = 'min'                 !< @brief prefix used to name the minimum configuration file
  CHARACTER(LEN=255) :: prefix_sad   = 'sad'                 !< @brief prefix used to name the saddle point configuration file
  CHARACTER(LEN=255) :: artn_resume                          !< @brief variable store the 2 minimum and saddle point configuration file
  ! optional file
  CHARACTER(LEN=255) :: push_guess   = " "        !< @brief  user file where the initial push is defined
  CHARACTER(LEN=255) :: eigenvec_guess = " "      !< @brief  user file where the first eigenvector of lanczos is defined
  ! Constante move
  INTEGER, parameter :: VOID = 1, INIT = 2, PERP = 3, EIGN = 4, LANC = 5, RELX = 6, OVER = 7, SMTH = 8
  CHARACTER(LEN=4) :: MOVE(8)
  PARAMETER( MOVE = [ 'void', 'init', 'perp', 'eign', 'lanc', 'relx', 'over', 'smth'])
  !
  !! Control Flags
  !  =============
  LOGICAL :: linit              !< @brief initial push OF THE MACROSTEP
  LOGICAL :: lperp              !< @brief perpendicular relax
  LOGICAL :: leigen             !< @brief push with lanczos eigenvector
  LOGICAL :: llanczos           !< @brief lanczos algorithm
  LOGICAL :: lbasin             !< @brief true while in basin 
  LOGICAL :: lpush_over         !< @brief saddle point obtained
  LOGICAL :: lbackward          !< @brief backward saddle point obtained
  LOGICAL :: lmove_nextmin      !< @brief backward saddle point obtained
  LOGICAL :: lread_param        !< @brief flag read artn params NOTE: does not affect anything
  LOGICAL :: lnperp_limitation  !< @brief Constrain on the nperp-relax above the inflation point 
  LOGICAL :: lend               !< @brief Flag to finish the ARTn research
  LOGICAL :: in_lanczos_at_min  !< @brief Set to true when lanczos loop is the one done at min
  INTEGER :: verbose            !< @brief Verbose Level
  !
  ! counters
  INTEGER :: iartn              !< @brief counter of current ARTn macro step
  INTEGER :: istep              !< @brief counter of current step
  INTEGER :: iinit              !< @brief counter of pushes made with initial push, before Lanczos
  INTEGER :: iperp              !< @brief number of steps in perpendicular relaxation
  INTEGER :: ilanc              !< @brief counter of current lanczos iteration step
  INTEGER :: ieigen             !< @brief counter of pushes made with eigenvector
  INTEGER :: irelax             !< @brief counter of relaxation steps
  INTEGER :: iover              !< @brief number of push_over step
  INTEGER :: inewchance         !< @brief number of new attemps after loosing eigenvalue 
  INTEGER :: ismooth            !< @brief counter of current smoothing step
  INTEGER :: if_pos_ct          !< @brief counter used to determine the number of fixed coordinates
  INTEGER :: iperp_save         !< @brief number of steps in perpendicular relaxation
  INTEGER :: ilanc_save         !< @brief save current lanczos iteration
  !
  INTEGER :: nlanc              !< @brief number of lanczos iterations (after lanczos converge)
  !
  ! related to multiple explorations
  INTEGER :: ifound             !< @brief Number of saddle point found (only used in write_header_report)
  INTEGER :: isearch = 0        !< @brief Number of saddle point research, initialise here, implicit save!
  INTEGER :: ifails             !< @brief number of failures, initialize in setup_artn

  ! system parameter
  INTEGER :: natoms             !< @brief Number of atoms in the system
  INTEGER :: zseed              !< @brief random number generator seed

  ! output parameter
  INTEGER :: prev_disp          !< @brief Save the previous displacement
  INTEGER :: prev_push          !< @brief Save the previous push
  ! 
  ! optional staff
  !! nperp
  INTEGER :: nperp                                              !< @brief  max perp-relax iteration  
  INTEGER :: noperp                                             !< @brief  count number of time perp-relax is not done
  INTEGER :: def_nperp_limitation(5) = [ 4, 8, 12, 16, -1 ]     !< @brief  default values for nperp limitation evolution
  INTEGER, ALLOCATABLE :: nperp_limitation(:)                   !< @brief  array of nperp values
  INTEGER :: nperp_step                                         !< @brief  nperp_limitation step
  !
  !! output structure counter
  INTEGER :: nmin       !< @brief  count the number of minimum found
  INTEGER :: nsaddle    !< @brief  count the number of saddle point found
  !
  ! lanczos variables
  REAL(DP) :: lowest_eigval                      !< @brief  Lowest eigenvalues obtained by lanczos algorithm
  !                                           
  !! arrays that are needed by ARTn internally !
  !
  REAL(DP) :: lat(3,3)                           !< @brief Box parameter
  REAL(DP), ALLOCATABLE :: tau_init(:,:)         !< @brief initial coordinates
  REAL(DP), ALLOCATABLE :: tau_nextmin(:,:)      !< @brief coordinates of the new minimum
  REAL(DP), ALLOCATABLE :: delr(:,:)             !< @brief displacement vector  
  REAL(DP), ALLOCATABLE :: push(:,:)             !< @brief initial push vector
  REAL(DP), ALLOCATABLE :: eigenvec(:,:)         !< @brief lanczos eigenvector
  REAL(DP), ALLOCATABLE :: tau_step(:,:)         !< @brief current coordinates (restart)
  REAL(DP), ALLOCATABLE :: force_step(:,:)       !< @brief current force (restart)
  REAL(DP), ALLOCATABLE :: tau_saddle(:,:)       !< @brief coordinates of saddle point
  REAL(DP), ALLOCATABLE :: eigen_saddle(:,:)     !< @brief saddle point eigenvector
  INTEGER, ALLOCATABLE :: types(:)
  !
  ! stored total energies and energy differences
  !
  REAL(DP) :: etot_init    !< @brief  the total energy of the initial state
  REAL(DP) :: etot_step    !< @brief  the total energy in the current step
  REAL(DP) :: etot_saddle  !< @brief  the total energy of the saddle point
  REAL(DP) :: etot_final   !< @brief  the total energy of the next minimum along eigenvector
  REAL(DP) :: de_saddle    !< @brief  change in E from starting point
  REAL(DP) :: de_back      !< @brief  backward barrier
  REAL(DP) :: de_fwd       !< @brief  forward barrier
  !                                               !
  ! arrays that are used by the Lanczos algorithm !
  !                                               !
  REAL(DP) :: a1  !< @brief dot product between previous and actual min lanczos vector
  REAL(DP) :: old_lowest_eigval                 !< @brief eigenvalue of the last lanczos computation
  REAL(DP), ALLOCATABLE :: old_lanczos_vec(:,:) !< @brief Store the previous lanczos vec
  REAL(DP), ALLOCATABLE :: H(:,:)               !< @brief tridiagonal matrix
  REAL(DP), ALLOCATABLE :: Vmat(:,:,:)          !< @brief matrix containing the laczos vectors
  REAL(DP), ALLOCATABLE :: force_old(:,:)       !< @brief force in the previous step
  REAL(DP), ALLOCATABLE :: v_in(:,:)            !< @brief first lanczos eigenvector
  REAL(DP), ALLOCATABLE :: push_initial_vector(:,:)  !< @brief save the initial push
  !------------------------------------------------------------!
  ! variables that are read from the input  start here
  !------------------------------------------------------------!
  !
  LOGICAL :: lrestart                       !< @brief do we want to restart the calculation
  LOGICAL :: lrelax                         !< @brief do start the relaxation to adjacent minima from the saddle point
  LOGICAL :: lpush_final                    !< @brief push to adjacent minimum along eigenvector
  LOGICAL :: lanczos_always_random          !< @brief always start lanczos with random vector
  LOGICAL :: lanczos_at_min                 !< @brief Do lanczos when the new minima are reached to check if all EV are positive
  !
  INTEGER :: nevalf_max                     !< @brief Force calls max #. Must be < one of the F engine (if exist) to have an effect
  INTEGER :: ninit                          !< @brief number of initial pushes before lanczos start
  INTEGER :: neigen                         !< @brief number of steps made with eigenvector before perp relax
  INTEGER :: lanczos_max_size               !< @brief size of the lanczos tridiagonal matrix 
  INTEGER :: lanczos_min_size               !< @brief minimal size of lanzos matrix (use with care)
  INTEGER :: nsmooth                        !< @brief number of smoothing steps from push to eigenvec
  INTEGER :: nnewchance                     !< @brief number of new attemps after loosing eigenvalue
  INTEGER :: nrelax_print                   !< @brief print at every nrelax step 
  CHARACTER(LEN = 5) :: push_mode           !< @brief type of initial push (all , list or rad)
  ! convergence criteria
  REAL(DP) :: push_dist_thr                 !< @brief distance threshold for push mode "rad"
  REAL(DP) :: forc_thr                      !< @brief tightened force convergence criterion when near the saddle point
  REAL(DP) :: eigval_thr                    !< @brief threshold for eigenvalue
  REAL(DP) :: frelax_ene_thr                !< @brief threshold to start relaxation to adjacent minima
  REAL(DP) :: etot_diff_limit               !< @brief limit for energy difference, if above exit the research
  REAL(DP) :: delr_thr                      !< @brief length Threshold to consider an atomic has moved
  ! step sizes
  REAL(DP) :: push_step_size                !< @brief step size of inital push in angstrom
  REAL(DP) :: push_step_size_per_atom       !< @brief step size of inital push in angstrom per atom
  LOGICAL :: luser_choose_per_atom          !< @brief Flag to distinguish the 2 push_step_size definition
  REAL(DP) :: eigen_step_size               !< @brief step size for a step with the lanczos eigenvector
  REAL(DP) :: current_step_size             !< @brief controls the current size of eigenvector step
  INTEGER :: fpush_factor                  !< @brief factor for the final push
  REAL(DP), target :: lanczos_disp          !< @brief step size in the lanczos algorithm 
  REAL(DP), target :: lanczos_eval_conv_thr !< @brief threshold for convergence of eigenvalue in Lanczos
  REAL(DP) :: push_over                     !< @brief EigenVec fraction Push_over the saddle point for the relax
  ! arrays related to constraints
  INTEGER,  ALLOCATABLE :: push_ids(:)    !< @brief IDs of atoms to be pushed
  REAL(DP), ALLOCATABLE :: push_add_const(:,:) !< @brief constraints on initial push
  ! array related to the report
  !REAL(DP) :: bilan(8)                    !< @brief Array contains the values for the debrief output
  REAL(DP) :: debrief(8)                    !< @brief Array contains the values for the debrief output

  ! Default Values (in Ry, au)
  REAL(DP), PARAMETER :: NAN = HUGE( lanczos_disp )  !< @brief Biggest number in DP representation
  REAL(DP), PARAMETER :: def_push_dist_thr           = 0.0_DP,     &
                         def_delr_thr                = 0.1_DP,     &
                         def_forc_thr                = 1.0d-3,     &
                         def_eigval_thr              = -0.01_DP,   &
                         def_frelax_ene_thr          = 0.00_DP,    &
                         def_push_step_size          = 0.4,        &
                         def_push_step_size_per_atom = 0.2_DP,     &
                         def_eigen_step_size         = 0.4,        &
                         def_lanczos_disp            = 1.D-2,      &
                         def_lanczos_eval_conv_thr   = 1.0D-2,     &
                         def_etot_diff_limit         = 80.0_DP

  !
  CHARACTER(LEN=256)            :: engine_units                     !< @brief variable contains the Engine[/units] 
  CHARACTER(LEN=10)             :: struc_format_out                 !< @brief output format for the configuration
  CHARACTER(LEN=10), PARAMETER  :: def_struc_format_out = 'xsf'     !< @brief default value of struc_format_out
  CHARACTER(LEN=3), ALLOCATABLE :: elements(:)                      !< @brief Array containing the element name in the system
  CHARACTER(:),     ALLOCATABLE :: converge_property                !< @brief Define the way to compute the force convergence (MAXVAL or NORM)
  CHARACTER(LEN=500)            :: error_message                    !< @brief Variable to store the error message
  character(:), allocatable :: words(:) !< Use for parser : remove the worning
  ! output parameter
  INTEGER :: restart_freq       !< @brief Frequency to write the restart_file: 0= never, 1= every step, 2= every push
  TYPE( t_artn_data ), pointer :: artn_data_ptr=>null() !< @brief Pointer to type containing data, set from the API
  LOGICAL :: lserialize_input, lserialize_output    !< @brief flags if we are in serialize data mode
  !
  ! define input namelist
  !
  NAMELIST/artn_parameters/ &
       !! FLAGS
       lrestart, lrelax, lpush_final, lmove_nextmin, lserialize_output,&

       !! counter
       ninit, neigen, nperp, lanczos_max_size, lanczos_min_size, nsmooth, nevalf_max, &

       !! constrain
       push_mode, push_dist_thr, push_ids, push_add_const, &

       !! Threshold
       forc_thr, eigval_thr, frelax_ene_thr, delr_thr,  &
       lanczos_eval_conv_thr, converge_property,   &

       !! Displacement length
       push_step_size, push_step_size_per_atom, lanczos_disp, eigen_step_size, push_over, &
       engine_units, elements, push_guess, eigenvec_guess,   &

       !! initial vectors
       push, eigenvec, &

       !! Filename and format
       filout, initpfname, eigenfname, restartfname,  &
       verbose, zseed, restart_freq, struc_format_out, &

       ! -- OPTION
       nperp_limitation, lnperp_limitation, nnewchance, lanczos_at_min, &
       lanczos_always_random, etot_diff_limit, nrelax_print

  NAMELIST/artn_parameters/ &
       !! for testing
       current_step_size


  !> @interface warning
  !! @brief 
  !!   generic name for \b warning_nothing \b , \b warning_int \b , \b warning_real \b and \b warning_char \b subroutine
  INTERFACE warning
    module procedure :: warning_nothing, warning_int, warning_real, warning_char
  END INTERFACE 



CONTAINS


  SUBROUTINE set_default_params()
    implicit none

  END SUBROUTINE set_default_params


  !---------------------------------------------------------------------------
  !> @brief \b FILL_PARAM_STEP
  !
  !> @par Purpose
  !  ============
  !>   Fill the *_step arrays on which ARTn works on (positions and forces).\n
  !!   For parallel Engine each proc has list from 1 to natproc.
  !!   So there is a global index [1:nat] and local index nproc*[1:natproc]:
  !!   IMPORTANT: All the array are ordered and the POSITIONS ARE NOT CONVERTED.
  !> @verbatim
  !!   array_eng( i ) is ordered such that order( i ) = iat (Ordered) 
  !!   => array( iat ) = array_eng( i )
  !!   Then array( order(i) ) = array_eng( i )
  !> @endverbatim
  !
  !> @param[in]  nat      number of atoms
  !! @param[in]  box      box parameters
  !! @param[in]  order    index order of engine
  !! @param[in]  pos      atomic position
  !! @param[in]  etot     energy of the system
  !! @param[in]  force    atomic force
  !! @param[out] error    failure indicator
  !
  SUBROUTINE Fill_param_step( nat, box, order, ityp,  pos, etot, force, error )
    !
    ! overwrite variables from artn_params:
    !  - natoms
    !  - lat
    !  - etot_step
    !  - types        ORDERED by 'order' argument
    !  - force_step   ORDERED by 'order' argument
    !  - tau_step     ORDERED by 'order' argument
    !  - error
    !  - error_message

    use units, only : convert_energy, convert_force, convert_length

    INTEGER, INTENT(IN) :: nat, order(nat), ityp(nat)
    REAL(DP), INTENT(IN) :: box(3,3), etot, pos(3,nat), force(3,nat)
    LOGICAL, INTENT(OUT) :: error

    !! reset the error message
    error = .false.
    error_message = ""

    !! Error if any index in the order array is out of scope (indicate lost atoms in lammps).
    IF( any(order .lt. 1) .or. &
         any(order .gt. nat)  ) THEN

       !! signal failure
       error = .true.
       error_message = "order array contains invalid values. Should be [1:nat]"
       return
    ENDIF

    !! if any given parameters are NaN, return error
    IF( nat .ne. nat .or. &
         any(order .ne. order) .or. &
         any(box .ne. box) .or. &
         any(pos .ne. pos) .or. &
         any(force .ne. force) .or. &
         etot .ne. etot ) THEN
       error = .true.
       error_message = "Received a NaN value from engine"
       return
    ENDIF


    natoms = nat
    lat = box
    etot_step = convert_energy( etot )
    types(order(:)) = ityp(:)
    force_step(:,order(:)) = convert_force( force(:,:) )
    ! ...IMORTANT: the position is not converted 
    tau_step(:,order(:)) = pos(:,:)
    !tau_step(:,order(:)) = convert_length( pos(:,:) )

  END SUBROUTINE Fill_param_step


  !
  !---------------------------------------------------------------------------
  !> @brief
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !
  SUBROUTINE warning_nothing( u0, STEP, text )
    integer, intent( in ) :: u0
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    1 format(*(A))

  END SUBROUTINE warning_nothing

  !> @brief 
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !> @param[in]   intv   vector of integer
  !
  SUBROUTINE warning_int( u0, STEP, text, intv )
    !
    integer, intent( in ) :: u0, intv(:)
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    WRITE( u0,2 ) "* => ", intv
    1 format(*(A))
    2 format(A,*(1x,i0))

  END SUBROUTINE warning_int


  !> @brief 
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !> @param[in]   realv   vector of real
  !
  SUBROUTINE warning_real( u0, STEP, text, realv )
    integer, intent( in ) :: u0
    REAL(DP), intent( in ) :: realv(:)
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    WRITE( u0,2 ) "* => ", realv
    1 format(*(A))
    2 format(A,*(1x,f12.6))

  END SUBROUTINE warning_real


  !> @brief 
  !!   routine write warning
  !
  !> @param[in]   u0     output unit chanel
  !> @param[in]   STEP   name of function you call warning
  !> @param[in]   text   comment for the user
  !> @param[in]   charv   vector of character
  !
  SUBROUTINE warning_char( u0, STEP, text, charv )
    integer, intent( in ) :: u0
    character(*), intent( in ) :: charv(:)
    character(*), intent( in ) :: STEP, text

    WRITE( u0,1 ) "* WARNING in ", STEP
    WRITE( u0,1 ) "* => ", text
    WRITE( u0,1 ) "* => ", charv
    1 format(*(A))

  END SUBROUTINE warning_char



  !---------------------------------------------------------------------------
  !> @brief
  !!   turn off all the block flags
  !
  subroutine flag_false()
    implicit none

    lrelax = .false.
    linit = .false.
    lbasin = .false.
    lperp = .false.
    llanczos = .false.
    leigen = .false.
    !lsaddle = .false.
    lpush_over = .false.
    lrestart = .false.
    in_lanczos_at_min = .false.

  end subroutine flag_false

  !> @brief
  !!   set all counters used locally in single ARTn run to zero
  subroutine local_counters_zero()
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



  !---------------------------------------------------------------------------
  REAL(8) FUNCTION ran3( idum )
    !-------------------------------------------------------------------------
    !> @brief
    !!   Random number generator.
    !
    !> @param [in] idum   dummy integer: on first call to ran3, this is the seed,
    !!                                    its value is put to 1 after the first
    !!                                    call. If the calling program modifies it
    !!                                    to a negative number, the generator is
    !!                                    re-seeded.
    !> @return a real(8) ramdom number
    !
    !
    IMPLICIT NONE
    !
    SAVE
    !         implicit real*4(m)
    !         parameter (mbig=4000000.,mseed=1618033.,mz=0.,fac=2.5e-7)
    integer :: mbig, mseed, mz
    real(DP) :: fac
    parameter (mbig = 1000000000, mseed = 161803398, mz = 0, fac = 1.d-9)
   
    integer :: ma (55), iff, k, inext, inextp, ii, mj, idum, i, mk
    !inext = 0
    !inextp = 0
    !     common /ranz/ ma,inext,inextp
    data iff / 0 /
    if (idum.lt.0.or.iff.eq.0) then
       iff = 1
       mj = mseed-iabs (idum)
       mj = mod (mj, mbig)
       ma (55) = mj
       mk = 1
       do i = 1, 54
          ii = mod (21 * i, 55)
          ma (ii) = mk
          mk = mj - mk
          if (mk.lt.mz) mk = mk + mbig
          mj = ma (ii)
       enddo
       do k = 1, 4
          do i = 1, 55
           ma (i) = ma (i) - ma (1 + mod (i + 30, 55) )
           if (ma (i) .lt.mz) ma (i) = ma (i) + mbig
        enddo
     enddo
     inext = 0
     inextp = 31
     idum = 1
    endif
    inext = inext + 1
    if (inext.eq.56) inext = 1
    inextp = inextp + 1
    if (inextp.eq.56) inextp = 1
    mj = ma (inext) - ma (inextp)
    if (mj.lt.mz) mj = mj + mbig
    ma (inext) = mj
    ran3 = mj * fac
    return
  END FUNCTION ran3


  !..................................................
  !> @brief 
  !!   Scalar product of 2 arrays
  !
  !> @note   NOT USED!
  !
  !> @param[in] n   size of array
  !> @param[in] dx  array dx  
  !> @param[in] dy  array dy 
  !! @return  scalar product dx*dy
  !
  function dot_field( n, dx, dy )result( res )
    use units, only : DP
    implicit none
    integer, intent(in) :: n
    real(DP), intent(in) :: dx(*), dy(*)

    integer :: i
    real(DP) :: tmp, res

    res = 0.0_DP
    tmp = 0.0_DP
    do i = 1,n
       tmp = tmp + dx(i)*dy(i)
    enddo
    res = tmp
  end function dot_field

  !..................................................
  !> @brief
  !!   make real(DP) random array normalized with a possibility to 
  !!   give a bias to the randomness  
  !
  !> @note NOT USED!
  !
  !> @param[in]      n     length of the arrays
  !> @param[inout]   v     array has to be random
  !> @param[in]      bias  specific direction use to orient the randomization (optional)
  !! @param[in]      seed  Seed for random number generator (optional)
  !
  SUBROUTINE random_array( n, v, bias, seed )
    implicit none
 
    integer, intent( in ) :: n
    real(DP), intent( out ) :: v(*)
    real(DP), intent( in ), optional :: bias(*)
    integer, intent( in ), optional :: seed
 
    integer :: i, iidum
    REAL(DP) :: z, vnorm, vbias(n)
    real(DP), external :: dsum
 
    ! ...BIAS OPTION
    vbias = 1.0_DP
    if( present(bias) )then
      do i = 1,n
         vbias(i) = bias(i)
      enddo
    endif
 
    ! ...SEED OPTION
    if( present(seed) )then
      iidum = seed
    else
      CALL random_number(z)
      z = z *1e8
      iidum = INT(z)
    endif

    ! ...Random Vector
    DO i = 1, n
       !! Antoine update
       v( i ) = (0.5_DP - ran3(iidum))*vbias( i )
    ENDDO
 
    ! normalize
    !vnorm = 1.0_DP / sqrt(dsum(n,v))
    vnorm = 1.0_DP / norm2(v(1:n))
    DO i = 1,n
       v(i) = v(i) * vnorm
    ENDDO

  END SUBROUTINE random_array
    
END MODULE artn_params
! ======================================================================== END MODULE 
 
 




