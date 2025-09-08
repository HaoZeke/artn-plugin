program single
  use liblammps
  use artn_api
  implicit none

  ! type( t_partn ) :: artn
  type( lammps ) :: lmp
  integer :: ierr
  !real, dimension(3,343) :: pp
  real, dimension(4, 343 ) :: addconst
  character(len=*), dimension(*), parameter :: args = &
       ! [ character(len=12) :: 'liblammps','-log', 'none','-screen','none' ]
       [ character(len=12) :: 'liblammps','-log', 'none' ]

  !! init lammps
  lmp = lammps(args)
  !! init partn
  ! artn = t_partn()


  ierr = artn_create()
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  !! set artn input params
  call artn_set( "engine_units", "lammps/metal", ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "verbose", 3, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "restart_freq", 0, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "ninit", 2, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "nnewchance", 0, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "forc_thr", 0.002, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "nperp_limitation", [3,6,8,-1], ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "struc_format_out","none", ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  !! set constrained random initial push
  call artn_set( "push_mode", "list", ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "push_ids", [2], ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  call artn_set( "push_step_size", 0.16, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  addconst(:,:) = 0.0
  addconst(:,2) = [0.0, 1.0, 0.0, 10.0]
  call artn_set( "push_add_const", addconst, ierr )
  if( ierr /= 0 ) call artn_merr(__FILE__,__LINE__)

  !! set a custom initial push vector
  ! pp(:,:) = 0.0
  ! pp(:,1) = [-0.1, 0.22, 0.01 ]
  ! ! pp(:,2) = [0.2, 0.2, 0.2]
  ! call artn_set( "push_init", pp)

  ! call dump_input( "afile.in")


  call lmp% command( "units metal" )
  call lmp% command( "dimension 3" )
  call lmp% command( "atom_modify sort 0 0.0" )
  ! call lmp% command( "atom_modify map yes")
  call lmp% command( "read_data   pt111_heptamer.in" )
  call lmp% command( "region rb block 0.0 19.2088 0.0 19.2088 0.0 6.0" )
  call lmp% command( "group bottom region rb" )
  call lmp% command( "fix 1 bottom setforce 0.0 0.0 0.0" )
  call lmp% command( "pair_style morse/smooth/linear 9.5" )
  call lmp% command( "pair_coeff * * 0.7102 1.6047 2.897" )
  call lmp% command( "dump 10  all custom 1 config.dmp id type x y z fx fy fz" )
  call lmp% command( "plugin load ../../../lib/libartn-lmp.so" )
  call lmp% command( "fix 10 all artn dmax 8.0" )
  call lmp% command( "min_style fire")

  call lmp% command("minimize 1e-3 1e-3 800 800")
  ! call artn% close()
  call lmp% close()


  block
    integer, allocatable :: typ(:)
    real, allocatable :: coords(:,:)
    integer :: i, nat

    if( artn_extract( "typ_sad", typ ) /= 0 ) &
        call artn_merr(__FILE__,__LINE__)
    if( artn_extract( "tau_sad", coords ) /= 0 ) &
        call artn_merr(__FILE__,__LINE__)
    if( artn_extract( "natoms", nat ) /=0 )    &
        call artn_merr(__FILE__,__LINE__)

    write(*,*) nat
    write(*,*)
    do i = 1, nat
       write(*,*) typ(i), coords(:,i)
    end do

  end block

end program single
