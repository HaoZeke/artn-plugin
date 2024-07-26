! 
!> @author Damien Connétable,
!! @author Miha Gunde
!! @author Antoine Jay
!
!> @brief 
!!   Interface VASP /ARTn:
!
!> @par Purpose
!  ============
!>   We convert/compute/adapt some variables, 
!!   modifies the input force to perform the ARTn algorithm 
!
!> @param[in,out]   force              force calculated by the engine
!! @param[in]       etot = toten        total energy in current step
!! @param[in,out]   epsf_qe            force convergence threshold of the engine
!! @param[in]       T_INFO%NIONS       number of atoms
!! @param[in]       T_INFO%NTYP        number of atomic types
!! @param[in]       T_INFO%ITYP        atom types
!! @param[in]       T_INFO%TYPE        name of atom corresponding to ityp
!! @param[in,out]   T_INFO%POSION      atomic positions (needed for output only)
!! @param[in]       at                 lattice parameters in alat units
!! @param[in]       alat               lattice parameter of QE
!! @param[in]       istep              current step
!! @param[in]       if_pos             coordinates fixed by engine
!! @param[in,out]   vel                velocity of previous FIRE step
!! @param[in]       dt_init            default time step in FIRE
!! @param[in]       fire_alpha_init    initial value of alpha in FIRE
!! @param[out]      lconv              flag for controlling convergence
!
!> @ingroup Interface
!> @snippet artn_step.f90  VASP
!------------------------------------------------------------------------------
SUBROUTINE artn_step( force, etot, T_INFO, INFO, dyn, latt_cur, IO )
  !----------------------------------------------------------------------------
  !
!> [VASP]
  ! VASP modules: 
  use prec
  use POSCAR 
  use BASE 
  USE lattice
  ! VTST module
  use fire 
  !
  ! 
  IMPLICIT NONE
!=====================================================
  TYPE(TYPE_INFO),    INTENT(IN) ::    T_INFO           !  contains informations about the atomic positions
  TYPE(INFO_STRUCT),  INTENT(IN) ::    INFO             !  
  REAL(q),            INTENT(INOUT) :: force(3,T_INFO%nions)     !  force calculated by the engine == TIFOR 
  REAL(q),            INTENT(IN)    :: etot             !  force calculated by the engine == toten
  TYPE(DYNAMICS),     INTENT(INOUT) ::    DYN              !  
  TYPE(latt),         INTENT(IN) ::    latt_cur         ! current lattice real and rez.
  TYPE(in_struct),    INTENT(IN) ::    IO               ! contains the number IU6 

!)===================================================
  INTEGER,     AllOCATABLE   ::    ityp(:)        !  atom types
  INTEGER,     ALLOCATABLE   ::    if_pos(:,:)    !  coordinates fixed by engine  (3, nat)
!  INTEGER                    ::    ntyp           !  number of atomic types  T_INFO%NTYP
!  INTEGER                    ::    nat            !  number of atoms    == T_INFO%NIONS
  REAL(q)                    ::    at(3,3)        !  lattice parameters in alat units  == LATT_CUR%A
  REAL(q)                    ::    atinv(3,3)     !  lattice parameters in alat units  == LATT_CUR%B
  CHARACTER(len=3), ALLOCATABLE ::    nomAT(:)    ! name of each atom


  REAL(q) :: velocity(3,T_INFO%nions)       !  velocity of previous FIRE step
  REAL(q) :: epsf_qe          !  force convergence threshold of the engine
  REAL(q) ::    dt_init          !  default time step in FIRE  
  REAL(q) ::    fire_alpha_init  !  initial value of alpha in FIRE 
  INTEGER ::    istep            !  current step
  LOGICAL :: lconv              !  flag for controlling convergence 
!)===================================================
  !  
  !REAL(q)                  :: box(3,3)
  !REAL(q)                  :: pos(3,nat)
  REAL(q)                  :: etot_fire, dt_curr, alpha
  REAL(q)                  :: displ_vec(3,T_INFO%nions)
  INTEGER                   :: nsteppos, order(T_INFO%nions)

  LOGICAL                   :: file_exists
  CHARACTER(len=256)        :: filnam
  INTEGER                   :: ios, i, disp
  INTEGER                   :: iu0, IU6
  INTEGER                   :: NI, NJ, j, k, iat

  LOGICAL :: ART, ARTinfo, ARTdebug
  CHARACTER(len=256) :: prefART
  INTEGER IDUM,IERR,N
  CHARACTER*1 CHARAC
  COMPLEX(q) CDUM
  LOGICAL LDUM
  REAL(q) RDUM
  real(q) :: dt
  INTEGER :: nbatom


  !------------------------------------------------------------------------------------------------------------

  !------------------------------------------------------------------------------------------------------------
  IU6 = IO%IU6
  IF (IU6>=0) THEN
      WRITE(IU6,'(A)') "======================================================"
      WRITE(IU6,'(A)') "            Hello, let's go"
      WRITE(IU6,'(A)') "    We enter in the ARTn-vasp subroutine"
      WRITE(IU6,'(A)') "    First, it is necessar to verify if ART flag is"
      WRITE(IU6,'(A)') "       present in INCAR"
      WRITE(IU6,'(A)') "======================================================"
  END IF
  
!=========================================================================
  !we first test if ART flag is true, to know if we use the ARTn plugin 
!=========================================================================
  ART = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ART','=','#',';','L', &
&            IDUM,RDUM,CDUM,ART,CHARAC,N,1,IERR)
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
      IF (iu0>=0) WRITE(iu0,*) 'Error reading item ''ARTn'' from file INCAR.'
           STOP
  ENDIF
  
  ARTinfo = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ARTinfo','=','#',';','L', &
&            IDUM,RDUM,CDUM,ARTinfo,CHARAC,N,1,IERR)
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
      IF (iu0>=0) WRITE(iu0,*) 'Error reading item ''ARTinfo'' from file INCAR.'
           STOP
  ENDIF

  ARTdebug = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ARTdebug','=','#',';','L', &
&            IDUM,RDUM,CDUM,ARTdebug,CHARAC,N,1,IERR)
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
      IF (iu0>=0) WRITE(iu0,*) 'Error reading item ''ARTdebug'' from file INCAR.'
           STOP
  ENDIF

  prefART = "input"
  CALL RDATAB(.TRUE.,INCAR,IO%IU5,'prefART','=','#',';','S', &
     &            IDUM,RDUM,CDUM,LDUM,prefART,N,40,IERR)
  IF ((IERR/=0).AND.(IERR/=3)) THEN
      IF (IU0>=0) &
         WRITE(IU0,*)'Error reading item ''prefART'' from file INCAR.'
         STOP 
  ENDIF
!=========================================================================
!=========================================================================


  IF (IU6>=0) THEN
      WRITE(IU6,'(A)') "======================================================"
      WRITE(IU6,'(A,L1)') " ART flag = ", ART
      WRITE(IU6,'(A)') "======================================================"
  END IF

  IF ( ART )  THEN
      iu0=IO%IU0

      ! allow to extract information if some species are able to move
      ALLOCATE(ityp(T_INFO%ntyp))
      nbatom = 0
      do i=1, T_INFO%NTYP
         ityp(i) =  0
         do j=1, T_INFO%NITYP(i)
            ityp(i) = ityp(i)+1
         end do
         nbatom = nbatom +  ityp(i)
      end do
      if ( nbatom .ne. T_INFO%nions ) print *, "Aie"

      ALLOCATE(nomAT(T_INFO%nions))
      iat = 1
      do i=1, T_INFO%NTYP
         do j=1, T_INFO%NITYP(i)
            nomAT(iat) = trim(T_INFO%TYPE(i))
            iat = iat+1
         end do
      end do
      !DO NI = 1, T_INFO%nions
      !   ityp(NI) = 1
      !END DO

      ! Make vector to zero out force on frozen atoms 
      ALLOCATE(if_pos(3,T_INFO%nions))
      if_pos(:,:) = 1
      IF(T_INFO%LSDYN) THEN
           DO NI = 1, T_INFO%nions
             DO NJ = 1,3
               IF (.NOT.T_INFO%LSFOR(NJ,NI)) if_pos(NJ,NI) = 0
             ENDDO
           ENDDO
      ENDIF

      !==================================================
      ! zero out any added forces on frozen atoms
      ! atomic constraints in direct coordinates, thanks to Christopher Stihl
      CALL KARDIR(T_INFO%nions, force, LATT_CUR%B)
      force = force*if_pos
      CALL DIRKAR(T_INFO%nions, force, LATT_CUR%A)
      !==================================================
      ! convert direct to Angstrom
      CALL KARDIR(T_INFO%nions, DYN%POSION, LATT_CUR%A)
      !==================================================

      print*, " nb atom IN ARTn_VASP", T_INFO%nions
      print*, " go in ARTn ==> "
      !print*, " * ARTn_QE::CONV:: ", epsf_qe
      ! 
    !call artn_VASP( ARTinfo, ARTdebug, IU6, force, etot, DYN%EDIFFG, T_INFO%nions, T_INFO%NTYP, T_INFO%ityp, nomAT, DYN%POSION, LATT_CUR%A, istep, if_pos,   &
    call artn_VASP( ARTinfo, ARTdebug, IU6, force, etot, DYN%EDIFFG, T_INFO%nions, T_INFO%NTYP, ityp, nomAT, DYN%POSION, LATT_CUR%A, istep, if_pos,   &
                   velocity, dt_init, fire_alpha_init, lconv, prefART )

      CALL KARDIR(T_INFO%nions, DYN%POSION, LATT_CUR%B)
       !
     !!CALL FIRE_MODIFIED_DATA

  ELSE
      WRITE(IO%IU6,*)  " ART unused, VASP is used normally"
  END IF   

END SUBROUTINE artn_step

