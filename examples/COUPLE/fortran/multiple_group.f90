PROGRAM multiple_single
  USE mpi_f08
  USE liblammps
  USE f_partn

  IMPLICIT NONE
  ! MPI variables
  INTEGER                   :: igroup, ngroup, iproc, nproc, me, key, ierr
  TYPE( MPI_Request )       :: requestA, requestB
  TYPE( MPI_Comm )          :: lmp_comm
  TYPE( MPI_Status )        :: statusA
  LOGICAL                   :: messageOK
  ! Extracted variables
  CHARACTER(:), ALLOCATABLE :: errmsg
  LOGICAL                   :: err
  INTEGER                   :: ninfl, nforc
  REAL                      :: dr1, dr2
  REAL                      :: einit, esad, emin1, emin2
  ! ARTN and LAMMPS API variables
  TYPE( lammps )            :: lmp
  TYPE( t_partn )           :: artn
  CHARACTER(len=*), dimension(*), parameter :: args = &
       [ character(len=12) :: 'liblammps','-log', 'none','-screen','none' ]
  CHARACTER(:), ALLOCATABLE :: fout
  !real, dimension(4,343)    :: addconst
  INTEGER                   :: nevents, ievent, ievent_previous

  ! These 2 variables should be arguments if this program becomes a subroutine
  ngroup=3
  nevents=10
  
  !
  !... MPI initialization and definitions 
  CALL mpi_init( ierr )
  CALL mpi_comm_size( MPI_COMM_WORLD, nproc, ierr )
  CALL mpi_comm_rank( MPI_COMM_WORLD, me,    ierr )

  !
  !... Split the processes in search groups
  IF (me==0) THEN
     IF (ngroup>nproc) THEN
        PRINT *, "ERROR: the number of groups is bigger than the number of process"
        STOP
     ENDIF
     DO iproc=0, nproc-1
       PRINT *, "PROC=", iproc, "GROUP=", MOD(iproc,ngroup), "key=", iproc/ngroup
     ENDDO
  ENDIF
  CALL MPI_Barrier(MPI_COMM_WORLD)
  igroup = MOD(me, ngroup)
  key=me/ngroup
  CALL mpi_comm_split( MPI_COMM_WORLD, igroup, key, lmp_comm, ierr )

  !
  !... Open API pointors to LAMMPS AND ARTN   
  lmp = lammps( comm = lmp_comm% mpi_val, args = args )
  artn = t_partn()
  
  !
  !... Set ARTN parameters that are common for all searches
  CALL artn% set( "engine_units", "lammps/metal")
  CALL artn% set( "verbose", 0 )
  CALL artn% set( "restart_freq", 0 )
  CALL artn% set( "ninit", 2)
  CALL artn% set( "lpush_final", .true. )
  CALL artn% set( "nnewchance", 50)
  CALL artn% set( "forc_thr", 0.002 )
  CALL artn% set( "nperp_limitation", [3,6,8,-1] )
  CALL artn% set( "struc_format_out","xyz" )
  CALL artn% set( "nevalf_max", 99999 )
  CALL artn% set( "etot_diff_limit", 200.0 )
  CALL artn% set( "push_mode", "list" )
  CALL artn% set( "push_step_size", 1.0 )
  CALL artn% set( "push_ids", [1,2,3,4,5,6,7])
  ! addconst(:,:) = 0.0
  ! addconst(:,1) = [0.0, 1.0, 0.0, 45.0 ]
  ! CALL artn% set( "push_add_const", addconst)

  !
  !... Set LAMMPS parameters that are common for all searches
  CALL lmp% command( "units metal" )
  CALL lmp% command( "dimension 3" )
  CALL lmp% command( "atom_modify sort 0 1" )
  CALL lmp% command( "read_data   pt111_heptamer.in" )
  CALL lmp% command( "comm_style tiled")
  CALL lmp% command( "balance 1.1 rcb")
  CALL lmp% command( "region rb block 0.0 19.2088 0.0 19.2088 0.0 6.0" )
  CALL lmp% command( "group bottom region rb" )
  CALL lmp% command( "fix 1 bottom setforce 0.0 0.0 0.0" )
  CALL lmp% command( "pair_style morse/smooth/linear 9.5" )
  CALL lmp% command( "pair_coeff * * 0.7102 1.6047 2.897" )
  CALL lmp% command( "plugin load ../../../lib/libartn-lmp.so" )
  CALL lmp% command( "fix 10 all artn dmax 8.0" )
  CALL lmp% command( "min_style fire" )
  ! CALL lmp% command( "timestep 0.0002" )

  !
  !... This is the do loop over the events
  ievent= igroup ! Initialization
  LIST_OF_EVENTS_:  DO WHILE (ievent < nevents) 
     !
     !... Set parameters that depends on the seach (output files, starting vector...) 
     ALLOCATE( CHARACTER(LEN=20) :: fout )
     WRITE( fout, "(a9,i0)") "artn.out_", ievent
     CALL artn% set( "filout",     trim(fout) )
     WRITE( fout, "(a6,i0)") "initp_", ievent
     CALL artn% set( "initpfname", trim(fout) )
     WRITE( fout, "(a4,i0,a1)") "sad_", ievent,"_"
     CALL artn% set( "prefix_sad", trim(fout) )
     WRITE( fout, "(a4,i0,a1)") "min_", ievent, "_"
     CALL artn% set( "prefix_min", trim(fout) )
     ! This is commented because it writes a lot. If added don't forget to undump before next event
     !WRITE( fout, "(a,i0)") "config.dmp_", ievent
     !CALL lmp% command( "dump 10 all custom 1 "//trim(fout)//" id type x y z fx fy fz" )
     DEALLOCATE (fout)
   
     !... launch LAMMPS
     CALL lmp% command( "minimize 1e-3 1e-3 80000 80000" )
    
     !
     !... Only group masters enter here, the other processes wait at the barrier (bcast) bellow
     GROUP_MASTER: IF (key==0) THEN
        ! 
        !... Extract some values to analyse the connectivity 
        err = artn% extract( "has_error")
        IF( err ) THEN
           errmsg = artn% extract( "error_message" )
           WRITE(*,"(2x,a6,1x,i0,1x,a18,1x,a)")&
             "Search", ievent, "has error message:", errmsg 
        ELSE
           nforc  = artn% extract( "nevalf"      )
           dr1    = artn% extract( "delr_min1"   )
           dr2    = artn% extract( "delr_min2"   )
           einit  = artn% extract( "energy_init" )
           esad   = artn% extract( "energy_sad"  )
           emin1  = artn% extract( "energy_min1" )
           emin2  = artn% extract( "energy_min2" )
           ninfl  = artn% extract( "inewchance"  ) 
           IF( dr1 < 0.1 ) THEN
              WRITE(*,"(2x,a6,1x,i0,1x,a8,1x,i0,1x,a32,1x,f12.8)")&
              "Search", ievent, "by group", igroup, "found connected saddle, barrier:", esad-emin1
           ELSEIF( dr2 < 0.1 ) THEN
              WRITE(*,"(2x,a6,1x,i0,1x,a8,1x,i0,1x,a32,1x,f12.8)")&
              "Search",ievent, "by group", igroup, "found connected saddle, barrier:", esad-emin2
           ELSE
              WRITE(*,"(2x,a6,1x,i0,1x,a8,1x,i0,1x,a32,1x,f12.8, 1x,a4,1x,f12.8)")&
              "Search",ievent, "by group", igroup, "found not connected saddle, dr1=", dr1, "dr2=", dr2
           ENDIF
        ENDIF
        !
        !... Master receives from the other masters the indice of their event and conserve the biggest one
        ievent_previous=MAX(ievent, ngroup-1) ! for the first cycle 
        DO iproc= 0, nproc-1
           IF ( iproc /= me .AND. iproc/ngroup==0 ) THEN ! this node is an other group master
              messageOK=.TRUE.
              DO WHILE (messageOK) ! Do loop because this iproc has maybe send several updates of ievent
                 CALL MPI_Irecv( ievent, 1, MPI_INTEGER, iproc ,0 ,MPI_COMM_WORLD, requestA, ierr)
                 CALL MPI_Test(requestA, messageOK, statusA, ierr) ! Check if the ievent has been received
                 IF (ievent>ievent_previous) ievent_previous = ievent
                 IF (.NOT. messageOK) THEN  !In case no value is received as no one has been emited
                    CALL MPI_Cancel(requestA, ierr)  
                    CALL MPI_Request_free(requestA, ierr)
                 ENDIF   
              ENDDO
           ENDIF
        ENDDO
        ! 
        !... Update the indice  search
        ievent=ievent_previous+1  
        !... Master send to others masters its inidice as it is the new highest
        DO iproc= 0 , nproc-1 
           IF ( iproc /= me .AND. iproc/ngroup==0 ) THEN
               CALL MPI_Isend( ievent, 1, MPI_INTEGER, iproc, 0 ,MPI_COMM_WORLD, requestB, ierr )
           ENDIF    
        ENDDO
        !
     ENDIF GROUP_MASTER
     !
     !... All workers wait here that their group master send them its indice of the new TODO search
     CALL MPI_Bcast( ievent, 1, MPI_INTEGER, 0 , lmp_comm, ierr)
     !
  ENDDO LIST_OF_EVENTS_  
  !
  !... Finalize
  CALL lmp% CLOSE()
  CALL artn% CLOSE()
  CALL mpi_finalize( ierr )
  !
end program multiple_single
