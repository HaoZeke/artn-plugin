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
SUBROUTINE artn_step_vasp( force, etot, T_INFO, INFO, dyn, latt_cur, nstep, IO )
  !----------------------------------------------------------------------------
  !
!> [VASP]
  ! VASP modules: 
  use prec
  use POSCAR 
  use BASE 
  USE lattice
  ! 
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

  INTEGER IDUM,IERR,N
  CHARACTER*1 CHARAC
  COMPLEX(q) CDUM
  LOGICAL LDUM
  REAL(q) RDUM
  INTEGER :: nbatom


  !------------------------------------------------------------------------------------------------------------
  ! CHECK if added ARTn flagas work -- this part sould be written in OUTCAR!!
  !------------------------------------------------------------------------------------------------------------
  IU6 = IO%IU6
  IF (IU6>=0) THEN
      WRITE(IU6,*) "======================================================"
      WRITE(IU6,*) "            Hello, let's go"
      WRITE(IU6,*) "    We enter in the ARTn-vasp subroutine"
      WRITE(IU6,*) "    First, it is necessar to verify if ART flag is"
      WRITE(IU6,*) "       present in INCAR"
      WRITE(IU6,*) "Enrgy:",etot
      WRITE(IU6,*) "LSDYN:",T_INFO%LSDYN
      WRITE(IU6,*) "EDIFF:",INFO%EDIFF
      WRITE(IU6,*) "EDIFFG:",dyn%POSION
      WRITE(IU6,*) "LATT:", latt_cur%A
      WRITE(IU6,*) "NSTEP:",nstep
      WRITE(IU6,*) "IO:", IO
      WRITE(IU6,*) "======================================================"
  END IF
  

  !------------------------------------------------------------------------------------------------------------
  ! RDATAB subroutine in lib/drdatab.F
  ! extracts data form defined file (here INCAR) --
  ! in this form it writes an error if variables "ART|ARTinfo|ARTdebug" are not defined correctly in the INCAR
  ! use:  RDATAB(.TRUE.,'FILENAME',IO%IU5,'KEYWORD','seperator between KEYWORD and VALUE','COMMENT SIGN',&
  ! 'SEPERATOR OF VALUES','VALUE type',INTRES,FLTRES,CMPRES,LOGRES,STR,N,NMAX,IERR)
  ! INTRES,FLTRES,CMPRES,LOGRES,STR: VALUES depending on the type (I, F, C, L, S)
  !------------------------------------------------------------------------------------------------------------

  ART = .FALSE.
  CALL RDATAB(.TRUE.,'INCAR',IO%IU5,'ART','=','#',';','L', &
  &            IDUM,RDUM,CDUM,ART,CHARAC,N,1,IERR)
  IF (((IERR/=0).AND.(IERR/=3)).OR. ((IERR==0).AND.(N<1))) THEN
     IF (iu0>=0) WRITE(iu0,*) 'Error reading item ''ARTn'' from file INCAR.'
     STOP
  ENDIF

  !------------------------------------------------------------------------------------------------------------
  ! WRITING the value of ART and initilizing it if ART = .TRUE.'
  !------------------------------------------------------------------------------------------------------------

  IF (IU6>=0) THEN
      WRITE(IU6,'(A)') "======================================================"
      WRITE(IU6,*) " ART flag = ", ART
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

!     convert direct to Angstrom
      CALL KARDIR(T_INFO%nions, DYN%POSION, LATT_CUR%A)
!==================================================

      print*, "Positions before artn",  DYN%POSION(:,1)

      print*, " nb atom IN ARTn_VASP", T_INFO%nions
      print*, " go in ARTn ==> "
      print*, " * ARTn::CONV:: ", DYN%EDIFFG
      ! 
      call artn_VASP( IU6, force, etot, DYN%EDIFFG, T_INFO%nions, T_INFO%NTYP, T_INFO%ityp, nameAT, DYN%POSION, LATT_CUR%A, nstep, if_pos, lconv )

      print*, "Positions after artn",  DYN%POSION(:,1)

      CALL KARDIR(T_INFO%nions, DYN%POSION, LATT_CUR%B)
      WRITE(IU6,*) "EDIFFG after :",dyn%EDIFFG

      print*, "Positions after artn - crystal",  DYN%POSION(:,1)
      print*, "Force send to engine", force
!
      write(IU6,*) " atomic  positions (Ang),  forces (in eV/Ang), move "
  DO i=1, T_INFO%nions
     write(IU6,667) nameAT(i), DYN%POSION(:,i), force(:,i), if_pos(:,i)
  ENDDO
  WRITE(IU6,666)
  write(IU6,*) "eps       ! force convergence threshold of the engine ??"
  WRITE(IU6,666)
  ELSE
      WRITE(IO%IU6,*)  " ART unused, VASP is used normally"
      END IF
      
666    format("======================================================")
667    format(A3,3F12.5,3x,3F12.5,3x,3I4,3F12.5)

       END SUBROUTINE artn_step_vasp

