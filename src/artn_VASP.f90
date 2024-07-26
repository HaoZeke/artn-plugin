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
!! @param[in]       vasp_istep              current step
!! @param[in]       if_pos             coordinates fixed by engine
!! @param[in,out]   vel                velocity of previous FIRE step
!! @param[in]       dt_init            default time step in FIRE
!! @param[in]       fire_alpha_init    initial value of alpha in FIRE
!! @param[out]      lconv              flag for controlling convergence
!
!> @ingroup Interface
!> @snippet artn_VASP.f90  VASP
!------------------------------------------------------------------------------
SUBROUTINE artn_VASP(iu, engforce, etot, epsf_qe, nat, ntyp, ityp, atm, tau, at, vasp_istep, if_pos, lconv)
  !----------------------------------------------------------------------------
  !
!> [VASP]
  USE precision, ONLY : DP
  USE artn_params, ONLY: forc_thr, elements, istep
  use m_setup_artn
  use m_artn_step
  use m_fire, ONLY: fire_init
  !
  ! 
  IMPLICIT NONE
!=====================================================
!=====================================================
  INTEGER,            INTENT(IN)    :: nat            !  number of atoms    == T_INFO%NIONS
  REAL(dp),           INTENT(INOUT) :: engforce(3,nat)     !  force calculated by the engine == TIFOR 
  REAL(dp),           INTENT(IN)    :: etot             !  force calculated by the engine == toten
  REAL(dp),           INTENT(INOUT) :: epsf_qe          !  force convergence threshold of the engine
  INTEGER,            INTENT(IN)    ::    ntyp           !  number of atomic types  T_INFO%NTYP
  INTEGER,            INTENT(INOUT) ::    ityp(nat)        !  atom types
  CHARACTER(LEN=3),   INTENT(IN)    :: atm(nat)              !  name of atom corresponding to ityp
  REAL(DP),           INTENT(INOUT) :: tau(3,nat)       !  atomic positions
  REAL(dp),           INTENT(IN)    ::    at(3,3)        !  lattice parameters in alat units  == LATT_CUR%A
  INTEGER,            INTENT(IN)    ::    vasp_istep            !  current step
  INTEGER,            INTENT(IN)    ::    if_pos(3,nat)    !  coordinates fixed by engine  (3, nat)
  LOGICAL,            INTENT(OUT) :: lconv              !  flag for controlling convergence 
  INTEGER,            INTENT(IN) :: iu
!)===================================================
  !  
  !REAL(dp)                  :: box(3,3)
  REAL(dp)                  :: pos(3,nat), force(3,nat)
  !REAL(dp)                  :: etot_fire, dt_curr
  REAL(dp)                  :: displ_vec(3,nat)
  INTEGER                   ::  order(nat), check_fire

  LOGICAL                   :: lerror
  !CHARACTER(len=256)        :: filnam
  INTEGER                   :: i
  INTEGER                   :: IU6
  INTEGER                   :: NI, NJ, j, k

  write(IU,'(A,I3)') " nber of atoms = ", nat
  write(IU,*) " nber of type of atoms:", ntyp
  write(IU,'(A,F15.8)') " energy of the system (in eV) = ", etot
  WRITE(IU,666)
  WRITE(IU,666)
  write(IU,*) " atom  = ", (ityp(i), i=1, ntyp)
  WRITE(IU,666)
  WRITE(*,*) " box = "
  WRITE(*,'(F12.5,F12.5,F12.5)') at
  WRITE(IU,666)
  write(IU,*) " atomic  positions (Ang),  forces (in eV/Ang) move, velocity= "
  DO i=1, nat
     write(IU,667) atm(i), tau(:,i), engforce(:,i), if_pos(:,i)
  ENDDO
  WRITE(IU,666)
  write(IU,*) epsf_qe,       "! force convergence threshold of the engine ??"
  WRITE(IU,666)
  !write(IU,*) "dt         !  default time step in FIRE  = ", dt_init
  !fire_alpha_init = alpha_start
  !write(IU,*) "fire_alpha_init !  initial value of alpha in FIRE= ", fire_alpha_init
  write(IU,*) "lconv !  flag for controlling convergence  !logical= ", lconv
  !write(IU,*) "prefix    !  prefix for scratch files of engine ", prefix
  WRITE(IU,666)

  print*, " * IN ARTn_VASP"
  print*, " * step",  vasp_istep, "VASP convergence:", epsf_qe
  !print*, " * ARTn_QE::CONV:: ", epsf_qe
  !
  
  do i = 1,nat
     order(i) = i
  enddo
  
  !! the elements array
  if( allocated(elements) )then
     if( size(elements, 1) /= ntyp ) deallocate(elements)
  end if
  IF ( .not. ALLOCATED(elements) ) ALLOCATE( elements(ntyp), source = "XXX")

  DO j=1, ntyp
        elements(j) = atm(j)
  ENDDO
  print*, "Elements:", elements(:)

  call setup_artn2( nat, lerror )
  print*, lerror
  if( lerror ) then
     call err_write(__FILE__,__LINE__)
     call merr(__FILE__,__LINE__,kill=.true.)
     return
  end if
  
  if ( vasp_istep == 1 ) then
     !! initialize current values for dt and alpha
     !! dt is now in units of ARTn (AU)
       check_fire=fire_init()
       print*, "Check fire", check_fire
  end if

  !print*, "Calling artn_step"
  pos=tau
  force=engforce
  
  call artn_step( nat, etot, force, ityp, pos, at, if_pos, displ_vec, lconv )
  !print*, "Outside artn_step"
     ! Does not work with force = convert_force(force) 
     !!  After artn() because has to read the artn input to know forc_thr
  !if( epsf_qe < forc_thr )then
  
  !write(*,*) "first 3 coor before"
  !write(*,*) tau(:,1)
  !write(*,*) tau(:,2)
  !write(*,*) tau(:,3)
  
  !displ_vec is in already converted in artn step
  tau = tau + displ_vec
 

  !write(*,*) "first 3 coor"
  !write(*,*) tau(:,1)
  !write(*,*) tau(:,2)
  !write(*,*) tau(:,3)

  !if ( vasp_istep == 0  ) epsf = 1d-10 change the threshold?
     if( epsf_qe /= forc_thr )then
            write( *,* ) "WARNING:: VASP force threshold is different than ARTn", epsf_qe, forc_thr
            !epsf_qe = forc_thr  
     endif     

     ! ...Clean ARTn
     !lconv=.TRUE.
     IF( lconv ) call clean_artn()
     !
     ! write the FIRE parameters to its scratch file
     ! 
  !
  !> [VASP]
  !

666    format("======================================================")
667    format(A3,3F12.5,3x,3F12.5,3x,3I4,3F12.5)

END SUBROUTINE artn_VASP

