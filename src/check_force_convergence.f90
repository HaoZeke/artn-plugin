submodule( m_artn ) check_force_convergence_r
  implicit none

  !! local counters
  INTEGER, SAVE :: noperp=0  !< @brief  count number of time perp-relax is not done

contains

  !> @author
  !!   Matic Poberznik,
  !!   Miha Gunde,
  !!   Nicolas Salles,
  !!   Antoine Jay
  !
  !> @brief Check the force convergence
  !
  !> @par Purpose
  !  ============
  !>  A subroutine that checks the force convergence of a particular step in the artn algorithm
  !!  and changes the block flags if needed.
  !
  !> @param [in]   nat             Size of list: number of atoms
  !> @param [in]   force           Force field
  !> @param [in]   if_pos          List of atom move or not
  !> @param [in]   fperp           Perpendicular Force Field
  !> @param [in]   fpara           Parallel Force Field
  !> @param [out]  lforc_conv      Force Convergence Flag
  !> @param [out]  lsaddle_conv    Saddle-point Convergence Flag
  !
  MODULE SUBROUTINE check_force_convergence( nat, force, if_pos, fperp, fpara, lforc_conv, lsaddle_conv )
    !
    use h_artn_units, ONLY : unconvert_force
    use d_artn_data, only: etot_step
    use d_artn_params, ONLY: linit, leigen, llanczos, lperp, lrelax, lbasin, nperp_step, nperp_limitation, &
         iperp, nperp, nperp_step, istep, &
         forc_thr, verbose, iinit, ninit, in_lanczos_at_min, &
         converge_property, ismooth, nsmooth, restart_freq, inewchance, &
         filout
    use m_artn_option, only: write_restart, nperp_limitation_step
    use m_artn_report, only: write_artn_step_report, iperp_save
    use m_block_lanczos, only: ilanc, lowest_eigval
    use m_artn_tools, only: ddot
    !
    IMPLICIT NONE
    INTEGER,  INTENT(IN)  :: nat
    REAL(DP), INTENT(IN)  :: force(3,nat)
    REAL(DP), INTENT(IN)  :: fperp(3,nat)
    REAL(DP), INTENT(IN)  :: fpara(3,nat)
    INTEGER,  INTENT(IN)  :: if_pos(3,nat)
    !INTEGER, INTENT(IN)  :: order(nat)
    LOGICAL,  INTENT(OUT) :: lforc_conv, lsaddle_conv
    !
    ! Local Variables
    LOGICAL               :: C0,C1, C2, C3, C4
    integer               :: ios, u0
    REAL(DP)              :: maxforce, maxfperp, maxfpara
    !REAL(DP)              :: min_dir(3,nat)
    !
    C0           = .false.
    C1           = .false.
    C2           = .false.
    C3           = .false.
    C4           = .false.
    lforc_conv   = .false.
    lsaddle_conv = .false.
    !
    ! in lanczos, never converge
    IF( llanczos ) return
    !
    ! ...Compute the variable
    IF( trim(converge_property) == 'norm' )THEN
       !call sum_force( force*if_pos, nat, maxforce )
       !call sum_force( fpara, nat, maxfpara )
       !call sum_force( fperp, nat, maxfperp )
       maxforce = norm2( force*real(if_pos,DP) )
       maxfpara = norm2( fpara )
       maxfperp = norm2( fperp )
    ELSE
       maxforce = MAXVAL(ABS(force*real(if_pos,DP)))
       maxfpara = MAXVAL(ABS(fpara))
       maxfperp = MAXVAL(ABS(fperp))
    ENDIF

    ! ...Write the restart file at every step - QE (not in llanczos)
    if( restart_freq == 1 )then
       call write_restart()
    end if

    !
    ! This routine is relevant only when lperp=.true. or lrelax=.true.
    !
    ! if( .not.( lperp .or. lrelax ) ) return

    !
    IF ( lperp ) THEN
       !
       ! ...Compute Force evolution
       IF ( leigen ) THEN ! ... NOT IN BASIN

          ! we enter this block when perp relaxing after eigen push.

          !
          ! ... Is the system converged to saddle?
          C0 = ( maxforce < forc_thr )
          IF( C0 ) THEN
             lsaddle_conv = .true.
             iperp_save = iperp  !! save iperp before the write_report()
             if( restart_freq == 2 )then
                call write_restart()
             end if

             CALL write_ARTn_step_report( etot_step, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
             RETURN
          ENDIF


          !
          ! ... Conditions for stopping perp_relax
          C2 = ( nperp >= 0 .AND. iperp >= nperp )  ! check on the number of perp-relax iterations
          C3 = ( MAXfperp < MAXfpara )             ! check wheter fperp is lower than fpara

          IF( C3 .and. iperp == 0 ) C1 = .false. ! Force to do at least one perp-relax. NOTE: should be C3=.false.?
          IF( nsmooth > 0 .AND. ismooth <= nsmooth )C3 = .False.  ! Force to do a perp relax during the smooth step

          !
          ! ...Alignment between fperp and direction of minimum
          C4 = fperp_min_alignment( 0.8_DP, 0.1_DP )

          !
          ! ...Stopping condition is filled, switch to lanczos
          IF( C2 .OR. C3 .OR. C4 )THEN
             lperp    = .false.
             leigen   = .false.
             llanczos = .true.
             ilanc    = 0
             iperp_save = iperp  !! save iperp before the write_report()
             !
             if( restart_freq == 2 )then
                call write_restart()
             end if

             CALL write_ARTn_step_report( etot_step, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
             !
          ENDIF
          !
          !
       ELSE ! ... IN  BASIN

          ! we enter this block when doing perp relax after initial push
          !write(*,'(3x,"Check_Force> In Basin: ",i0,1x,i0)')iperp, nperp

          !
          ! ... Conditions for stopping perp_relax
          C2 = ( nperp > -1 .AND.iperp >= nperp ) ! check on the number of perp-relax iterations
          !
          ! ... Stopping condition is filled, switch to lanczos or to init if we are still close to the minimum
          IF( C2 )THEN
             IF( iinit < ninit ) THEN
                ! continue with doing init pushes
                linit    = .true.
             ELSE
                ! start computing lanczos
                linit    = .false.
                llanczos = .true.
                ilanc    = 0
             ENDIF
             lperp = .false.
             iperp_save = iperp  !! save iperp before the write_report()
             !
             if( restart_freq == 2 )then
                call write_restart()
             end if

             CALL write_ARTn_step_report( etot_step, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
          ENDIF
          !
          ! ...Count if fperp is always to small after each init push
          IF ( C1 .AND. iperp == 0) noperp = noperp + 1    !!NOTE: should be IF( C2 .AND. ... )?
          !
       ENDIF

       !
       !
       ! ... Show Stop perp message
       IF( verbose > 2 )THEN
          OPEN( NEWUNIT=u0, FILE = filout, FORM = 'formatted', POSITION = 'append', STATUS = 'unknown', IOSTAT = ios )
111       format(12x,a46,1x,f10.4,1x,a1,1x,f10.4,a20)
112       format(12x,a46,1x,i0,1x,a1,1x,i0)

          IF ( C0 ) WRITE(u0,111) &
               "|> Stop perp relax because force < forc_thr  :",&
               unconvert_force( maxforce ),"<", unconvert_force(forc_thr), TRIM(converge_property)

          IF ( C2 ) WRITE(u0,112) &
               "|> Stop perp relax because iperp = nperp max :",&
               iperp,"=",nperp
          !
          IF ( C3 ) WRITE(u0,111) &
               "|> Stop perp relax because fperp < fpara     :",&
               unconvert_force( maxfperp ),"<", unconvert_force( maxfpara ), TRIM(converge_property)
          !
          IF ( C3 .AND. iperp == 0) WRITE(u0,111) &
               "|> No perp relax because fperp < fpara       :",&
               unconvert_force( maxfperp ),"<", unconvert_force( maxfpara ), TRIM(converge_property)
          !
          IF ( C4 ) WRITE(u0,'(5x,"|> No perp relax because fperp is directed towards the starting minimum ")')
          !
          IF ( noperp > 2 ) WRITE(u0,'(5x,a90)') &  !! NOTE: This can never happen... noperp=0 always
               "|> WARNING -The Fperp is too small after each Push-INIT- You should increase push_step_size"
          CLOSE( u0 )
          !
       ENDIF

       !
       !... If perp relax is finished: lperp flag was switched off,
       ! update counter and update number of allowed perp_relax steps
       IF (.NOT. lperp ) THEN
          !iperp_save = iperp
          iperp      = 0
          IF ( .NOT. lbasin) THEN
             ! move the nperp steps to next value in nperp_limitation sequence
             !nperp_step = nperp_step + 1
             !nperp = nperp_limitation(MIN(SIZE(nperp_limitation), nperp_step))
             call nperp_limitation_step( 1 )  !! Should that
          ELSE
             IF( inewchance == 0 )nperp = nperp_limitation(1)
          ENDIF
       ENDIF
       !


    ELSE IF ( lrelax ) THEN

       ! we enter this block only when relaxing
       !
       ! ... Check if Minimum has been reached
       C0 = ( maxforce < forc_thr )
       IF ( C0 ) THEN
          lforc_conv = .true.
          CALL write_ARTn_step_report( etot_step, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
          !
          ! ... Show Stop relax message
          IF( verbose > 1 .AND. .NOT. in_lanczos_at_min )THEN
             OPEN( NEWUNIT = u0, FILE = filout, FORM = 'formatted', POSITION = 'append', STATUS = 'unknown', IOSTAT = ios )
             WRITE(u0,111) &
                  "|> Stop relax because force < forc_thr       :",&
                  unconvert_force( MAXforce ),"<", unconvert_force( forc_thr ), TRIM(converge_property)
             CLOSE( u0 )
          ENDIF
       ENDIF
       !
    ENDIF
    !
  END SUBROUTINE check_force_convergence



  !> @brief Alignment Fperp/min
  !!
  !> @par Purpose
  !  ============
  !>   compute the 2 conditions:
  !!    - eigenVec has been suddenlly changed
  !!    - direction of minimum is perp to the last push
  !!
  !> @param[in] thr1    threshold on the eigenvec alignement
  !> @param[in] thr2    threshold in the fperp - direction of minimum alignment
  !> @return   Logical .true. if Fperp is aligned with min direction
  !
  module logical function fperp_min_alignment( thr1, thr2 )result( res )
    use h_artn_precision, only : DP
    USE d_artn_data, only : tau_step, tau_init, natoms
    use d_artn_params, only: push
    use m_block_lanczos, only: a1
    use m_artn_tools, only: ddot
    implicit none

    !integer :: i
    real(DP), intent(in) :: thr1, thr2
    REAL(DP) :: min_dir(3,natoms), dtmp

    min_dir = tau_step - tau_init
    min_dir = min_dir / NORM2( min_dir )
    dtmp = ddot(3*natoms,min_dir,1,push,1)

    !! IF eigenVec change suddenlly AND direction of minimum is perp to the last push
    res = ( a1 < thr1 .AND. ABS(dtmp) < thr2 )

  end function fperp_min_alignment

end submodule check_force_convergence_r
