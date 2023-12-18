

SUBROUTINE refresh_artn()

  use artn_params
  use units
  implicit none

  logical :: input_from_lib
  integer :: vv(8)

  input_from_lib = associated( artn_data_ptr )

  write(*,*) "associated artn_data_ptr", input_from_lib

  !! this routine is only useful when there is data from interactive input mode.
  if( .not. input_from_lib ) return

  write(*,*) repeat('>',60)
  write(*,*) ">>>> entering refresh"

  !! ------ artn_data_ptr is associated:
  !! overwrite data in artn_params with data that is defined in artn_data_ptr (skip undefined)
  !!-----------------------------------

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



  !! string
  if( allocated( artn_data_ptr% prefix_sad       )) prefix_sad        = artn_data_ptr% prefix_sad
  if( allocated (artn_data_ptr% push_mode        )) push_mode         = artn_data_ptr% push_mode
  if( allocated (artn_data_ptr% engine_units     )) engine_units      = artn_data_ptr% engine_units
  if( allocated (artn_data_ptr% struc_format_out )) struc_format_out  = artn_data_ptr% struc_format_out
  if( allocated (artn_data_ptr% push_guess       )) push_guess        = artn_data_ptr% push_guess
  if( allocated (artn_data_ptr% eigenvec_guess   )) eigenvec_guess    = artn_data_ptr% eigenvec_guess
  if( allocated (artn_data_ptr% filout           )) filout            = artn_data_ptr% filout
  if( allocated (artn_data_ptr% filin            )) filin             = artn_data_ptr% filin
  if( allocated (artn_data_ptr% sadfname         )) sadfname          = artn_data_ptr% sadfname
  if( allocated (artn_data_ptr% initpfname       )) initpfname        = artn_data_ptr% initpfname
  if( allocated (artn_data_ptr% eigenfname       )) eigenfname        = artn_data_ptr% eigenfname
  if( allocated (artn_data_ptr% restartfname     )) restartfname      = artn_data_ptr% restartfname
  if( allocated (artn_data_ptr% converge_property)) converge_property = artn_data_ptr% converge_property
  if( allocated (artn_data_ptr% prefix_min       )) prefix_min        = artn_data_ptr% prefix_min




  !! int allocatable
  ! write(*,*) "nperp_limitation"
  ! write(*,*) nperp_limitation
  ! write(*,*) artn_data_ptr% nperp_limitation

  if( allocated( artn_data_ptr% nperp_limitation) ) then
     deallocate( nperp_limitation )
     allocate( nperp_limitation, source = artn_data_ptr% nperp_limitation )
  end if

  if( allocated( artn_data_ptr% push_ids ) ) then
     deallocate( push_ids )
     allocate( push_ids, source = artn_data_ptr% push_ids )
  end if




  !! real allocatable
  if( allocated( artn_data_ptr% push_add_const ) ) then
     deallocate( push_add_const )
     allocate( push_add_const, source = artn_data_ptr% push_add_const )
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



  write(*,*) ">>>> exiting refresh"
  write(*,*) repeat('>',60)

  !! output new header

  !! No output
  IF( verbose == 0 ) RETURN

  !! get current time and date
  CALL date_and_time( VALUES=vv )
  OPEN( UNIT = iunartout, FILE = filout, FORM = 'formatted', STATUS = 'OLD', POSITION='append' )
  ! write( iunartout,*) "new header:"
  IF( verbose == 1 ) THEN
     WRITE(iunartout,'(5x,"ARTn-plugin::output")')
     WRITE (iunartout,"(5x,a,1x,i0,a1,i0,a1,i0,1x,a,1x,i0.2,a1,i0.2,a1,i0.2)") "Launched on (dd.mm.yyyy):", &
          vv(3),".",vv(2),".",vv(1),"at:",vv(5),":",vv(6),":",vv(7)
  ELSE
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(5X, "|       _____                _____ _______       |")')
     WRITE (iunartout,'(5X, "|      /  _  |         /\   |  __ \__   __|      |")')
     WRITE (iunartout,'(5X, "|      | (_) |  ___   /  \  | |__) | | |         |")')
     WRITE (iunartout,'(5X, "|      |  ___/ |___| / /\ \ |  _  /  | |         |")')
     WRITE (iunartout,'(5X, "|      | |          / ____ \| | \ \  | |         |")')
     WRITE (iunartout,'(5X, "|      |_|         /_/    \_\_|  \_\ |_|         |")')
     WRITE (iunartout,'(5X, "|                                    ARTn plugin |")')   !> @author Antoine Jay
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,"(5x,a,1x,i0,a1,i0,a1,i0,1x,a,1x,i0.2,a1,i0.2,a1,i0.2)") "Launched on (dd.mm.yyyy):", &
          vv(3),".",vv(2),".",vv(1),"at:",vv(5),":",vv(6),":",vv(7)
     WRITE (iunartout,'(5X, " "                                                 )')
     WRITE (iunartout,'(5X, "               INPUT PARAMETERS                   ")')
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(5x, "engine_units:", *(1x,A))') TRIM(engine_units)
     WRITE (iunartout,'(5x, "Verbosity Level:", *(1x,i2))') verbose
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(5X, "Simulation Parameters:")')
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(13X,"* Iterators Parameter: ")')
     WRITE (iunartout,'(15X,"ninit           = ", I6)') ninit
     WRITE (iunartout,'(15X,"nperp           =",*(1x,I6))') nperp_limitation
     WRITE (iunartout,'(15X,"neigen          = ", I6)') neigen
     WRITE (iunartout,'(15X,"nsmooth         = ", I6)') nsmooth
     WRITE (iunartout,'(13X,"* Threshold Parameter: ")')
     WRITE (iunartout,'(15X,"converge_property = ", A)') converge_property
     WRITE (iunartout,'(15X,"forc_thr          = ", F7.3,2x,A)') unconvert_force( forc_thr ), unit_char('force')
     WRITE (iunartout,'(15X,"eigval_thr        = ", F7.3,2x,A)') unconvert_hessian( eigval_thr ), unit_char('hessian')
     WRITE (iunartout,'(15X,"frelax_ene_thr    = ", F7.3,2x,A)') unconvert_energy( frelax_ene_thr ), unit_char('energy')
     WRITE (iunartout,'(15X,"delr_thr          = ", F7.3,2x,A)') delr_thr, unit_char('length')
     WRITE (iunartout,'(13X,"* Step size Parameter: ")')
     IF( luser_choose_per_atom )THEN
       WRITE( iunartout,'(15X,"push_step_size_per_atom = ", F6.2,2x,A)') &
           unconvert_length( push_step_size_per_atom ), unit_char('length')
     ELSE
       WRITE( iunartout,'(15X,"push_step_size  = ", F6.2,2x,A)') &
           unconvert_length( push_step_size ), unit_char('length')
     ENDIF
     WRITE (iunartout,'(15X,"eigen_step_size = ", F6.2,2x,A)') unconvert_length( eigen_step_size ), unit_char('length')
     WRITE (iunartout,'(15X,"push_over       = ", F6.3,2x,A)') push_over, "fraction of eigen_step_size"
     WRITE (iunartout,'(15X,"push_mode       = ", A6)') push_mode
     IF( trim(push_mode) == "list") THEN
        WRITE(iunartout, '(15X, "push_ids      = ",*(I0,:,1x))') push_ids
     END IF
     IF( len_trim(push_guess) .gt. 0 ) THEN
        WRITE(iunartout,'(15X,"push_guess      = ", A)') trim(push_guess)
     END IF
     IF( LEN_TRIM(eigenvec_guess) .gt. 0 ) THEN
        WRITE(iunartout,'(15X,"eigenvec_guess  = ", A)') trim(eigenvec_guess)
     END IF
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(5X, "Lanczos algorithm:")' )
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(15X,"lanczos_min_size   = ", I6)') lanczos_min_size
     WRITE (iunartout,'(15X,"lanczos_max_size   = ", I6)') lanczos_max_size
     WRITE (iunartout,'(15X,"lanczos_disp           = ", G11.4,2x,A)') unconvert_length( lanczos_disp ), unit_char('length')
     WRITE (iunartout,'(15X,"lanczos_eval_conv_thr   = ", G11.4)') lanczos_eval_conv_thr
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(5X, "In/out file preferences:")' )
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(15X, "filin              = ", A)') trim(filin)
     WRITE (iunartout,'(15X, "filout             = ", A)') trim(filout)
     WRITE (iunartout,'(15X, "struc_format_out   = ", A)') trim(struc_format_out)
     WRITE (iunartout,'(15X, "prefix_sad         = ", A)') trim(prefix_sad)
     WRITE (iunartout,'(15X, "prefix_min         = ", A)') trim(prefix_min)
     WRITE (iunartout,'(5X, "--------------------------------------------------")')
     WRITE (iunartout,'(/,/)')
  END IF
  CLOSE(iunartout, status="keep")
END SUBROUTINE refresh_artn
