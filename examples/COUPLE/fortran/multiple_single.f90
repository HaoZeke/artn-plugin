program multiple_single
  use mpi_f08
  use liblammps
  use f_partn

  implicit none
  integer :: ierr, np, me
  type( lammps ) :: lmp
  type( t_partn ) :: artn
  type( mpi_comm ) :: lmp_comm
  character(:), allocatable :: dumpfname, fout, errmsg
  real, dimension(4,343) :: addconst
  integer :: n
  logical :: er
  real :: dr1, dr2, esad, emin1, emin2
  character(len=*), dimension(*), parameter :: args = &
       [ character(len=12) :: 'liblammps','-log', 'none','-screen','none' ]
       ! [ character(len=12) :: 'liblammps','-log', 'none' ]

  ! me=0
  call mpi_init( ierr )

  call mpi_comm_size( MPI_COMM_WORLD, np, ierr )
  call mpi_comm_rank( MPI_COMM_WORLD, me, ierr )

  call mpi_comm_split( MPI_COMM_WORLD, me, 0, lmp_comm, ierr )

  lmp = lammps( comm = lmp_comm% mpi_val, args = args )
  ! lmp = lammps( )
  artn = t_partn()

  call artn% set( "engine_units", "lammps/metal")
  call artn% set( "verbose", 0 )
  call artn% set( "restart_freq", 0 )
  call artn% set( "ninit", 2)
  call artn% set( "lpush_final", .true. )
  call artn% set( "nnewchance", 1)
  call artn% set( "forc_thr", 0.002 )
  call artn% set( "nperp_limitation", [3,6,8,-1] )
  call artn% set( "struc_format_out","none" )
  call artn% set( "nevalf_max", 2999 )
  call artn% set( "push_mode", "list" )
  call artn% set( "push_ids", [1,2,3,4,5,6,7])

  !! set a different output file to each proc
  allocate( character(len=20) :: fout )
  write( fout, "(a,i0)") "artn.out",me
  call artn% set( "filout", trim(fout) )

  ! addconst(:,:) = 0.0
  ! addconst(:,1) = [0.0, 1.0, 0.0, 45.0 ]
  ! call artn% set( "push_add_const", addconst)


  call lmp% command( "units metal" )
  call lmp% command( "dimension 3" )
  call lmp% command( "atom_modify sort 0 0.0" )
  call lmp% command( "read_data   pt111_heptamer.in" )
  call lmp% command( "region rb block 0.0 19.2088 0.0 19.2088 0.0 6.0" )
  call lmp% command( "group bottom region rb" )
  call lmp% command( "fix 1 bottom setforce 0.0 0.0 0.0" )
  call lmp% command( "pair_style morse/smooth/linear 9.5" )
  call lmp% command( "pair_coeff * * 0.7102 1.6047 2.897" )

  !! different dump file for each proc
  allocate( character(len=20) :: dumpfname )
  write( dumpfname, "(a,i0)") "config.dmp", me
  call lmp% command( "dump 10  all custom 1 "//trim(dumpfname)//" id type x y z fx fy fz" )

  call lmp% command( "plugin load ../../../lib/libartn-lmp.so" )
  call lmp% command( "fix 10 all artn dmax 8.0" )
  ! call lmp% command( "timestep 0.0002" )
  call lmp% command( "min_style fire" )

  !! launch lammps
  call lmp% command( "minimize 1e-3 1e-3 8000 8000" )

  n = artn% extract( "nevalf" )
  er = artn% extract( "has_error")
  ! write(*,*) me, "did",n, er
  if( er ) then
     errmsg = artn% extract( "error_message" )
     write(*,"(2x,a,1x,i0,1x,a,1x,a)") "node",me,"has error message:",errmsg
  else
     dr1 = artn% extract( "delr_min1" )
     dr2 = artn% extract( "delr_min2" )
     ! write(*,*) me, dr1, dr2
     esad = artn% extract( "energy_sad" )
     emin1 = artn% extract( "energy_min1" )
     emin2 = artn% extract( "energy_min2" )
     if( dr1 < 0.1 ) then
        write(*,"(2x,a,1x,i0,1x,a,1x,f12.8)") "node", me, "found connected saddle, barrier:", esad-emin1
     elseif( dr2 < 0.1 ) then
        write(*,"(2x,a,1x,i0,1x,a,1x,f12.8)") "node", me, "found connected saddle, barrier:", esad-emin2
     else
        write(*,"(2x,a,1x,i0,1x,a,1x,2(f9.4))") "node", me, "saddle not connected", dr1, dr2
     end if

  end if

  call lmp% close()
  call artn% close()

  call mpi_finalize( ierr )
end program multiple_single
