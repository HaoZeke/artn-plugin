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
SUBROUTINE ARTN_VASP( force, etot, T_INFO, INFO, dyn, latt_cur, nstep, IO )
  !----------------------------------------------------------------------------
  !
!> [VASP]
  ! VASP modules: 
  use prec
  use POSCAR 
  use BASE 
  USE lattice
      !use m_artn_step

      IMPLICIT NONE
!=====================================================
  TYPE(TYPE_INFO),    INTENT(IN) ::    T_INFO           !  contains informations about the atomic positions
  TYPE(INFO_STRUCT),  INTENT(IN) ::    INFO             !  
  REAL(q),            INTENT(INOUT) :: force(3,T_INFO%nions)     !  force calculated by the engine == TIFOR 
  REAL(q),            INTENT(IN)    :: etot             !  force calculated by the engine == toten
  TYPE(DYNAMICS),     INTENT(INOUT) :: DYN              !  
  TYPE(latt),         INTENT(IN) ::    latt_cur         ! current lattice real and rez.
  TYPE(in_struct),    INTENT(IN) ::    IO               ! contains the number IU6 
  INTEGER,            INTENT(IN) ::   nstep  ! current ionic step (NSTEP)

  INTEGER,     AllOCATABLE   ::    ityp(:)        !  atom types
  INTEGER,     ALLOCATABLE   ::    if_pos(:,:)    !  coordinates fixed by engine  (3, nat)
  CHARACTER(len=3), ALLOCATABLE ::    nameAT(:)    ! name of each atom
  REAL(q) :: conv_ions          !  force convergence threshold of the engine
  LOGICAL :: lconv              !  flag for controlling convergence 
  LOGICAL                   :: file_exists, ART
  CHARACTER(len=256)        :: filnam
  INTEGER                   :: ios, i, disp
  INTEGER                   :: iu0, IU6
  INTEGER                   :: NI, NJ, j, k, iat
  REAL(q)                  :: displ_vec(3,T_INFO%nions)
      
  INTEGER IDUM,IERR,N
  CHARACTER*1 CHARAC
  COMPLEX(q) CDUM
  LOGICAL LDUM
  REAL(q) RDUM
  INTEGER :: nbatom


  IU6 = IO%IU6

  !------------------------------------------------------------------------------------------------------------
  ! RDATAB subroutine in lib/drdatab.F
  ! extracts data form defined file (here INCAR)
  !------------------------------------------------------------------------------------------------------------

  ART = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ARTN','=','#',';','L', &
  &            IDUM,RDUM,CDUM,ART,CHARAC,N,1,IERR)
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
     IF (iu0>=0) WRITE(iu0,*) 'Error reading item ''ARTN'' from file INCAR.'
     STOP
  ENDIF

  !------------------------------------------------------------------------------------------------------------
  ! WRITING the value of ART and initilizing it if ARTN = .TRUE.'
  !------------------------------------------------------------------------------------------------------------

  IF (IU6>=0) THEN
      WRITE(IU6,'(A)') "======================================================"
      WRITE(IU6,*) " ARTN flag = ", ART
      WRITE(IU6,'(A)') "======================================================"
  END IF

  IF ( ART )  THEN
      iu0=IO%IU0

  ! allow to extract information if some species are able to move
  !------------------------------------------------------------------------------------------------------------
  ! Extracting information for number of atoms in calculation and how many atoms of each type
  !------------------------------------------------------------------------------------------------------------     
      ALLOCATE(ityp(T_INFO%ntyp))
      nbatom = 0
      do i=1, T_INFO%NTYP
         ityp(i) =  0 !same as T_INFO%NITYP
         do j=1, T_INFO%NITYP(i)
            ityp(i) = ityp(i)+1
         end do
         nbatom = nbatom +  ityp(i)
      end do
      if ( nbatom .ne. T_INFO%nions ) print *, "Aie"
  !------------------------------------------------------------------------------------------------------------
  ! Naming ordered atom list -- nameAT(:nions)
  !------------------------------------------------------------------------------------------------------------
      ALLOCATE(nameAT(T_INFO%nions))
      iat = 1
      do i=1, T_INFO%NTYP
         do j=1, T_INFO%NITYP(i)
            nameAT(iat) = trim(T_INFO%TYPE(i))
            iat = iat+1
         end do
      end do
      
  !------------------------------------------------------------------------------------------------------------
  ! Locks atoms that are fixed; makes the forces 0 -- this is already done in VASP??
  !------------------------------------------------------------------------------------------------------------
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

      print*, "Positions before artn - crystal",  DYN%POSION(:,1)

!     convert crystal positions to Angstrom
      CALL KARDIR(T_INFO%nions, DYN%POSION, LATT_CUR%A)

!     set engine convergence to super small value so it does not intervene with ARTn
      if (nstep == 1) DYN%EDIFFG = -1e-8

!calling artn calculation
      call artn_step( T_INFO%nions, etot, force, T_INFO%ITYP, DYN%POSION, LATT_CUR%A, if_pos, displ_vec, lconv )

      DYN%POSION = DYN%POSION + displ_vec
      
!     convert Angstroms to VASP positions
      CALL KARDIR(T_INFO%nions, DYN%POSION, LATT_CUR%B)

!     increase engine convergence criteria if artn finishes
      if (lconv) then
         DYN%EDIFFG = 1.0
         print*, "ARTn convergence achieved"
      endif
      
      ELSE
         WRITE(IO%IU6,*)  " ART unused, VASP is used normally"
      END IF
      
666    format("======================================================")
667    format(A3,3F12.5,3x,3F12.5,3x,3I4,3F12.5)

       END SUBROUTINE ARTN_VASP

