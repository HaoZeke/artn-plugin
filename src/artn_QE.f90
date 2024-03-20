!
!> @author Matic Poberznik,
!! @author Miha Gunde
!! @author Nicolas Salles
!
!> @brief
!!   Interface Quantum ESPRESSO/ARTn:
!
!> @par Purpose
!  ============
!>   We convert/compute/adapt some variables,
!!   modifies the input force to perform the ARTn algorithm
!
!> @param[in,out]   force              force calculated by the engine
!! @param[in]       etot               total energy in current step
!! @param[in,out]   epsf_qe            force convergence threshold of the engine
!! @param[in]       nat                number of atoms
!! @param[in]       ntyp               number of atomic types
!! @param[in]       ityp               atom types
!! @param[in]       atm                name of atom corresponding to ityp
!! @param[in,out]   tau                atomic positions (needed for output only)
!! @param[in]       at                 lattice parameters in alat units
!! @param[in]       alat               lattice parameter of QE
!! @param[in]       istep              current step
!! @param[in]       if_pos             coordinates fixed by engine
!! @param[in,out]   vel                velocity of previous FIRE step
!! @param[in]       dt_init            default time step in FIRE
!! @param[in]       fire_alpha_init    initial value of alpha in FIRE
!! @param[out]      lconv              flag for controlling convergence
!! @param[in]       prefix_qe          prefix for scratch files of engine
!! @param[in]       tmp_dir_qe         scratch directory of engine
!
!> @ingroup Interface
!> @snippet artn_QE.f90  QE
!------------------------------------------------------------------------------
SUBROUTINE artn_QE( force, etot, epsf_qe, nat, ntyp, ityp, atm, tau, at, alat, istep, if_pos,   &
                    vel, dt_init, fire_alpha_init, lconv, prefix_qe, tmp_dir_qe, qe_version_number )
  !----------------------------------------------------------------------------
  !
!> [QE]
  USE precision, ONLY : DP
  USE artn_params, ONLY: forc_thr, elements
  use m_artn
  use m_move_mode
  use m_clean_artn
  !
  !
  IMPLICIT NONE
  INTEGER,            INTENT(IN)    :: nat               !  number of atoms
  REAL(DP),           INTENT(INOUT) :: force(3,nat)      !  force calculated by the engine
  REAL(DP),           INTENT(INOUT) :: vel(3,nat)        !  velocity of previous FIRE step
  REAL(DP),           INTENT(INOUT) :: tau(3,nat)        !  atomic positions (needed for output only)
  REAL(DP),           INTENT(INOUT) :: epsf_qe           !  force convergence threshold of the engine
  REAL(DP),           INTENT(IN)    :: etot              !  total energy in current step
  REAL(DP),           INTENT(IN)    :: dt_init           !  default time step in FIRE
  REAL(DP),           INTENT(IN)    :: fire_alpha_init   !  initial value of alpha in FIRE
  REAL(DP),           INTENT(IN)    :: alat              !  lattice parameter of QE
  REAL(DP),           INTENT(IN)    :: at(3,3)           !  lattice parameters in alat units
  INTEGER,            INTENT(IN)    :: ntyp              !  number of atomic types
  INTEGER,            INTENT(INOUT)    :: ityp(nat)         !  atom types
  INTEGER,            INTENT(IN)    :: istep             !  current step
  INTEGER,            INTENT(IN)    :: if_pos(3,nat)     !  coordinates fixed by engine
  CHARACTER(LEN=3),   INTENT(IN)    :: atm(*)            !  name of atom corresponding to ityp
  CHARACTER(LEN=255), INTENT(IN)    :: tmp_dir_qe        !  scratch directory of engine
  CHARACTER(LEN=255), INTENT(IN)    :: prefix_qe         !  prefix for scratch files of engine
  CHARACTER(LEN=6),   INTENT(IN)    :: qe_version_number !  contains information on the used version of QE
  LOGICAL,            INTENT(OUT)   :: lconv             !  flag for controlling convergence
  !
  REAL(DP)                          :: box(3,3)
  REAL(DP)                          :: pos(3,nat)
  REAL(DP)                          :: etot_fire, dt_curr, alpha
  REAL(DP)                          :: displ_vec(3,nat)
  REAL(DP)                          :: qe_version
  INTEGER                           :: nsteppos, order(nat)

  LOGICAL                           :: file_exists
  CHARACTER(len=256)                :: filnam
  INTEGER                           :: ios, i, disp
  INTEGER                           :: fire_restart

  box = at * alat
  pos = tau * alat

  READ (qe_version_number, '(f3.2)') qe_version

  do i = 1,nat
     order(i) = i
  enddo
  IF ( .not. ALLOCATED(elements) )         ALLOCATE( elements(ntyp),        source = "XXX")

  ! use atomic types defined in QE input
  DO i = 1, ntyp
     elements(i) = atm(i)
  ENDDO

  ! ...Launch ARTn
  call artn( force, etot, nat, ityp, atm, pos, order, box, if_pos, disp, displ_vec, lconv )

  ! ... Set the QE force threshold to a safe value (it is reset after the ARTn converges)
  if ( istep == 0  ) epsf_qe = 1d-10

  ! ...Change the position to QE
  tau = pos / alat
  ! ...Read the Fire parameters
  filnam = trim(tmp_dir_qe) // '/' // trim(prefix_qe) // '.' //'fire'
  INQUIRE( file = filnam, exist = file_exists )
  OPEN( unit = 4, file = filnam, form = 'formatted', status = 'unknown', iostat = ios)
  !
  IF (file_exists ) THEN
     ! if file exists read the data, otherwise just close it
     IF ( qe_version >= 7.2)  READ( UNIT = 4, FMT = * ) fire_restart
     READ( UNIT = 4, FMT = * ) etot_fire, nsteppos, dt_curr, alpha
     CLOSE( UNIT = 4, STATUS = 'KEEP' )
  ELSE
     CLOSE( UNIT = 4, STATUS = 'DELETE')
  ENDIF

  ! ...Convert the dR given by ARTn to forces
  call move_mode( nat, order, force, vel, etot_fire, nsteppos, &
       dt_curr, alpha, fire_alpha_init, dt_init, disp, displ_vec )

  ! ...Clean ARTn
  IF( lconv )THEN
     ! Set the force threshold of qe to that of pARTn
     epsf_qe = forc_thr
     call clean_artn()
  ENDIF
  !
  ! write the FIRE parameters to its scratch file
  !
  OPEN( unit = 4, file = filnam, form = 'formatted', status = 'unknown', iostat = ios)
  IF ( qe_version >= 7.2)  WRITE( UNIT = 4, FMT = * )   fire_restart
  WRITE( UNIT = 4, FMT = * )   etot_fire, nsteppos, dt_curr, alpha
  !
  CLOSE( UNIT = 4, STATUS = 'KEEP' )
  !

END SUBROUTINE artn_QE
