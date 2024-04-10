submodule( m_artn_report ) write_report_routines

  use precision, only: DP
  use m_error
  implicit none

contains


  !> @note
  !>   List of subroutine and where are they called
  !>   - write_initial_report():   artn()
  !>   - write_header_report():    artn()
  !>   - write_report():           artn()
  !>   - write_artn_step_report(): check_force_convergence()
  !>   - write_inter_report():     artn()
  !>   - write_end_report():       artn()
  !>   - write_fail_report():      artn(),
  !>                               clean_artn(),
  !>   - write_comment():          artn(),
  !>                               check_force()




  !> @brief
  !!   Open and write the information of ARTn research in the ouput
  !!   defined by the channel IUARTNOUT and the file name FILOUT.
  !!   New file for output is created at open().
  !
  !! @param[in]  filout       name of the file
  !
  MODULE SUBROUTINE write_initial_report( fout )
    !
    use artn_params, ONLY: engine_units, ninit, nperp, neigen, nsmooth,  &
         forc_thr, eigval_thr, delr_thr, &
         push_step_size, eigen_step_size, lanczos_max_size, lanczos_disp, &
         push_step_size_per_atom, luser_choose_per_atom, &
         push_mode, verbose, push_over, zseed, &
         converge_property, lanczos_eval_conv_thr, nperp_limitation, verbose, &
         lanczos_min_size, struc_format_out, prefix_min, prefix_sad, filin, filout, &
         push_guess, eigenvec_guess, push_ids, isearch, nevalf_max, alpha_mix_cr, nnewchance
    use units, only : unconvert_force, &
         unconvert_energy, unconvert_hessian, unconvert_length, unit_char
    implicit none

    CHARACTER (LEN=255), INTENT(IN) :: fout
    ! -- Local Variables
    integer :: ios, u0
    integer :: vv(8)
    character(len=128) :: msg
    !
    ! Writes the header to the artn output file
    !

    !! No output
    IF( verbose == 0 ) RETURN

    ! get current date and time for output
    CALL date_and_time( VALUES=vv )

    ! open file for writing
    IF( isearch == 0 ) THEN
       ! first call, overwrite old output if it exists
       open( NEWUNIT=u0, FILE=fout, FORM='formatted', STATUS='UNKNOWN', POSITION='rewind', IOSTAT=ios, IOMSG=msg )
    ELSE
       ! not first call, append old output
       open( NEWUNIT=u0, FILE=fout, FORM='formatted', STATUS='UNKNOWN', POSITION='append', IOSTAT=ios, IOMSG=msg )
    END IF
    if( ios /= 0 ) then
       write(*,*) "ERROR with file:", trim(fout)
       write(*,*) trim(msg)
       ! call merr( __FILE__, __LINE__ )
    end if


    IF( verbose == 1 )THEN

       WRITE(u0,'(5x,"ARTn-plugin::output")')
       WRITE (u0,"(5x,a,1x,i0,a1,i0,a1,i0,1x,a,1x,i0.2,a1,i0.2,a1,i0.2)") "Launched on (dd.mm.yyyy):", &
            vv(3),".",vv(2),".",vv(1),"at:",vv(5),":",vv(6),":",vv(7)
    ELSE

       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(5X, "|       _____                _____ _______       |")')
       WRITE (u0,'(5X, "|      /  _  |         /\   |  __ \__   __|      |")')
       WRITE (u0,'(5X, "|      | (_) |  ___   /  \  | |__) | | |         |")')
       WRITE (u0,'(5X, "|      |  ___/ |___| / /\ \ |  _  /  | |         |")')
       WRITE (u0,'(5X, "|      | |          / ____ \| | \ \  | |         |")')
       WRITE (u0,'(5X, "|      |_|         /_/    \_\_|  \_\ |_|         |")')
       WRITE (u0,'(5X, "|                                    ARTn plugin |")')   !> @author Antoine Jay
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,"(5x,a,1x,i0,a1,i0,a1,i0,1x,a,1x,i0.2,a1,i0.2,a1,i0.2)") "Launched on (dd.mm.yyyy):", &
            vv(3),".",vv(2),".",vv(1),"at:",vv(5),":",vv(6),":",vv(7)
       WRITE (u0,'(5X, " "                                                 )')
       WRITE (u0,'(5X, "               INPUT PARAMETERS                   ")')
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(5x, "engine_units:", *(1x,A))') TRIM(engine_units)
       WRITE (u0,'(5x, "Verbosity Level:", *(1x,i2))') verbose
       WRITE (u0,'(5x, "Zseed          : ", I0)') zseed
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(5X, "Simulation Parameters:")')
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(13X,"* Iterators Parameter: ")')
       WRITE (u0,'(15X,"ninit            = ", I0)') ninit
       WRITE (u0,'(15X,"nevalf_max       = ", I0)') nevalf_max
       WRITE (u0,'(15X,"nperp_limitation =",*(1x,I0))') nperp_limitation
       WRITE (u0,'(15X,"neigen           = ", I0)') neigen
       WRITE (u0,'(15X,"nsmooth          = ", I0)') nsmooth
       WRITE (u0,'(15X,"nnewchance       = ", I0)') nnewchance
       WRITE (u0,'(13X,"* Threshold Parameter: ")')
       WRITE (u0,'(15X,"converge_property = ", A)') converge_property
       WRITE (u0,'(15X,"forc_thr          = ", F7.3,2x,A)') unconvert_force( forc_thr ), unit_char('force')
       WRITE (u0,'(15X,"eigval_thr        = ", F7.3,2x,A)') unconvert_hessian( eigval_thr ), unit_char('hessian')
       WRITE (u0,'(15X,"eigval_thr_nounit = ", F7.3)') eigval_thr
       WRITE (u0,'(15X,"delr_thr          = ", F7.3,2x,A)') delr_thr, unit_char('length')  !! this parameter is not converted becasue tau is not converted
       WRITE (u0,'(13X,"* Step size Parameter: ")')
       IF( luser_choose_per_atom )THEN
          WRITE( u0,'(15X,"push_step_size_per_atom = ", F6.2,2x,A)') &
               unconvert_length( push_step_size_per_atom ), unit_char('length')
       ELSE
          WRITE( u0,'(15X,"push_step_size  = ", F6.2,2x,A)') &
               unconvert_length( push_step_size ), unit_char('length')
       ENDIF
       WRITE (u0,'(15X,"eigen_step_size = ", F6.2,2x,A)') unconvert_length( eigen_step_size ), unit_char('length')
       WRITE (u0,'(15X,"push_over       = ", F6.2,2x,A)') push_over, "fraction of eigen_step_size"
       WRITE (u0,'(15X,"push_mode       = ", A6)') push_mode
       WRITE (u0,'(15X,"alpha_mix_cr    = ", F6.2)') alpha_mix_cr
       IF( trim(push_mode) == "list") THEN
          WRITE(u0, '(15X, "push_ids      = ",*(I0,:,1x))') pack( push_ids, push_ids .ne. 0 )
       END IF
       IF( trim(push_mode) == "file" ) THEN
          WRITE(u0,'(15X,"push_guess      = ", A)') trim(push_guess)
       END IF
       IF( LEN_TRIM(eigenvec_guess) .gt. 0 ) THEN
          WRITE(u0,'(15X,"eigenvec_guess  = ", A)') trim(eigenvec_guess)
       END IF
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(5X, "Lanczos algorithm:")' )
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(15X,"lanczos_min_size      = ", I6)') lanczos_min_size
       WRITE (u0,'(15X,"lanczos_max_size      = ", I6)') lanczos_max_size
       WRITE (u0,'(15X,"lanczos_disp          = ", F7.3,2x,A)') unconvert_length( lanczos_disp ), unit_char('length')
       WRITE (u0,'(15X,"lanczos_eval_conv_thr = ", F7.3)') lanczos_eval_conv_thr
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(5X, "In/out file preferences:")' )
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(15X, "filin              = ", A)') trim(filin)
       WRITE (u0,'(15X, "filout             = ", A)') trim(filout)
       WRITE (u0,'(15X, "struc_format_out   = ", A)') trim(struc_format_out)
       WRITE (u0,'(15X, "prefix_sad         = ", A)') trim(prefix_sad)
       WRITE (u0,'(15X, "prefix_min         = ", A)') trim(prefix_min)
       WRITE (u0,'(5X, "--------------------------------------------------")')

    ENDIF

    !! output the message about overwriting variables
    if( allocated( overwrite_msg )) WRITE(u0, "(a)") trim(overwrite_msg)
    WRITE (u0,'(/,/)')

    CLOSE ( UNIT = u0, STATUS = 'KEEP')

  END SUBROUTINE write_initial_report




  !> @brief
  !!   write the header before the run. It contains the system units
  !
  !
  MODULE SUBROUTINE write_header_report( )
    !
    use artn_params, only : verbose, isearch, ifound, filout
    use units, only :  strg_units
    implicit none

    integer               :: ios, u0
    character(len=128) :: msg


    IF( verbose > 1 )THEN
       open( NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='OLD', POSITION='append', IOSTAT=ios, IOMSG=msg )
       if( ios /= 0 ) then
          write(*,*) "ERROR with file:",trim(filout)
          write(*,*) trim(msg)
          ! call merr( __FILE__, __LINE__ )
       end if

       WRITE(u0,'(5x,"|> ARTn research :",2(1x,i0)/,5x,*(a))') isearch, ifound, repeat("-",50)

       WRITE( u0,'(5X,"istep",4X,"ART_step",4X,"Etot",5x,"init/eign/perp/lanc/relx",&
            &4X," Ftot ",5X," Fperp ",4X," Fpara ",4X,"eigval", 6X, "delr", 2X, "npart", 1X,"evalf",2X,"a1")')
       ! -- Units
       WRITE( u0, strg_units )
       CLOSE( u0 )
    ENDIF
  END SUBROUTINE write_header_report



  !> @brief
  !!   a subroutine that writes a report of the current step to the output file
  !
  !> @param [in]  etot          energy of the system
  !> @param [in]  force         List of atomic forces
  !> @param [in]  fpara         List of parallel atomic forces
  !> @param [in]  fperp         List of perpendicular atomic forces
  !> @param [in]  lowest_eigval Lowest eigenvalue obtained by lanczos
  !> @param [in]  if_pos        Fix the atom or not
  !> @param [in]  istep         actual step of ARTn
  !> @param [in]  nat           Number of atoms
  !
  MODULE SUBROUTINE write_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
    !
    use m_artn_data, only: etot_init, delr_step
    USE artn_params, ONLY: STR_MOVE, verbose, filout,  &
         iinit, iperp, ieigen, irelax, iartn &
         ,converge_property, ninit  &
         ,lbasin, lrelax, in_lanczos_at_min &
                                !,lrelax, linit, lbasin, lperp, llanczos, leigen, lpush_over, lpush_final, lbackward, lrestart &
         , INIT, LANC, RELX, nrelax_print
    use precision, only: DP
    use m_block_lanczos, only: ilanc, a1
    USE UNITS
    IMPLICIT NONE

    ! -- Arguments
    INTEGER,  INTENT(IN) :: nat, istep
    INTEGER,  INTENT(IN) :: if_pos(3,nat)
    REAL(DP), INTENT(IN) :: force(3,nat),   &
         fpara(3,nat),   &
         fperp(3,nat)
    REAL(DP), INTENT(IN) :: etot, lowest_eigval

    ! -- Local Variables
    CHARACTER(LEN=5)     :: Mstep
    INTEGER              :: evalf, npart
    REAL(DP)             :: force_tot, fperp_tot, fpara_tot, detot, lowEig, dr
    !REAL(DP)             :: ctot, cmax
    REAL(DP), EXTERNAL   :: ddot !, dsum
    INTEGER              :: disp
    integer              :: ios, u0
    logical              :: print_it
    character(len=128)   :: msg

    !! No output
    IF( verbose == 0 ) RETURN

    print_it = .false.

    !
    ! ... Update iart counter: ARTn step start by Lanczos or Init push
    IF( (prev_disp==LANC .AND. ilanc==1) .OR. &
         (prev_disp==INIT .AND. iinit<=ninit)  )THEN
       !new_step = .true.
       iartn = iartn + 1
    ENDIF

    !
    ! ...Print each 5 step for RELX mode
    !IF( (prev_disp == RELX).AND.(mod(irelax,5) == 0) )print_it = .true.
    IF( (prev_disp == RELX).AND.(mod(irelax,nrelax_print) == 0) )print_it = .true.


    ! ...Print for the step 0
    IF( istep == 0 )print_it = .true.


    !
    ! ...Define when to print
    IF( verbose < 3.AND.(.NOT.print_it) )RETURN

    ! ...Load the previous displacement step to be coherent
    !     with the informtion gave in report
    disp = prev_disp

    !
    ! ...Force processing
    IF( trim(converge_property) == 'norm' )THEN
       !force_tot = sqrt( dsum( 3*nat, force*if_pos ) )
       !fpara_tot = sqrt( dsum( 3*nat, fpara ) )
       !fperp_tot = sqrt( dsum( 3*nat, fperp ) )
       force_tot = norm2( force*if_pos )
       fpara_tot = norm2( fpara )
       fperp_tot = norm2( fperp )
    ELSE
       force_tot = MAXVAL( ABS(force*if_pos) )
       fperp_tot = MAXVAL( ABS(fperp) )
       fpara_tot = MAXVAL( ABS(fpara) )
    ENDIF
    !
    ! .. Conversion Units
    force_tot = unconvert_force( force_tot )
    fperp_tot = unconvert_force( fperp_tot )
    fpara_tot = unconvert_force( fpara_tot )
    dEtot     = unconvert_energy(etot - etot_init)
    lowEig    = unconvert_hessian( lowest_eigval )


    !
    !%! More Complete Output
    Mstep              = "Mstep"
    IF( lbasin ) Mstep = 'Bstep'
    IF( .NOT.lbasin ) Mstep = 'Sstep'
    IF( lrelax .OR. in_lanczos_at_min) Mstep = 'Rstep'
    !
    !delr = sum()
    evalf = istep+1
    dr    = 0.
    npart = 0


    !
    !
    IF( verbose > 1 )THEN
       open( NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='OLD', POSITION='append', IOSTAT=ios, IOMSG=msg )
       if( ios /= 0 ) then
          write(*,*) "ERROR with file:",trim(filout)
          write(*,*) trim(msg)
          ! call merr( __FILE__, __LINE__ )
       end if
       WRITE(u0,6) iartn, Mstep, STR_MOVE(prev_push), detot, iinit, ieigen, iperp, ilanc, irelax,  &
            force_tot, fperp_tot, fpara_tot, lowEig, dr, npart, evalf, a1
            ! force_tot, fperp_tot, fpara_tot, lowEig, delr_step, npart, evalf, a1
6      FORMAT(5x,i4,3x,a,1x,a,F10.4,1x,5(1x,i4),5(1x,f10.4),2(1x,i5),3X,f4.2)
       FLUSH(u0)
       CLOSE(u0)
    ENDIF

  END SUBROUTINE write_report






  !> @brief
  !!   a subroutine that writes a report each new ARTn step
  !
  !> @param[in]  etot          energy of the system
  !> @param[in]  force         List of atomic forces
  !> @param[in]  fpara         List of parallel atomic forces
  !> @param[in]  fperp         List of perpendicular atomic forces
  !> @param[in]  lowest_eigval Lowest eigenvalue obtained by lanczos
  !> @param[in]  if_pos        Fix the atom or not
  !> @param[in]  istep         actual step of ARTn
  !> @param[in]  nat           Number of atoms
  !
  MODULE SUBROUTINE write_artn_step_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
    !
    use m_artn_data, only: etot_init, tau_init, tau_step, lat, natoms
    USE artn_params, ONLY: STR_MOVE, verbose, debrief, filout, &
          iinit, ieigen, irelax, iartn, &
          converge_property, ninit, &
          lbasin, lrelax, delr_thr
    use artn_params, only: delr_vec
    use precision, only: DP
    use m_tools, only: compute_delr_vec
    use m_block_lanczos, only: a1
    USE UNITS
    IMPLICIT NONE

    ! -- Arguments
    INTEGER,  INTENT(IN) :: nat, istep
    INTEGER,  INTENT(IN) :: if_pos(3,nat)
    REAL(DP), INTENT(IN) :: force(3,nat),   &
         fpara(3,nat),   &
         fperp(3,nat)
    REAL(DP), INTENT(IN) :: etot, lowest_eigval

    ! -- Local Variables
    CHARACTER(LEN=5)     :: Mstep
    INTEGER              :: evalf, i, npart
    REAL(DP)             :: force_tot, fperp_tot, fpara_tot, detot, lowEig, dr, r
    !REAL(DP)             :: ctot, cmax
    REAL(DP), EXTERNAL   :: ddot !, dsum
    !INTEGER              :: disp
    integer              :: ios, u0
    character(len=128)   :: msg
    LOGICAL              :: new_step


    new_step = .false.

    !disp = prev_disp

    !
    ! ...Force processing
    IF( trim(converge_property) == 'norm' )THEN
       !force_tot = sqrt( dsum( 3*nat, force*if_pos ) )
       !fpara_tot = sqrt( dsum( 3*nat, fpara ) )
       !fperp_tot = sqrt( dsum( 3*nat, fperp ) )
       force_tot = norm2( force*if_pos )
       fpara_tot = norm2( fpara )
       fperp_tot = norm2( fperp )
    ELSE
       force_tot = MAXVAL( ABS(force*if_pos) )
       fperp_tot = MAXVAL( ABS(fperp) )
       fpara_tot = MAXVAL( ABS(fpara) )
    ENDIF
    !
    ! .. Conversion Units
    force_tot = unconvert_force( force_tot )
    fperp_tot = unconvert_force( fperp_tot )
    fpara_tot = unconvert_force( fpara_tot )
    dEtot     = unconvert_energy(etot - etot_init)
    lowEig    = unconvert_hessian( lowest_eigval )


    !
    !%! More Complete Output
    Mstep              = "Mstep"
    IF( lbasin ) Mstep = 'Bstep'
    IF( .NOT.lbasin ) Mstep = 'Sstep'
    IF( lrelax ) Mstep = 'Rstep'
    !
    evalf = istep + 1
    dr    = 0.
    npart = 0


    !
    ! ...Displacement processing
    call allocate_var( 3, natoms, delr_vec, 0.0_DP )
    call compute_delr_vec( nat, tau_step, tau_init, lat, delr_vec )
    npart = 0
    DO i = 1, nat
       r = norm2(delr_vec(:,i))
       IF( r > delr_thr )npart = npart + 1
    ENDDO
    !! routine sum_force is equivalent to implicit: norm2( delr )
    !call sum_force( delr, nat, dr )
    dr = norm2( delr_vec )


    !
    ! ...Save the information for the resume of the search
    debrief = [ detot, force_tot, fpara_tot, fperp_tot, lowEig, real(npart,DP), dr, real(evalf,DP) ]

    ! No output
    ! IF( verbose == 0 ) RETURN

    !
    !
    IF( verbose > 1 )THEN
       open( NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='OLD', POSITION='append', IOSTAT=ios, IOMSG=msg )
       if( ios /= 0 ) then
          write(*,*) "ERROR with file:",trim(filout)
          write(*,*) trim(msg)
          ! call merr( __FILE__, __LINE__ )
       end if

       WRITE(u0,6) iartn, trim(Mstep)//"/"//STR_MOVE(prev_push), detot, iinit, ieigen, iperp_save, ilanc_save, irelax,  &
            force_tot, fperp_tot, fpara_tot, lowEig, dr, npart, evalf, a1
6      FORMAT(5x,i4,3x,a,F10.4,1x,5(1x,i4),5(1x,f10.4),2(1x,i5),3X,f4.2)

       CLOSE(u0)
    ENDIF

    !
    ! ...Re-Initialize the counter_save
    iperp_save = 0
    ilanc_save = 0


  END SUBROUTINE write_artn_step_report








  !> @brief
  !!   intermediate report between the saddle convergence and the
  !!   various minimum relaxation
  !
  !! @param[in]  pushfactor   sens of the push over at saddle point
  !! @param[in]  de(*)        energetic parameters depending on which push over it is
  !
  MODULE SUBROUTINE write_inter_report( pushfactor, de )
    !
    use precision, only: DP
    use units, only : unconvert_energy, unit_char
    use artn_params, only : artn_resume, istep, ifails, filout, verbose, &
         lpush_final, lbackward, debrief
    implicit none

    integer, intent( in )     :: pushfactor
    real(DP), intent( in )    :: de(*)        !> list of energies
    character(len=500)      :: dl
    character(2) :: DIR
    integer                   :: ios, u0
    character(len=128)        :: msg

    !! No output
    IF( verbose == 0 ) RETURN

    open( NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='OLD', POSITION='append', IOSTAT=ios, IOMSG=msg )
    if( ios /= 0 ) then
       write(*,*) "ERROR with file:",trim(filout)
       write(*,*) trim(msg)
       ! call merr( __FILE__, __LINE__ )
    end if

    IF( verbose > 1 ) THEN

       SELECT CASE( pushfactor )

       CASE( 1 )
          ! de(1) = de_back
          WRITE( u0, '(5X, "--------------------------------------------------")')
          WRITE( u0, '(5X, "|> ARTn converged to a forward minimum | backward E_act =", F12.5,1x,a)') &
               unconvert_energy( de(1) ), unit_char('energy')
          WRITE( u0, '(5X, "--------------------------------------------------")')
          WRITE (u0,'(5X, "|> number of steps:",1x, i0)') istep

          DIR = ":1" !"+1"

       CASE( -1 )
          ! de(1) = de_back
          ! de(2) = de_fwd
          ! de(3) = etot_init
          ! de(4) = etot_final
          ! de(5) = etot
          WRITE( u0,'(5X, "--------------------------------------------------")')
          WRITE( u0,'(5X, "|> ARTn converged to a backward minimum::")')
          WRITE( u0,'(5X, "--------------------------------------------------")')
          WRITE( u0,'(15X,"forward  E_act =", F12.5,1x,a)') unconvert_energy(de(2)), unit_char('energy')
          WRITE( u0,'(15X,"backward E_act =", F12.5,1x,a)') unconvert_energy(de(1)), unit_char('energy')
          WRITE( u0,'(15X,"reaction dE    =", F12.5,1x,a)') unconvert_energy((de(5)-de(4))), unit_char('energy')
          WRITE( u0,'(15X,"dEinit - dEfinal    =", F12.5,1x,a)') unconvert_energy((de(3)-de(5))), unit_char('energy')
          WRITE( u0,'(5X, "--------------------------------------------------")')
          WRITE( u0,'(5X, "|> Configuration Files:", 1X,A)') trim(artn_resume)
          !WRITE( *,'(5x, "|> Configuration Files:", 1X,A)') trim(artn_resume)
          WRITE( u0,'(5X, "--------------------------------------------------")')
          !WRITE( u,'(/)')

          DIR = ":2" !"-1"

       CASE DEFAULT
          WRITE( u0,'(5x,"********* ERROR write_inter_report:: pushfactor",1x,i0," **************")') pushfactor
          WRITE( *,'(5x,"********* ERROR write_inter_report:: pushfactor",1x,i0," **************")') pushfactor


       END SELECT

       ! ...Write the debrief line
       write(dl, '(5x,a,a,a)')       "|> DEBRIEF(RLX ",trim(dir),") |"
       write(dl, '(a,1x,a,g0.5,1x,a,a)')    trim(dl), "dE = ",Debrief(1), unit_char('energy'), " |"
       write(dl, '(a,1x,a,3(g0.5,2x),a,a)')trim(dl), "F_{tot,parap,perp} = ", Debrief(2:4), unit_char('force'), " |"
       write(dl, '(a,1x,a,g0.5,1x,a,a)')   trim(dl), "EigenVal = ",Debrief(5), unit_char('hessian'), " |"
       write(dl, '(a,1x,a,i0,1x,a)')       trim(dl), "npart = ", nint(Debrief(6)), " |"
       write(dl, '(a,1x,a,g0.5,1x,a,a)')   trim(dl), "delr = ",Debrief(7), unit_char('length')," |"
       write(dl, '(a,1x,a,i0,1x,a)')       trim(dl), "evalf = ", nint(Debrief(8)), " |"

       ! ...Write to artn output
       Write(u0, '(a)') trim(dl)
       write(u0,'(5x,*(a))') repeat("-",50)

    ENDIF

    !! if at the end
    IF( lpush_final .AND. (pushfactor == -1) .AND. .NOT.lbackward )  &
         WRITE(u0,'(5X,A7,1X,i0,1X,A)') 'ifail: ',ifails, trim(artn_resume)

    CLOSE(u0)

  END SUBROUTINE write_inter_report




  !> @brief
  !!   Report to finish the search
  !
  !! @param[in]   lsaddle        flag for saddle point convergence
  !! @param[in]   lpush_final    flag for final push
  !! @param[in]   de             energetic parameter

  MODULE SUBROUTINE write_end_report( lsaddle, lpush_final, de )
    !
    use precision, only: DP
    use units, only : unconvert_energy, unit_char
    use artn_params, only : artn_resume, verbose, istep, filout, debrief
    implicit none

    logical, intent( in ) :: lsaddle, lpush_final
    REAL(DP), intent( in ), value :: de
    character(len=500)  :: dl
    integer                   :: ios, u0
    character(len=128)        :: msg

    !! No output
    IF( verbose == 0 ) RETURN

    open( NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='OLD', POSITION='append', IOSTAT=ios, IOMSG=msg )
    if( ios /= 0 ) then
       write(*,*) "ERROR with file:",trim(filout)
       write(*,*) trim(msg)
       ! call merr( __FILE__, __LINE__ )
    end if

    IF( verbose > 1 )THEN

       if( lsaddle )then

          WRITE (u0,'(5X, "--------------------------------------------------")')
          WRITE (u0,'(5X, "|> ARTn found a potential saddle point | E_saddle - E_initial =", F12.5,1x,a)') &
               unconvert_energy(de), unit_char('energy')
          WRITE(u0,'(5X, "|> Stored in Configuration Files:", 1x,a)') trim(artn_resume)
          WRITE (u0,'(5X, "--------------------------------------------------")')

          !fmt_debrief = '(5x,"|> DEBRIEF(SADDLE) | dE= ",f12.5,x,"'//unit_char('energy')//' | F_{tot,para,perp}= ",3(f12.5,x),"' &
          !    //unit_char('force')// &
          !    ' | EigenVal= ", f12.5,x,"'//unit_char('hessian')//' | npart= ",f4.0,x," | delr= ",f12.5,x,"'//unit_char('length')// &
          !    ' | evalf= ",f5.0,x,"|")'
          !!Write(u0,fmt_debrief) Bilan
          !Write(u0,fmt_debrief) Debrief

          ! write debrief line
          write( dl, '(5x,a)') "|> DEBRIEF(SADDLE) |"
          write( dl, '(a,1x,a,g0.5,1x,a,a)')     trim(dl), "dE = ",                 Debrief(1),   unit_char('energy'),  " |"
          write( dl, '(a,1x,a,3(g0.5,2x),a,a)') trim(dl), "F_{tot,parap,perp} = ", Debrief(2:4), unit_char('force'),   " |"
          write( dl, '(a,1x,a,g0.5,1x,a,a)')     trim(dl), "EigenVal = ",           Debrief(5),   unit_char('hessian'), " |"
          write( dl, '(a,1x,a,i0,1x,a)')         trim(dl), "npart = ",         nint(Debrief(6)),                        " |"
          write( dl, '(a,1x,a,g0.5,1x,a,a)')     trim(dl), "delr = ",               Debrief(7),   unit_char('length'),  " |"
          write( dl, '(a,1x,a,i0,1x,a)')         trim(dl), "evalf = ",         nint(Debrief(8)),                        " |"

          ! write to artn output
          write(u0,'(a)') trim(dl)
          write(u0,'(5x,*(a))') repeat("-",50)


          IF( lpush_final ) THEN
             WRITE(u0,'(5X,"|> Pushing forward to a minimum  ***      ")')
             WRITE(u0,'(5X,"-------------------------------------------------")')
          ELSE
             WRITE(u0,'(5X,"|> No push_final to Minimum :: ARTn search finished "/5x,*(a))') repeat("-",50)
             WRITE(u0,'(5X,"-------------------------------------------------"/)')
          ENDIF

       else
          WRITE (u0,'(5X,"--------------------------------------------------")')
          WRITE (u0,'(5X,"|> ARTn saddle search failed  ***        ")')
          WRITE (u0,'(5X,"--------------------------------------------------")')
       endif

       WRITE (u0,'(5X,"|> number of steps:",1x, i0)') istep

    ENDIF
    CLOSE(u0)

  END SUBROUTINE write_end_report


  !------------------------------------------------------------
  !> @author
  !!   Matic Poberznik,
  !!   Miha Gunde
  !!   Nicolas Salles

  !> @brief
  !!   Fail report
  !
  !! @param[in]  disp        displacement parameters
  !! @param[in]  estep       Energy of actual step
  !
  MODULE SUBROUTINE write_fail_report( disp, estep )
    !
    use precision, only: DP
    use units, only : unconvert_energy, unit_char, unconvert_hessian
    use artn_params, only : STR_MOVE, ifails, error_message, filout, artn_resume, verbose
    use m_block_lanczos, only: lowest_eigval
    implicit none

    integer, intent( in ) :: disp
    REAL(DP), intent( in ):: estep
    integer               :: ios, u0
    character(len=128)    :: msg

    ifails = ifails + 1

    !! No output
    IF( verbose == 0 ) RETURN

    ! open file for writing
    open( NEWUNIT=u0, FILE=filout, FORM='formatted', STATUS='unknown', POSITION='append', IOSTAT=ios, IOMSG=msg )

    if( ios /= 0 ) then
       write(*,*) "ERROR with file:",trim(filout)
       write(*,*) trim(msg)
       call merr( __FILE__, __LINE__ , kill=.true.)
    end if



    IF( verbose > 1 ) THEN
       WRITE (u0,'(5X, "--------------------------------------------------")')
       WRITE (u0,'(5X, "        *** ARTn search failed ( ",i0," ) at ",a," *** ")') ifails, STR_MOVE(DISP)
       WRITE (u0,'(5X, "Step Params: Etot = ",f10.4,1x,a)') unconvert_energy(estep), unit_char('energy')
       WRITE (u0,'(5X, "Failure message: ",a)') trim(adjustl(error_message))
       WRITE (u0,'(5X, "--------------------------------------------------"//)')
       write(u0, *) "eval:",unconvert_hessian(lowest_eigval)
    ENDIF

    WRITE(u0,'(5X,A7,1X,i0,1X,A)') 'ifail: ', ifails, trim(artn_resume)

    CLOSE (u0)
  END SUBROUTINE write_fail_report




  module subroutine write_comment( output, txt )
    use precision, only : DP
    use artn_params, only : filout
    implicit none
    character(*), intent( in ) :: output, txt
    integer :: ios, u0
    character(len=128) :: msg
    open( NEWUNIT=u0, FILE=output, FORM='formatted', STATUS='OLD', POSITION='append', IOSTAT=ios, IOMSG=msg )
    if( ios /= 0 ) then
       write(*,*) "ERROR with file:",trim(output)
       write(*,*) trim(msg)
       call merr( __FILE__, __LINE__ )
    end if
    write( u0, '(5x,"|> ",a)' ) txt
    CLOSE( u0 )
  end subroutine write_comment

end submodule write_report_routines

