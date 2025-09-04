!> @author Damien Connétable,
!! @author Miha Gunde
!! @author Antoine Jay
!
!> @brief 
!! Interface between VASP and ARTn:
!
!> @par Purpose
!  ============
!> Read if ARTn is active (at the first step only)
!! CAll artn_step to know the displacement
!! Perform the displacement
!
!> @param[in,out]   force         force calculated by the engine
!! @param[in]       etot = toten  total energy calculated by the engine 
!! @param[in]       T_INFO        Pointor to info natoms, types, ionic pos
!! @param[in]       INFO          Pointor that contains LSTOP (stops VASP)
!! @param[in]       dyn           Pointor to atomic positions
!! @param[in]       latt_cur      current step
!! @param[in]       nstep         current step
!! @param[in]       IO            current step
!
!> @ingroup Interface
!> @snippet artn_step.f90  VASP

MODULE ARTparam
   LOGICAL                   :: ARTN_is_active
   LOGICAL                   :: ARTN_PRINT
END MODULE 

!------------------------------------------------------------------------------
SUBROUTINE ARTN_VASP( force, etot, T_INFO, INFO, dyn, latt_cur, nstep, IO )
!------------------------------------------------------------------------------
! VASP modules: 
USE prec,         ONLY : q 
USE POSCAR,       ONLY : TYPE_INFO, DYNAMICS 
USE BASE,         ONLY : in_struct, INFO_STRUCT 
USE lattice 
USE mpi
! internal module:
USE ARTparam
! ARTn modules:
USE m_artn
USE m_artn_step,  ONLY : artn_step
USE m_setup_artn, ONLY : clean_artn

IMPLICIT NONE
! ... Fonction Parameters
TYPE(TYPE_INFO),    INTENT(IN)    :: T_INFO                       ! contains inFORMATions about the atomic positions
TYPE(latt),         INTENT(IN)    :: latt_cur                     ! current lattice real and rez.
TYPE(in_struct),    INTENT(IN)    :: IO                           ! contains the number IO%IU6 
REAL(q),            INTENT(IN)    :: etot                         ! force calculated by the engine == toten
INTEGER,            INTENT(IN)    :: nstep                        ! current ionic step from VASP
TYPE(INFO_STRUCT),  INTENT(INOUT) :: INFO                         ! Contains types
TYPE(DYNAMICS),     INTENT(INOUT) :: DYN                          ! contains forces 
REAL(q),            INTENT(INOUT) :: force(3,T_INFO%nions)        ! force calculated by the engine == TIFOR 
!
! ... Internal variables
INTEGER,     ALLOCATABLE          :: if_pos(:,:)                  !< @brief  coordinates fixed by engine  (3, nat)
REAL(q)                           :: conv_ions                    !< @brief  force convergence threshold of the engine
LOGICAL                           :: lconv                        !< @brief  flag for controlling convergence 
INTEGER                           :: i, j, iat                    !> @brief  some counters 
LOGICAL                           :: debug                        !< @brief  flag to print info in debug mode 
!
! ... Artn subroutine variables
REAL(q)                           :: ARTN_posion(3,T_INFO%nions)  !< @brief atomic position converted in bohr
REAL(q)                           :: displ_vec(3,T_INFO%nions)    !< @brief displacements in ua
REAL(q)                           :: Einit                        !< @brief initial energy
!
REAL(q), PARAMETER                :: RY2EV = 13.605691930242388   !< @brief Ry to eV conversion
REAL(q), PARAMETER                :: B2A   = 0.529177210903_q     !< @brief bohr to angstrom
!
! ... Temporary parameters used in the RDATAB call to read VASP ARTN parameters
INTEGER                           :: IDUM, ierr, N
CHARACTER*1                       :: CHARAC
COMPLEX(q)                        :: CDUM
LOGICAL                           :: LDUM
REAL(q)                           :: RDUM
!
! ... MPI Varibles
INTEGER                           :: rank                         !< @brief Rank of each MPI process
LOGICAL                           :: is_mpi                       !< @brief logical value to know if MPI job is done

! ... MPI initialization
rank = 0
call MPI_INITIALIZED ( is_mpi, ierr)
IF ( is_mpi )   call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)

! ... Call RDATAB to read the INCAR file and extract ARTNis_active value
IF (nstep == 1) THEN
  !   
  ARTN_is_active = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ARTN_is_active','=','#',';','L', &
       & IDUM,RDUM,CDUM,ARTN_is_active,CHARAC,N,1,IERR) !from lib/drdatab.f
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
    IF (IO%IU0>=0) WRITE(IO%IU0,*) &
        'Error reading item ''ARTN_is_active'' from file INCAR.'
    STOP
  END IF

  ARTN_PRINT = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ARTN_PRINT','=','#',';','L', &
       & IDUM,RDUM,CDUM,ARTN_PRINT,CHARAC,N,1,IERR)
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
     IF (IO%IU0>=0) WRITE(IO%IU0,*) &
         'Error reading item ''ARTN_PRINT'' from file INCAR.'
     STOP
  END IF
  !
END IF ! End of read INCAR at the first step 

! ... Enter here only if ART is used
IF ( ARTN_is_active )  THEN
  IF ( rank == 0 .AND. ARTN_PRINT )   WRITE(IO%IU6,'(A)') "ARTn is active"

  ! ... Transform VASP fix atoms (bolean) into if_pos (0 or 1)
  ALLOCATE (if_pos(3,T_INFO%nions))
  if_pos(:,:) = 1         ! default = all free
  IF (T_INFO%lsdyn) THEN
    DO iat= 1, T_INFO%nions
      DO i= 1, 3
        IF (.NOT.T_INFO%lsfor(i,iat)) if_pos(i,iat) = 0
      END DO
    END DO
  END IF

  ! ... Set engine convergence to tiny value so it does not stop before ARTn
  IF (nstep == 1)  DYN%EDIFFG = -1.0e-13

  ! ... VASP atomic position are in direct (=crystaline). Set them to angstrom for ARTn 
  CALL KARDIR(T_INFO%nions, DYN%POSION, TRANSPOSE(LATT_CUR%A))

  ! ... Call artn to obtain the displacement vector. Only Master proc enters here
  IF (rank == 0) THEN
    CALL artn_step(T_INFO%nions, etot, force, T_INFO%ityp, DYN%POSION, &
                   LATT_CUR%A, if_pos, displ_vec, lconv)
    IF ( lconv ) CALL clean_artn()
  ENDIF
  
  ! ... Send the calculated displ_vec and lconv flag to other processes
  IF ( is_mpi ) THEN
    CALL mpi_bcast(displ_vec, 3*T_INFO%nions, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    CALL mpi_bcast(lconv, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr )
  END IF

  ! ... FOR DEBUG: Save atomic positions, forces and displacement in a separated file
  IF ( ARTN_PRINT .AND. rank == 0) THEN
    IF ( nstep == 1 ) THEN
        OPEN(UNIT=656, FILE='ARTVASP.xyz', STATUS='replace')
        Einit = etot
     else 
        OPEN(UNIT=656, POSITION='append', FILE='ARTVASP.xyz')
    END IF
    WRITE(656, *) T_INFO%nions
    WRITE(656,221) 'Lattice="', LATT_CUR%A(:,:),'"', &
     & ' Properties=species:S:1:pos:R:3:forces:R:3:disp:R:3:id:I:1', &
     & ' Energy="', etot, '" eV, Step= "', nstep, '"' 
    DO iat=1, T_INFO%nions
       WRITE(656,222) T_INFO%ityp(iat), (DYN%POSION(i,iat), i=1,3), &
          & (force (i,iat), i=1,3), (displ_vec(i,iat), i=1,3), iat
    END DO
    CLOSE(656)
  END IF

  221 format(a,1x,9(f0.4,1x),a,a,a,f0.9,a,I5,a)
  222 format(i3,3(F14.6,1x),3X,3(F14.6,1x),3x,3(F14.6,1x),1x,I5)

  ! ... IF artn finishes, say VASP to stop with LSTOP flag
  IF (lconv) THEN
    IF (rank == 0) WRITE(IO%IU0,'(/5x,"ARTn converged: ",i0/)') nstep
    INFO%LSTOP = .TRUE.
  ELSE
    ! 
    ! ... Apply displacement: positions and displ are both in Angstrom (VASP units)
    DYN%POSION = DYN%POSION + displ_vec

    ! ... Convert Angstroms to DIRECT (=crystaline) to be back in VASP standard
    CALL KARDIR(T_INFO%nions, DYN%POSION, TRANSPOSE(LATT_CUR%B))
    DYN%POSIOC    = DYN%POSION ! transfer the new positions to old positions
    T_INFO%POSION = DYN%POSION ! transfer the new positions to this redundant place
  END IF

ELSE ! ARTn is not active
  IF (nstep == 1 .AND. rank == 0 .AND. debug) WRITE(IO%IU6,*) "ARTn not active"
END IF
!
END SUBROUTINE ARTN_VASP


