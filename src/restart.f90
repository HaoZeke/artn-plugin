
!---------------------------------------------------------------------------
!> @authors
!!   Matic Poberznik
!!   Miha gunde
!!   Nicolas Salles

!> @brief 
!!   Subroutine that writes the minimum parameters required for restart of a calculation
!!   to a file
!
!> @param[in]    filnres   restart filename
! 
!> @note 
!!   LOGICAL FLAGS: linit, lperp, leigen, llanczos, lsaddle, lrelax
!!   COUNTERS : istep, iinit, ilanc, ieigen, ismooth, nlanc
!!   ARRAYS:
!!   - LANCZOS: eigenvec, H, Vmat, force_old, lowest_eigval
!!   - (INIT/SADDLE/STEP): etot, tau, force (, current_step_size, fpush_factor)
!
SUBROUTINE write_restart( filnres )
  !
  use artn_params, only : linit, lperp, leigen, llanczos, lpush_over, lrelax, &
                          iartn, istep, iinit, ieigen, iperp, ilanc, irelax, ismooth,   &
                          ninit, neigen, nlanc, lanczos_max_size, nperp, nmin, nsaddle, &
                          etot_init, &
                          etot_step, tau_step, force_step, current_step_size, fpush_factor, &    !> Actual step
                          eigenvec, H, Vmat, force_old, lowest_eigval, &
                          etot_saddle, tau_saddle, iunartres

  implicit none

  CHARACTER(LEN=255), INTENT(IN) :: filnres
  INTEGER :: ios

  !print*, "WRITE_RESTART::", istep
  OPEN( UNIT = iunartres, FILE = filnres, ACTION="WRITE", FORM = 'formatted', STATUS = 'REPLACE', IOSTAT = ios)

  WRITE ( iunartres, * ) linit, lperp, leigen, llanczos, lpush_over, lrelax, &
       iartn, istep, iinit, ieigen, iperp, ilanc, irelax, ismooth,   &
       ninit, neigen, nlanc, lanczos_max_size, nperp, nmin, nsaddle, &
       etot_init, &
       etot_step, tau_step, force_step, current_step_size, fpush_factor, &    !> Actual step
       eigenvec, H, Vmat, force_old, lowest_eigval, &
       etot_saddle, tau_saddle

  CLOSE ( UNIT = iunartres, STATUS = 'KEEP')

END SUBROUTINE write_restart



!
!---------------------------------------------------------------------------
!> @brief
!!   Subroutine that reads the restart file, if a restart is requested
!
!> @param[in]   filnres     restart filename
!> @param[in]   nat         number of atoms
!> @param[in]   order       index order of atoms
!> @param[out]   ityp        type of atoms
!> @param[out]  ierr        flag for the error
!
!> @note
!!   LOGICAL FLAGS: lpush_init, lperp, leigen, llanczos, lsaddle, lrelax
!!   COUNTERS : istep, ipush, ilanc, ieigen, ismooth, nlanc
!!   ARRAYS: eigenvec, H, Vmat
!
!> @warning
!!   - Maybe doing a verification on the nat parameter in case...
!!   - All restart file are written ordered so having the array order() 
!!     in argument should not be needed here
!!   - order argument is not used in the routine
!!   - ityp is used in the routine
!
!SUBROUTINE read_restart( filnres, nat, order, ityp, ierr )
SUBROUTINE read_restart( filnres, nat, ityp, ierr )
  !
  use units, only : DP, unconvert_energy
  use artn_params, only : linit, lperp, leigen, llanczos, lpush_over, lrelax, &
                          iartn, istep, iinit, ieigen, iperp, ilanc, irelax, ismooth,   &
                          ninit, neigen, nlanc, lanczos_max_size, nperp, nmin, nsaddle, &
                          etot_init, &
                          etot_step, tau_step, force_step, current_step_size, fpush_factor, &    !> Actual step
                          eigenvec, H, Vmat, force_old, lowest_eigval, &
                          etot_saddle, tau_saddle, &
                          tau_init, initpfname, struc_format_out, elements, iunartres, iunartout, &
                          lat, push, types
  implicit none

  ! -- Arguments
  CHARACTER (LEN=255), INTENT(IN) :: filnres
  INTEGER, INTENT( IN ) :: nat
  !INTEGER, intent( in ) :: order(nat)
  INTEGER, intent( inout ) :: ityp(nat)   !> We change them or use them
  LOGICAL, intent( out ) :: ierr

  ! -- Local variable
  LOGICAL :: file_exists
  INTEGER :: ios
  CHARACTER(LEN=255) :: fname

  character(len=3) :: celt(nat)
  !INTEGER, allocatable :: itmp1(:), itmp2(:)
  REAL(DP) :: pos(3,nat)


  ! ...Verify if the file exist

  INQUIRE( file = filnres, exist = file_exists )
  ierr = .NOT.file_exists

  IF ( file_exists ) THEN


     ! ... Read the Restart file 

     OPEN( UNIT = iunartres, FILE = filnres, ACTION="READ", FORM = 'formatted', STATUS = 'old', IOSTAT = ios)
     IF( ios /= 0 )write(iunartout,*) "READ_RESTART::Cannot open file: ",trim(filnres) 

     READ( iunartres, * ) linit, lperp, leigen, llanczos, lpush_over, lrelax, &
       iartn, istep, iinit, ieigen, iperp, ilanc, irelax, ismooth,   &
       ninit, neigen, nlanc, lanczos_max_size, nperp, nmin, nsaddle, &
       etot_init, &
       etot_step, tau_step, force_step, current_step_size, fpush_factor, &   !> Actual step
       eigenvec, H, Vmat, force_old, lowest_eigval, &
       etot_saddle, tau_saddle

     CLOSE ( UNIT = iunartres, STATUS = 'KEEP')

     !> Maybe initialize de_back if needed


     ! ...Read the initial configuration => push, tau_init

     fname = TRIM(initpfname)//"."//TRIM(struc_format_out)
     INQUIRE( file = fname, exist = file_exists )
     ierr = .NOT.file_exists

     IF( file_exists )THEN
       WRITE(*,'(5x,"|> ARTn::RESTART:: init_structure file exist: ",a)') trim(initpfname)
       !if( .not.allocated(tau_init) )allocate( tau_init(3,nat), source=0.0_DP )

       celt = "XXX"
       call read_struct( lat, nat, pos, celt, ityp, push, struc_format_out, initpfname )
       !print*, ">>> READ"
       !do ios = 1,20
       !   print*, ios, pos(:,ios), tau_step(:,ios)
       !enddo

       !call write_struct( lat, nat, pos, celt, ityp, push, unconvert_energy( etot_init ), 1.0_DP, 200, struc_format_out, "initr" )
       !print*, ">>> WRITE"
       !do ios = 1,20
       !   print*, ios, pos(:,ios), tau_step(:,ios)
       !enddo

       ! .. Update the array
       tau_init = pos
       ityp = types

     ELSE
       WRITE(iunartout,*) "ARTn: initial conf file does not exist, exiting ...", fname
     ENDIF

  ELSE

     WRITE(iunartout,*) "ARTn: restart file does not exist, exiting ..."

  ENDIF


END SUBROUTINE read_restart

