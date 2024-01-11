

SUBROUTINE refresh_artn( lerror )

  !! lerror = .false. at normal execution
  use artn_params
  use units
  implicit none


  logical, intent(out) :: lerror
  logical :: input_from_lib
  ! integer :: vv(8)
  integer :: n
  logical :: refresh_check_size

  lerror = .false.
  input_from_lib = associated( artn_data_ptr )

  write(*,*) "associated artn_data_ptr", input_from_lib

  !! this routine is only useful when there is data from interactive input mode.
  if( .not. input_from_lib ) return

  write(*,*) repeat('>',60)
  write(*,*) ">>>> entering refresh"

  !! ------ artn_data_ptr is associated:
  !! overwrite data in artn_params with data that is defined in artn_data_ptr (skip undefined)
  !!-----------------------------------

  !! string
  if( allocated (artn_data_ptr% engine_units     ))then
     engine_units = artn_data_ptr% engine_units
  end if
  if( trim(engine_units) .ne. "qe" ) struc_format_out = "xyz"
  call make_units( engine_units )

  if( allocated( artn_data_ptr% prefix_sad       ))then
     !! check if string is too long
     lerror = refresh_check_size( "prefix_sad" )
     if(lerror)return
     prefix_sad = artn_data_ptr% prefix_sad
  end if
  if( allocated (artn_data_ptr% push_mode        ))then
     if( len(artn_data_ptr% push_mode) .gt. len(push_mode)) then
        ! lerror = warning_refresh( "push_mode", exp_dim1=len(push_mode), dim1=len(artn_data_ptr% push_mode) )
        return
     end if
     push_mode = artn_data_ptr% push_mode
  end if
  if( allocated (artn_data_ptr% struc_format_out ))then
     struc_format_out = artn_data_ptr% struc_format_out
  end if
  if( allocated (artn_data_ptr% push_guess       ))then
     push_guess = artn_data_ptr% push_guess
  end if
  if( allocated (artn_data_ptr% eigenvec_guess   ))then
     eigenvec_guess = artn_data_ptr% eigenvec_guess
  end if
  if( allocated (artn_data_ptr% filout           ))then
     filout = artn_data_ptr% filout
  end if
  if( allocated (artn_data_ptr% filin            ))then
     filin = artn_data_ptr% filin
  end if
  if( allocated (artn_data_ptr% sadfname         ))then
     sadfname = artn_data_ptr% sadfname
  end if
  if( allocated (artn_data_ptr% initpfname       ))then
     initpfname = artn_data_ptr% initpfname
  end if
  if( allocated (artn_data_ptr% eigenfname       ))then
     eigenfname = artn_data_ptr% eigenfname
  end if
  if( allocated (artn_data_ptr% restartfname     ))then
     restartfname = artn_data_ptr% restartfname
  end if
  if( allocated (artn_data_ptr% converge_property))then
     converge_property = artn_data_ptr% converge_property
  end if
  if( allocated (artn_data_ptr% prefix_min       ))then
     prefix_min = artn_data_ptr% prefix_min
  end if


  !! integer
  if( artn_data_ptr% ninit            .ne. -99 ) ninit = artn_data_ptr% ninit
  if( artn_data_ptr% nevalf_max       .ne. -99 ) nevalf_max = artn_data_ptr% nevalf_max
  if( artn_data_ptr% lanczos_max_size .ne. -99 ) lanczos_max_size = artn_data_ptr% lanczos_max_size
  !! the actual variable used in lanczos is nlanc
  nlanc = lanczos_max_size
  if( artn_data_ptr% lanczos_min_size .ne. -99 ) lanczos_min_size = artn_data_ptr% lanczos_min_size
  if( artn_data_ptr% neigen           .ne. -99 ) neigen = artn_data_ptr% neigen
  if( artn_data_ptr% nperp            .ne. -99 ) nperp = artn_data_ptr% nperp
  if( artn_data_ptr% nsmooth          .ne. -99 ) nsmooth = artn_data_ptr% nsmooth
  if( artn_data_ptr% verbose          .ne. -99 ) verbose = artn_data_ptr% verbose
  if( artn_data_ptr% zseed            .ne. -99 ) zseed = artn_data_ptr% zseed
  if( artn_data_ptr% nnewchance       .ne. -99 ) nnewchance = artn_data_ptr% nnewchance
  if( artn_data_ptr% nrelax_print     .ne. -99 ) nrelax_print = artn_data_ptr% nrelax_print
  if( artn_data_ptr% restart_freq     .ne. -99 ) restart_freq = artn_data_ptr% restart_freq


  !! real
  ! write(*,*) "artn_data_ptr% forc_thr",artn_data_ptr% forc_thr
  ! write(*,*) "converted:",convert_force( artn_data_ptr% forc_thr )
  !! NOTE: don't forget to convert the needed variables into units
  if( .not.(artn_data_ptr% forc_thr                > 1e19 ) ) &
       forc_thr = convert_force( artn_data_ptr% forc_thr )

  if( .not.(artn_data_ptr% push_dist_thr           > 1e19 ) ) &
       push_dist_thr = artn_data_ptr% push_dist_thr

  if( .not.(artn_data_ptr% eigval_thr              > 1e19 ) ) &
       eigval_thr = convert_hessian( artn_data_ptr% eigval_thr )

  if( .not.(artn_data_ptr% frelax_ene_thr          > 1e19 ) ) &
       frelax_ene_thr = convert_energy( artn_data_ptr% frelax_ene_thr )

  if( .not.(artn_data_ptr% delr_thr                > 1e19 ) ) &
       delr_thr = artn_data_ptr% delr_thr

  if( .not.(artn_data_ptr% lanczos_eval_conv_thr   > 1e19 ) ) &
       lanczos_eval_conv_thr = artn_data_ptr% lanczos_eval_conv_thr

  if( .not.(artn_data_ptr% etot_diff_limit         > 1e19 ) ) &
       etot_diff_limit = convert_energy( artn_data_ptr% etot_diff_limit )

  if( .not.(artn_data_ptr% push_step_size          > 1e19 ) ) &
       push_step_size = convert_length( artn_data_ptr% push_step_size )

  !! this is cnfusing
  if( .not.(artn_data_ptr% push_step_size_per_atom > 1e19 ) ) then
     push_step_size_per_atom = convert_length( artn_data_ptr% push_step_size_per_atom )
     luser_choose_per_atom = .true.
  end if

  !! is correct to convert lanczos length? for example other distance things are not
  if( .not.(artn_data_ptr% lanczos_disp            > 1e19 ) ) &
       lanczos_disp = convert_length( artn_data_ptr% lanczos_disp )

  if( .not.(artn_data_ptr% eigen_step_size         > 1e19 ) ) &
       eigen_step_size = convert_length( artn_data_ptr% eigen_step_size )

  !! what with this?
  if( .not.(artn_data_ptr% push_over               > 1e19 ) ) &
       push_over = 1.0

  !! testing
  if( .not.(artn_data_ptr% current_step_size       > 1e19 ) ) &
       current_step_size = artn_data_ptr% current_step_size



  !! logical: stored as integer with possible values -1,0,1:
  !!   value = -1 when undefined; value = 0 when .false.; value = 1 when .true.
  if( artn_data_ptr% lanczos_at_min .ge. 0 ) then
     !! value has been defined interactively
     if( artn_data_ptr% lanczos_at_min == 0) lanczos_at_min = .false.
     if( artn_data_ptr% lanczos_at_min == 1) lanczos_at_min = .true.
  end if

  if( artn_data_ptr% lrestart              .ge. 0 ) then
     if( artn_data_ptr% lrestart              == 0 ) lrestart             = .false.
     if( artn_data_ptr% lrestart              == 1 ) lrestart             = .true.
  end if

  if( artn_data_ptr% lrelax                .ge. 0 ) then
     if( artn_data_ptr% lrelax                == 0 ) lrelax               = .false.
     if( artn_data_ptr% lrelax                == 1 ) lrelax               = .true.
  end if

  if( artn_data_ptr% lpush_final           .ge. 0 ) then
     if( artn_data_ptr% lpush_final           == 0 ) lpush_final          = .false.
     if( artn_data_ptr% lpush_final           == 1 ) lpush_final          = .true.
  end if

  if( artn_data_ptr% lmove_nextmin         .ge. 0 ) then
     if( artn_data_ptr% lmove_nextmin         == 0 ) lmove_nextmin        = .false.
     if( artn_data_ptr% lmove_nextmin         == 1 ) lmove_nextmin        = .true.
  end if

  if( artn_data_ptr% lnperp_limitation     .ge. 0 ) then
     if( artn_data_ptr% lnperp_limitation     == 1 ) lnperp_limitation    = .true.
     if( artn_data_ptr% lnperp_limitation     == 0 ) lnperp_limitation    = .false.
  end if

  if( artn_data_ptr% lanczos_always_random .ge. 0 ) then
     if( artn_data_ptr% lanczos_always_random == 1 ) lanczos_always_random = .true.
     if( artn_data_ptr% lanczos_always_random == 0 ) lanczos_always_random = .false.
  end if







  !! int allocatable
  if( allocated( artn_data_ptr% nperp_limitation) ) then
     !! can change size, no constraints
     deallocate( nperp_limitation )
     allocate( nperp_limitation, source = artn_data_ptr% nperp_limitation )
  end if

  if( allocated( artn_data_ptr% push_ids ) ) then
     !! needs to be size <= natoms
     lerror = refresh_check_size( "push_ids" )
     if( lerror ) return
     !! zero all push_ids, keep the size allocated
     push_ids(:) = 0
     !! copy artn_data_ptr% push_ids values into push_ids
     n = size( artn_data_ptr% push_ids )
     push_ids( 1:n ) = artn_data_ptr% push_ids
  end if



  !! real allocatable
  if( allocated( artn_data_ptr% push_add_const ) ) then
     !! needs to be size1==4 and size2==nat
     lerror = refresh_check_size( "push_add_const" )
     if( lerror ) return
     !! overwrite
     push_add_const(:,:) = artn_data_ptr% push_add_const(:,:)
     ! deallocate( push_add_const )
     ! allocate( push_add_const, source = artn_data_ptr% push_add_const )
  end if

  if( allocated( artn_data_ptr% push_init)) then
     !! needs to be size1==3, size2==nat
     lerror = refresh_check_size( "push_init" )
     if( lerror ) return
     !! overwrite push, and set mode=input
     push(:,:) = artn_data_ptr% push_init(:,:)
     push_mode = "input"
  end if


  !!---------------------------------------
  !! now do the opposite: overwrite artn_data_ptr with values from artn_params.
  !! This is to be able to extract defaults if not set interactively.
  !!---------------------------------------
  !! integer
  ! artn_data_ptr% ninit = ninit
  ! artn_data_ptr% nevalf_max = nevalf_max
  ! artn_data_ptr% lanczos_max_size = lanczos_max_size
  ! artn_data_ptr% lanczos_min_size = lanczos_min_size
  ! artn_data_ptr% neigen = neigen
  ! artn_data_ptr% nperp = nperp
  ! artn_data_ptr% nsmooth = nsmooth
  ! artn_data_ptr% verbose = verbose
  ! artn_data_ptr% zseed = zseed
  ! artn_data_ptr% nnewchance = nnewchance
  ! artn_data_ptr% nrelax_print = nrelax_print
  ! artn_data_ptr% restart_freq = restart_freq

  ! !! real
  ! artn_data_ptr% push_dist_thr = push_dist_thr
  ! artn_data_ptr% forc_thr = forc_thr
  ! artn_data_ptr% eigval_thr = eigval_thr
  ! artn_data_ptr% frelax_ene_thr = frelax_ene_thr
  ! artn_data_ptr% delr_thr = delr_thr
  ! artn_data_ptr% lanczos_eval_conv_thr = lanczos_eval_conv_thr
  ! artn_data_ptr% etot_diff_limit = etot_diff_limit
  ! artn_data_ptr% push_step_size = push_step_size
  ! artn_data_ptr% push_step_size_per_atom = push_step_size_per_atom
  ! artn_data_ptr% lanczos_disp = lanczos_disp
  ! artn_data_ptr% eigen_step_size = eigen_step_size
  ! artn_data_ptr% current_step_size = current_step_size
  ! artn_data_ptr% push_over = push_over

  ! !! logical
  ! artn_data_ptr% lrestart = 0
  ! artn_data_ptr% lrelax = 0
  ! artn_data_ptr% lpush_final = 0
  ! artn_data_ptr% lmove_nextmin = 0
  ! artn_data_ptr% lnperp_limitation = 0
  ! artn_data_ptr% lanczos_at_min = 0
  ! artn_data_ptr% lanczos_always_random = 0
  ! if( lrestart ) artn_data_ptr% lrestart = 1
  ! if( lrelax ) artn_data_ptr% lrelax = 1
  ! if( lpush_final ) artn_data_ptr% lpush_final = 1
  ! if( lmove_nextmin ) artn_data_ptr% lmove_nextmin = 1
  ! if( lnperp_limitation ) artn_data_ptr% lnperp_limitation = 1
  ! if( lanczos_at_min ) artn_data_ptr% lanczos_at_min = 1
  ! if( lanczos_always_random ) artn_data_ptr% lanczos_always_random = 1

  ! !! integer allocatable

  ! !! real allocatable

  ! !! string



  !! reallocate arrays from artn_setup if needed
  !! They can be of wrong size if the variable giving their size changes between
  !! successive calls. This happens since setup_artn() is only called in first isearch
  !! lanczos matrices: Vmat, H
  if( lanczos_max_size .ne. size(H,1) ) then
     ! write(*,*) "changed lanczos size, old",size(H,1),'new',lanczos_max_size
     if( allocated(H)) deallocate(H)
     allocate( H(1:lanczos_max_size, 1:lanczos_max_size), source=0.D0 )
     if( allocated(Vmat))deallocate(Vmat)
     allocate( Vmat(1:3, 1:natoms, 1:lanczos_max_size), source = 0.D0 )
  end if



  !! need to do some checks on params



  !! should artn_data_ptr contents be destroyed at this point?
  !!


  write(*,*) ">>>> exiting refresh"
  write(*,*) repeat('>',60)

  !! output new header

  !! No output
  IF( verbose == 0 ) RETURN

  !! write new header
  call write_initial_report( iunartout, filout )

END SUBROUTINE refresh_artn


function refresh_check_size( name )result( lerror )
  use artn_params
  implicit none
  character(*), intent(in) :: name
  logical :: lerror

  integer :: dim1, dim2, edim1, edim2

  dim1=-1; dim2=-1; edim1=-1; edim2=-1
  lerror = .false.

  !! get expected dim, and actual dim in data_ptr
  select case( name )
  case( "prefix_sad" )
     edim1 = len(prefix_sad); dim1=len(artn_data_ptr% prefix_sad)
  case( "push_add_const" )
     edim1 = size( push_add_const, 1 ); edim2 = size( push_add_const, 2)
     dim1 = size( artn_data_ptr% push_add_const, 1); dim2=size( artn_data_ptr% push_add_const, 2)
  case( "push_ids" )
     edim1=size(push_ids); dim1=size(artn_data_ptr% push_ids )
     !! if actual size of artn_data_ptr% push_ids is smaller than push_ids, this is ok
     !! since it allows to copy the smaller array into larger.
     !! instead return error only if it is larger than push_size
     if( dim1 .lt. edim1 ) dim1 = edim1
  case( "push_init" )
     !! expected size is same as push (push is allocated in setup_artn, so should be know)
     edim1=size( push, 1); edim2=size(push,2)
     dim1=size(artn_data_ptr% push_init, 1); dim2=size(artn_data_ptr% push_init, 2)
  end select

  !! compare sizes
  if( edim1 .ne. dim1 .or. edim2 .ne. dim2 ) then
     lerror = .true.
     write(*,'(5x,a)') "WARNING in refresh_artn:"
     write(*,'(5x,a,1x,a,1x,a)') "the variable:",name,"has wrong size!"
     write(*,'(5x, a,1x,i0)',advance="no") "expected:",edim1
     if( edim2 .ge. 0) write(*,'(1x,i0)', advance="no") edim2
     write(*,*)
     write(*,'(5x,a,1x,i0)',advance="no") "got:", dim1
     if(dim2 .ge. 0)write(*,'(1x,i0)',advance="no") dim2
     write(*,*)
  end if

end function refresh_check_size

