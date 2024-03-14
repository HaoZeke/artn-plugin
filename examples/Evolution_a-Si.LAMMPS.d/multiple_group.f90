PROGRAM multiple_group
# ifdef MPIF08
   USE mpi_f08
# else
   use mpi
# endif
  USE liblammps
  USE f_partn

  IMPLICIT NONE
  ! MPI variables
  INTEGER                   :: igroup, ngroup, iproc, nproc, me, key, ierr
# ifdef MPIF08
   TYPE( MPI_Request )       :: requestA, requestB
   TYPE( MPI_Comm )          :: lmp_comm
# else
   INTEGER                  :: requestA, requestB, lmp_comm
# endif
  LOGICAL                   :: messageOK
  ! Extracted variables
  CHARACTER(:), ALLOCATABLE :: errmsg
  LOGICAL                   :: err, errsad, errmin1, errmin2
  INTEGER                   :: ninfl, nforc
  REAL                      :: dr1, dr2, drS
  REAL                      :: einit, esad, emin1, emin2
  ! ARTN and LAMMPS API variables
  TYPE( lammps )            :: lmp
  TYPE( t_partn )           :: artn
  CHARACTER(len=*), dimension(*), parameter :: args = &
       [ character(len=12) :: 'liblammps','-log', 'none','-screen','none' ]
  CHARACTER(:), ALLOCATABLE :: fout
  ! real, dimension(4,343)    :: addconst
  ! Local variables
  INTEGER                   :: nevents, ievent, ievent_previous
  LOGICAL                   :: connect

  !
  ! These 2 variables should be arguments if this program becomes a subroutine
  ngroup=1
  nevents=3000
  
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
  CALL MPI_Barrier(MPI_COMM_WORLD, ierr )
  igroup = MOD(me, ngroup)
  key=me/ngroup
  CALL mpi_comm_split( MPI_COMM_WORLD, igroup, key, lmp_comm, ierr )

  !
  !... Open API pointors to LAMMPS AND ARTN   
# ifdef MPIF08
    lmp = lammps( comm = lmp_comm% mpi_val, args = args )
# else
    lmp = lammps( comm = lmp_comm, args = args )
# endif
  artn = t_partn()
  
  !
  !... Set ARTN parameters that are common for all searches
  artn = t_partn()
  CALL artn% set( "engine_units"     , "lammps/metal"  )
  CALL artn% set( "verbose"          , 0               )
  CALL artn% set( "restart_freq"     , 0               )
  CALL artn% set( "ninit"            , 0               )
  CALL artn% set( "lpush_final"      , .TRUE.          )
  CALL artn% set( "nnewchance"       , 100             )
  CALL artn% set( "forc_thr"         , 0.0001          )
  CALL artn% set( "nsmooth"          , 0               )
  CALL artn% set( "nperp_limitation" , [4,10,15,20,25,30,35,-1] )
  CALL artn% set( "struc_format_out" , "none"          )
  CALL artn% set( "nevalf_max"       , 99999           )
  CALL artn% set( "push_mode"        , "rad"           )  ! Initial push
  CALL artn% set( "push_step_size"   , 0.1             )
  CALL artn% set( "push_ids"         , [449]           )
  CALL artn% set( "push_dist_thr"    , 3.5             )
  CALL artn% set( "lanczos_disp"     , 0.005           )  ! Lanczos 
  CALL artn% set( "lanczos_min_size" , 5               )
  CALL artn% set( "lanczos_max_size" , 50              )
  CALL artn% set( "eigval_thr"       , -0.01           )
  CALL artn% set( "eigen_step_size"  , 0.1             )
  CALL artn% set( "push_over"        , 6.0             )
  ! addconst(:,:) = 0.0
  ! addconst(:,1) = [0.0, 1.0, 0.0, 45.0 ]
  ! CALL artn% set( "push_add_const", addconst)

  !
  !... Set LAMMPS parameters that are common for all searches
  CALL lmp% command( "clear" )
  CALL lmp% command( "units metal" )
  CALL lmp% command( "dimension 3" )
  CALL lmp% command( "atom_style atomic" )
  CALL lmp% command( "atom_modify sort 0 1" )
  CALL lmp% command( "read_data   conf.sw" )
  CALL lmp% command( "comm_style tiled")
  CALL lmp% command( "balance 1.1 rcb")
  CALL lmp% command( "pair_style sw" )
  CALL lmp% command( "pair_coeff * * Si.sw Si" )
  CALL lmp% command( "mass 1 29.0" )
  CALL lmp% command( "neighbor 2.0 bin" )
  CALL lmp% command( "neigh_modify delay 10 check yes" )
  CALL lmp% command( "plugin load ../../lib/libartn-lmp.so" )
  CALL lmp% command( "fix 10 all artn alpha0 0.2 dmax 0.5" )
  CALL lmp% command( "timestep 0.002" )
  CALL lmp% command( "min_style fire" )

  !
  !... This is the do loop over the events
  IF (me==0) WRITE(*,"(a)") " iEv group Connect  Nforc Ninfl     DEsad     DRSad      DEMin1    DRMin1      DEMin2    DRMin1"
  ievent= igroup ! Initialization
  LIST_OF_EVENTS_:  DO WHILE (ievent < nevents)
     !
     !... Set parameters that depends on the seach (output files, starting vector...) 
     ALLOCATE( CHARACTER(LEN=20) :: fout )
     CALL artn% set( "zseed"      , 10000*ievent )
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
     CALL lmp% command( "delete_atoms group all" )
     CALL lmp% command( "read_data conf.sw add append" )
     CALL lmp% command( "minimize 0.0 1e-8 30000 30000" )
     !CALL lmp% command( "undump 10 " )
    
     !
     !... Only group masters enter here, the other processes wait at the barrier (bcast) bellow
     GROUP_MASTER: IF (key==0) THEN
        ! 
        !... Extract some values to analyse the connectivity
        err     = artn% extract( "has_error" )
        errsad  = artn% extract( "has_sad"   ) 
        errmin1 = artn% extract( "has_min1"  )
        errmin2 = artn% extract( "has_min2"  )
        IF( err ) THEN
           errmsg = artn% extract( "error_message" )
           WRITE(*,"(2x,a6,1x,i0,1x,a18,1x,a)") "Search", ievent, "has error message:", errmsg
        ELSEIF( (.NOT. errsad) .OR. (.NOT. errmin1) .OR. (.NOT. errmin2) ) THEN
           WRITE(*,"(2x,a6,1x,i0,1x,a33)") "Search", ievent, "has error message: TOO MUCH STEPS" 
        ELSE
           nforc   = artn% extract( "nevalf_sad"  )
           dr1     = artn% extract( "delr_min1"   )
           dr2     = artn% extract( "delr_min2"   )
           drS     = artn% extract( "delr_sad"    )
           einit   = artn% extract( "energy_init" )
           esad    = artn% extract( "energy_sad"  )
           emin1   = artn% extract( "energy_min1" )
           emin2   = artn% extract( "energy_min2" )
           ninfl   = artn% extract( "inewchance"  ) 
           connect = .FALSE.
           !IF( (dr1 < 0.1) .AND. (ABS(emin1-einit)<0.1) .OR. &
           !    (dr2 < 0.1) .AND. (ABS(emin2-einit)<0.1) )  connect = .TRUE.
           IF(  (ABS(emin1-einit)<0.01) .OR. (ABS(emin2-einit)<0.01) )  connect = .TRUE.
           WRITE(*,"(i4, 1x, i3, 4x, l3, 4x,  i6, 1x, i3, 3x, f9.4, 1x,  f9.4, 3x, f9.4, 1x,   f9.4, 3x, f9.4, 1x,    f9.4)")&
                     ievent, igroup, connect, nforc,  ninfl, esad-einit, drS,      emin1-einit, dr1,     emin2-einit, dr2
        ENDIF
        !
        !... Master receives from the other masters the indice of their event and conserve the biggest one
        ievent_previous=MAX(ievent, ngroup-1) ! for the first cycle 
        DO iproc= 0, nproc-1
           IF ( iproc /= me .AND. iproc/ngroup==0 ) THEN ! this node is an other group master
              messageOK=.TRUE.
              DO WHILE (messageOK) ! Do loop because this iproc has maybe send several updates of ievent
                 CALL MPI_Irecv( ievent, 1, MPI_INTEGER, iproc ,0 ,MPI_COMM_WORLD, requestA, ierr)
                 CALL MPI_Test(requestA, messageOK, MPI_STATUS_IGNORE, ierr) ! Check if the ievent has been received
                 IF (.NOT. messageOK) THEN                                   ! If not (no one has been emited), close request
                    CALL MPI_Cancel(requestA, ierr)  
                    CALL MPI_Request_free(requestA, ierr)
                 ELSE   
                    IF (ievent>ievent_previous) ievent_previous = ievent     ! If yes, conserve the biggest one
                 ENDIF   
              ENDDO
           ENDIF
        ENDDO
        ! 
        !... Update the indice search
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
end program multiple_group
