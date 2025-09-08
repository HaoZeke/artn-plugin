PROGRAM multiple_group
# ifdef MPIF08
   USE mpi_f08
# else
   use mpi
# endif
  USE liblammps
  USE artn_api

  IMPLICIT NONE
  ! MPI variables
  INTEGER                             :: igroup, ngroup, iproc, nproc, me, key 
  INTEGER                             :: req_count, req_count_str, req_count_bol, req_count_iev
# ifdef MPIF08
  TYPE( MPI_Request )                 :: requestA
  TYPE( MPI_Request ),ALLOCATABLE     :: req_send(:), req_send_str(:), req_send_bol(:)
  TYPE( MPI_Request ),ALLOCATABLE     :: req_send_iev(:)
  TYPE( MPI_Status ), ALLOCATABLE     :: statuses(:)
  TYPE( MPI_Status )                  :: status
  TYPE( MPI_Comm )                    :: lmp_comm
# else
   INTEGER                            :: requestA, lmp_comm
   INTEGER, ALLOCATABLE               :: req_send(:), req_send_str(:), req_send_bol(:)
   INTEGER, ALLOCATABLE               :: req_send_iev(:)
   INTEGER, ALLOCATABLE               :: statuses(:,:)
   INTEGER                            :: status(MPI_STATUS_SIZE)
# endif
  LOGICAL                             :: messageOK
  ! Extracted variables
  CHARACTER(:), ALLOCATABLE           :: errmsg
  LOGICAL                             :: err, errsad, errmin1, errmin2
  INTEGER                             :: ninfl, nforc
  REAL(8)                             :: dr1, dr2, drS
  REAL(8)                             :: einit, esad, emin1, emin2
  REAL(8),    ALLOCATABLE             :: einitall(:), esadall(:)
  ! ARTN and LAMMPS API variables
  TYPE( lammps )                      :: lmp
  CHARACTER(len=*), DIMENSION(*), PARAMETER :: args = &
        [ character(len=12)           :: 'liblammps','-screen','none' ]
        ![ character(len=12)           :: 'liblammps','-log', 'none','-screen','none' ]
  CHARACTER(:), ALLOCATABLE           :: fout
  ! real, dimension(4,343)            :: addconst
  ! Local variables
  INTEGER                             :: central_atom 
  INTEGER                             :: nevents, ievent, ievent_previous, ierr
  INTEGER                             :: istep, nsteps, chosen_event
  REAL(8)                             :: rand, buf(3)
  REAL(8),     ALLOCATABLE            :: enewall(:)
  REAL(8),     ALLOCATABLE            :: cum_weights(:)                                ! Poids cumulés des energies de Boltzmann
  LOGICAL                             :: connect
  LOGICAL,   ALLOCATABLE              :: connectall(:)
  LOGICAL,   ALLOCATABLE              :: is_calculated(:)                                   ! Indice set to true when event calculated
  CHARACTER(50), ALLOCATABLE          :: new_file(:)                                        ! 
  CHARACTER(:), ALLOCATABLE           :: min1_file, min2_file                               ! 
  CHARACTER(50)                       :: init_file
  CHARACTER(250)                      :: lmp_command
  REAL(8)                             :: T
  REAL(8)                             :: rnd 
  REAL(8), PARAMETER                  :: kB =8.617333262d-5                             !Boltzmann constant (eV/K)
  INTEGER                             :: select_algo                       ! Algorithm used to select one event in the list 
  REAL(8)                             :: caca 

  !
  ! These variables should be arguments if this program becomes a subroutine
  ngroup      = 4              ! number of seach group
  nevents     = 12             ! number of seached event per step
  nsteps      = 10             ! number of steps to make the structure evolves
  init_file   = "conf.xyz"     ! Structure file that is used for the first step
  T           = 300            ! Temperature (K) for Boltzmann weights
  select_algo = 3
  caca        = -1.0
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
  ierr = artn_create()
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  !
  !... Memory allocation to save the info of all the events into tables
  ALLOCATE( einitall(      nevents) )
  ALLOCATE( cum_weights(   nevents) )
  ALLOCATE( esadall(       nevents) )
  ALLOCATE( enewall(       nevents) )
  ALLOCATE( new_file(      nevents) )
  ALLOCATE( connectall(    nevents) )
  ALLOCATE( is_calculated( nevents) )
  ALLOCATE( req_send(      nevents) )
  ALLOCATE( req_send_str(  nevents) )
  ALLOCATE( req_send_bol(  nevents) )
  ALLOCATE( req_send_iev(  nevents*nproc) )
  ALLOCATE( statuses(      MPI_STATUS_SIZE,nevents))

  !
  !... This is the do loop over the steps to make the system evolves
  LIST_OF_STEPS_:  DO istep=0, nsteps

     !
     !... Some initialization of lists
     einitall      = 999.0
     esadall       = 999.0
     enewall       = 999.0
     connectall    = .FALSE.
     is_calculated = .FALSE.
     req_count     = 1 
     req_count_str = 1 
     req_count_bol = 1 
     req_count_iev = 1 
     !
     !... Define the atom on which the artn searches will focus: chose the algo you want, here random
     CALL RANDOM_NUMBER(rand)
     central_atom= FLOOR(rand*1000)                                  ! This example has 1000 atoms
     IF (me==0) WRITE(*,*) "____________________________________________________"
     IF (me==0) WRITE(*,*) "Start step", istep, " Exploration centered on atom ", central_atom

     !
     !... Set ARTN parameters that are common for all searches
     CALL artn_set( "engine_units"     , "lammps/metal"     , ierr)
     CALL artn_set( "verbose"          , 2                  , ierr)
     CALL artn_set( "restart_freq"     , 0                  , ierr)
     CALL artn_set( "ninit"            , 0                  , ierr)
     CALL artn_set( "lpush_final"      , .TRUE.             , ierr)
     CALL artn_set( "nnewchance"       , 100                , ierr)
     CALL artn_set( "forc_thr"         , 0.0001             , ierr)
     CALL artn_set( "nsmooth"          , 0                  , ierr)
     CALL artn_set( "nperp_limitation" , [4,10,15,20,25,-1] , ierr)
     CALL artn_set( "struc_format_out" , "xyz"              , ierr)  ! Put xyz if you want to see output structures
     CALL artn_set( "nevalf_max"       , 99999              , ierr)
     CALL artn_set( "push_mode"        , "rad"              , ierr)  ! Initial push
     CALL artn_set( "push_step_size"   , 0.1                , ierr)
     CALL artn_set( "push_ids"         , [central_atom]     , ierr)
     CALL artn_set( "push_dist_thr"    , 3.5                , ierr)
     CALL artn_set( "lanczos_disp"     , 0.005              , ierr)
     CALL artn_set( "lanczos_min_size" , 5                  , ierr)
     CALL artn_set( "lanczos_max_size" , 50                 , ierr)
     CALL artn_set( "eigval_thr"       , -0.01              , ierr)
     CALL artn_set( "eigen_step_size"  , 0.1                , ierr)
     CALL artn_set( "push_over"        , 6.0                , ierr)
     CALL artn_set( "alpha_mix_cr"     , 0.4                , ierr)
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
     CALL lmp% command( "read_data   conf.box" )                    ! This contains atoms but the correct pos are reloaded after
     CALL lmp% command( "pair_style sw" )
     CALL lmp% command( "pair_coeff * * Si.sw Si" )
     CALL lmp% command( "mass 1 29.0" )
     CALL lmp% command( "neighbor 2.0 bin" )
     CALL lmp% command( "neigh_modify delay 10 check yes" )
     CALL lmp% command( "comm_style tiled")
     CALL lmp% command( "balance 1.1 rcb")
     CALL lmp% command( "plugin load ../../lib/libartn-lmp.so" )
     CALL lmp% command( "fix 10 all artn alpha0 0.2 dmax 0.5" )
     CALL lmp% command( "timestep 0.002" )
     CALL lmp% command( "min_style fire" )
   
     !
     !... This is the do loop over the events
     IF (me==0) WRITE(*,"(a)") " iEv group Connect  Nforc Ninfl     DEsad     DRSad      DEMin1    DRMin1      DEMin2    DRMin1"
     ievent= igroup+1 ! Initialization
     LIST_OF_EVENTS_:  DO WHILE (ievent < nevents+1)

        !
        !... Set parameters that depends on the seach (output files, starting vector...) 
        ALLOCATE( CHARACTER(LEN=20) :: fout )
        CALL artn_set( "zseed"      , 10000*ievent ,ierr)
        WRITE( fout, "(a9,i0,a1,i0)") "artn.out_", istep, "_", ievent
        CALL artn_set( "filout",     trim(fout)    ,ierr)
        WRITE( fout, "(a6,i0,a1,i0)") "initp_"   , istep, "_", ievent
        CALL artn_set( "initpfname", trim(fout)    ,ierr)
        WRITE( fout, "(a4,i0,a1,i0,a1)") "sad_",   istep, "_", ievent,"_"
        CALL artn_set( "prefix_sad", trim(fout)    ,ierr)
        WRITE( fout, "(a4,i0,a1,i0,a1)") "min_",   istep, "_", ievent, "_"
        CALL artn_set( "prefix_min", trim(fout)    ,ierr)
        ! This is commented because it writes a lot. If added don't forget to undump before next event
        !WRITE( fout, "(a,i0)") "config.dmp_", istep, "_", ievent
        !CALL lmp% command( "dump 10 all custom 1 "//trim(fout)//" id type x y z fx fy fz" )
        DEALLOCATE (fout)
    
        !... launch LAMMPS
        lmp_command="read_dump "//trim(init_file)//" 0 x y z box no format xyz"
        CALL lmp% command( trim(lmp_command) )
        CALL lmp% command( "minimize 0.0 1e-8 30000 30000" )
        !CALL lmp% command( "undump 10 " )
        
        !
        !... Only the master of each group enters here, the other processes wait at the barrier (bcast) bellow
        GROUP_MASTER: IF (key==0) THEN
           ! 
           !... Extract some values to analyse the connectivity
           ierr = artn_extract( "has_error" , err     )
           ierr = artn_extract( "has_sad"   , errsad  ) 
           ierr = artn_extract( "has_min1"  , errmin1 )
           ierr = artn_extract( "has_min2"  , errmin2 )
           IF( err ) THEN
              ierr   = artn_extract( "error_message", errmsg)
              WRITE(*,"(2x,a6,1x,i0,1x,a18,1x,a)") "Search", ievent, "has error message:", errmsg
           ELSEIF( (.NOT. errsad) .OR. (.NOT. errmin1) .OR. (.NOT. errmin2) ) THEN
              WRITE(*,"(2x,a6,1x,i0,1x,a33)") "Search", ievent, "has error message: TOO MUCH STEPS" 
           ELSE
              ierr   = artn_extract( "nevalf_sad"  , nforc     )
              ierr   = artn_extract( "delr_min1"   , dr1       )
              ierr   = artn_extract( "delr_min2"   , dr2       )
              ierr   = artn_extract( "delr_sad"    , drS       )
              ierr   = artn_extract( "etot_init"   , einit     )
              ierr   = artn_extract( "etot_sad"    , esad      )
              ierr   = artn_extract( "etot_min1"   , emin1     )
              ierr   = artn_extract( "etot_min2"   , emin2     )
              ierr   = artn_extract( "fname_min1"  , min1_file )
              ierr   = artn_extract( "fname_min2"  , min2_file )
              CALL get_runparam( "inewchance", ninfl, ierr )
              connect = .FALSE.
              IF(  (ABS(emin1-einit)<0.01) .OR. (ABS(emin2-einit)<0.01) )  connect = .TRUE.  ! distance condition can be added
              WRITE(*,"(i4, 1x, i3, 4x, l3, 4x,  i6, 1x, i3, 3x, f9.4, 1x,  f9.4, 3x, f9.4, 1x,   f9.4, 3x, f9.4, 1x,    f9.4)")&
                        ievent, igroup, connect, nforc,  ninfl, esad-einit, drS,      emin1-einit, dr1,     emin2-einit, dr2
              !
              !... Find which of min1 and min2 is the new min and save the relevant information into tabulars
              connectall(ievent) = connect
              einitall(ievent)   = einit
              esadall(ievent)    = esad
              IF (dr1>dr2) THEN 
                 enewall(ievent)   = emin1
                 new_file(ievent)  = TRIM(min1_file) 
              ELSE
                 enewall(ievent)   = emin2
                 new_file(ievent)  = TRIM(min2_file)
              ENDIF    

              !
              !... Send this value to process 0 (received when all the events are finished) !Same kind of variable are grouped
              buf(1) = enewall(ievent) 
              buf(2) = esad 
              buf(3) = einit 
              IF ( me /= 0 ) THEN
                 CALL MPI_Isend(buf,              3,  MPI_DOUBLE_PRECISION,      0,&
                                ievent+ 0*nevents, MPI_COMM_WORLD, req_send(req_count ),         ierr)
                 CALL MPI_Isend(new_file(ievent), 50, MPI_CHARACTER,             0,&
                                ievent+ 1*nevents, MPI_COMM_WORLD, req_send_str(req_count_str ), ierr)
                 CALL MPI_Isend(connect,          1,  MPI_LOGICAL,               0,&
                                ievent+ 2*nevents, MPI_COMM_WORLD, req_send_bol(req_count_bol ), ierr)
                 req_count     = req_count+1
                 req_count     = req_count+1
                 req_count_str = req_count_str+1
                 req_count_bol = req_count_bol+1
              ENDIF    
              is_calculated(ievent)= .TRUE.
              !
           ENDIF
           !
           !... Master receives from the other masters the indice of their event and conserve the biggest one
           ievent_previous=MAX(ievent, ngroup)                                   ! for the first cycle 
           DO iproc= 0, nproc-1
              IF ( iproc /= me .AND. iproc/ngroup==0 ) THEN                      ! this node is an other group master
                 messageOK=.TRUE.
                 DO WHILE (messageOK) ! Do loop because this iproc has maybe send several updates of ievent
                    CALL MPI_Irecv( ievent, 1, MPI_INTEGER, iproc ,100*istep+5*nevents+iproc,&
                                    MPI_COMM_WORLD, requestA, ierr)
                    CALL MPI_Test(requestA, messageOK, MPI_STATUS_IGNORE, ierr)  ! Check if the ievent has been received
                    IF (.NOT. messageOK) THEN                                    ! If not (no one has been emited), close request
                       CALL MPI_Cancel(requestA, ierr)  
                       CALL MPI_Request_free(requestA, ierr)
                    ELSE  
                       IF (ievent>ievent_previous) ievent_previous = ievent      ! If yes, conserve the biggest one
                    ENDIF   
                 ENDDO
              ENDIF
           ENDDO
           ! 
           !... Update the indice search
           ievent=ievent_previous+1  
           !... Master send to others masters its inidice as it is the new highest
           DO iproc= 0 , nproc-1 
              IF ( iproc /= me .AND. iproc/ngroup==0 .AND. ievent.LE.nevents) THEN
                  CALL MPI_Isend( ievent, 1, MPI_INTEGER, iproc, 100*istep+5*nevents+me, &
                                  MPI_COMM_WORLD, req_send_iev(req_count_iev), ierr )
                  req_count_iev=req_count_iev+1
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
     !... Everybody wait here that the last groups finish their seach
     CALL FLUSH(6)
     CALL MPI_Barrier(MPI_COMM_WORLD, ierr)

     !
     !... Only process 0 receives the informations and chose the event
     IF (me==0) THEN 
         DO  ievent = 1, nevents
            IF (.NOT. is_calculated(ievent)) THEN
               CALL MPI_Recv(buf,                3, MPI_DOUBLE_PRECISION, MPI_ANY_SOURCE, &
                   ievent+0*nevents, MPI_COMM_WORLD, status, ierr)
               CALL MPI_Recv(new_file(ievent),  50, MPI_CHARACTER,        MPI_ANY_SOURCE, &
                   ievent+1*nevents, MPI_COMM_WORLD, status, ierr)
               CALL MPI_Recv(connectall(ievent), 1, MPI_LOGICAL,          MPI_ANY_SOURCE, &
                   ievent+2*nevents, MPI_COMM_WORLD, status, ierr)
               enewall(ievent)  = buf(1)
               esadall(ievent)  = buf(2) 
               einitall(ievent) = buf(3)
            ENDIF
         ENDDO
         !
         !... Here the user chose how he wants that the event is selected
         SELECT CASE(select_algo)
           CASE(1) !... To select the one that reduces the most the energy
              chosen_event= MINLOC(enewall,1)
           CASE(2) !... To select the one that has the lowest energy barrier
              chosen_event= MINLOC(esadall,1)
           CASE(3) !... To select randomly with probability equal to the Boltzmann weight   
             cum_weights(1) = EXP(-(esadall(1)-einitall(1)) / (kB*T))
             DO ievent = 2, nevents
                cum_weights(ievent) = cum_weights(ievent-1) +&
                       EXP(-(esadall(ievent)-einitall(ievent)) / (kB*T))*MERGE(1.0,0.0,connectall(ievent))
             ENDDO
             CALL RANDOM_NUMBER(rnd)
             rnd = rnd * cum_weights(nevents)
             DO ievent = 1, nevents
                IF (rnd <= cum_weights(ievent)) then
                   chosen_event = ievent
                   EXIT 
                ENDIF
             ENDDO
             IF ( cum_weights(nevents) .LE. 1E-30 ) THEN
                 PRINT*, "PROBLEM Temperature too small of barriers too high"
                 chosen_event= MINLOC(esadall,1)
             ENDIF    
         END SELECT
         init_file=new_file(chosen_event)       
         WRITE(*,*) " Step ", istep, " done. Chosen event=", chosen_event, &
                        " Eb = ", esadall(chosen_event)-einitall(chosen_event),&
                        " DE = ", enewall(chosen_event)-einitall(chosen_event),&
                        " New starting file = ", init_file
     ENDIF
     
     !
     !... All the processes wait here that process 0 gives them the new init_file 
     CALL MPI_Bcast(init_file, 50 , MPI_CHARACTER, 0, MPI_COMM_WORLD, ierr)
     
     !
     ! ... Finalize the messages sended by group masters to process 0
     IF ( me/ngroup==0 ) THEN
        CALL MPI_Waitall(req_count,     req_send,     MPI_STATUSES_IGNORE, ierr)
        CALL MPI_Waitall(req_count_str, req_send_str, MPI_STATUSES_IGNORE, ierr)
        CALL MPI_Waitall(req_count_bol, req_send_bol, MPI_STATUSES_IGNORE, ierr)
        CALL MPI_Waitall(req_count_iev, req_send_iev, MPI_STATUSES_IGNORE, ierr)
     ENDIF   
     CALL FLUSH(6)
     CALL MPI_Barrier(MPI_COMM_WORLD, ierr) ! wait that everybody arrives here before starting
     CALL SLEEP(1)
  ENDDO LIST_OF_STEPS_  
  !
  !... Finalize
  DEALLOCATE( einitall )
  DEALLOCATE( cum_weights )
  DEALLOCATE( esadall  )
  DEALLOCATE( enewall )
  DEALLOCATE( new_file )
  DEALLOCATE( connectall )
  DEALLOCATE( is_calculated )
  DEALLOCATE( req_send, req_send_str, req_send_bol )
  DEALLOCATE( req_send_iev, req_send_str, req_send_bol )
  DEALLOCATE( statuses )
  CALL lmp% CLOSE()
  CALL MPI_finalize( ierr )
  !
end program multiple_group
