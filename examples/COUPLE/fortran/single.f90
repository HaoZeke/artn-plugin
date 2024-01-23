program single
  use liblammps
  use f_partn

  type( t_partn ) :: artn
  type( lammps ) :: lmp
  integer :: ierr, bb
  real, dimension(3,343) :: pp
  real, dimension(4, 343 ) :: addconst
  character(len=*), dimension(*), parameter :: args = &
       ! [ character(len=12) :: 'liblammps','-log', 'none','-screen','none' ]
       [ character(len=12) :: 'liblammps','-log', 'none' ]

  !! init lammps
  lmp = lammps(args)
  !! init partn
  artn = t_partn()

  !! set artn input params
  call artn% set( "engine_units", "lammps/metal")
  call artn% set( "verbose", 3 )
  call artn% set( "restart_freq", 0 )
  ! call artn% set( "converge_property", "norm" )
  call artn% set( "ninit", 2)
  ! call artn% set( "lpush_final", .true.)
  ! call artn% set( "nsmooth", 2)
  call artn% set( "nnewchance", 1)
  call artn% set( "forc_thr", 0.002 )
  call artn% set( "nperp_limitation", [3,6,8,-1] )
  ! call artn% set( "etot_diff_limit" , 42.0 )

  ! call artn% set( "lanczos_disp", 1e-3 )
  ! call artn% set( "lanczos_max_size", 16 )
  ! call artn% set( "lanczos_eval_conv_thr", 1e-2 )
  ! call artn% set( "eigen_step_size", 0.25 )
  ! call artn% set( "frelax_ene_thr", -0.0002 )
  call artn% set( "struc_format_out","none" )
  ! call artn% set( "zseed", 1234 )
  call artn% set( "nevalf_max", 999 )

  !! set constrained random initial push
  ! call artn% set( "push_mode", "list" )
  ! call artn% set( "push_ids", [2] )
  ! addconst(:,:) = 0.0
  ! addconst(:,1) = [0.0, 1.0, 0.0, 10.0]
  ! call artn% set( "push_add_const", addconst )

  !! set a custom initial push vector
  pp(:,:) = 0.0
  pp(:,1) = [-0.1, 0.22, 0.01 ]
  ! pp(:,2) = [0.2, 0.2, 0.2]
  call artn% set( "push_init", pp)


  ! call artn% dump_input()

  !! set lmp commands
  call lmp% command( "units metal" )
  call lmp% command( "dimension 3" )
  call lmp% command( "atom_modify sort 0 0.0" )
  call lmp% command( "read_data   pt111_heptamer.in" )
  call lmp% command( "region rb block 0.0 19.2088 0.0 19.2088 0.0 6.0" )
  call lmp% command( "group bottom region rb" )
  call lmp% command( "fix 1 bottom setforce 0.0 0.0 0.0" )
  call lmp% command( "pair_style morse/smooth/linear 9.5" )
  call lmp% command( "pair_coeff * * 0.7102 1.6047 2.897" )
  call lmp% command( "dump 10  all custom 1 config.dmp id type x y z fx fy fz" )
  call lmp% command( "plugin load ../../../lib/libartn-lmp.so" )
  call lmp% command( "fix 10 all artn dmax 8.0" )
  ! call lmp% command( "timestep 0.0002" )
  call lmp% command( "min_style fire" )


  !! launch lammps
  call lmp% command( "minimize 1e-3 1e-3 8000 8000" )



  !! extract data from artn
  nstep = artn% extract( "nevalf" )
  bb = artn% extract("inewchance")
  write(*,*) "nstep:",nstep
  write(*,*) "inewchance", bb

  block
    real :: ev
    integer, allocatable :: tt(:)
    real, allocatable :: cc(:,:)
    character(:), allocatable :: msg
    integer :: n, err, nat
    logical :: has_sad
    real, allocatable :: lat(:,:)

    ev = artn% extract( "delr_sad" )
    has_sad = artn% extract( "has_sad" )
    write(*,*) "dd",ev
    write(*,*) "has_sad", has_sad

    nat = artn% extract( "nat" )
    write(*,*) "nat:",nat

    lat = artn% extract( "lat" )

    if( .not. has_sad ) then
       err = artn% extract( "error_code" )
       write(*,*) "error code:",err
       msg = artn% extract( "error_message" )
       write(*,*) "msg:",msg
    else

       !! extract saddle conf
       tt = artn% extract( "typ_sad" )
       cc = artn% extract( "coords_sad" )

       !! write xyz format
       ! write(*,*) nat
       ! write(*,*) 'Lattice="',lat,'"'
       ! do n = 1, nat
       !    write(*,*) tt(n), cc(:,n)
       ! end do

       !! deallocate conf
       deallocate( tt, cc )
    end if



  end block

  call artn% close()
  call lmp% close()
end program single
