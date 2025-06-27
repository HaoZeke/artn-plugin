module m_move_mode
  use h_artn_precision, only: DP
  implicit none

contains



  !> @brief
  !!   translate specified move to appropriate force and set FIRE parameters accordingly
  !
  !> @param [in]    nat         Size of list: Number of atoms
  !> @param [in]    order       Order of engine atoms list
  !> @param [inout] force       List of force on atoms
  !> @param [inout] vel         List of atomic velicity
  !> @param [in]    alpha_init  Initial Value of alpha parameter of FIRE algorithm
  !> @param [in]    dt_init     Initial Value of dt parameter of FIRE algorithm
  !> @param [inout] etot        Actual energy total of the system
  !> @param [inout] alpha       Value of alpha paramter of FIRE algorithm
  !> @param [inout] dt_curr     Value of dt paramter of FIRE algorithm
  !> @param [inout] nsteppos    ??
  !> @param [in]    disp_code   encoder of actual displacement type
  !> @param [in]    displ_vec   Displacement field (unit lemgth/force/hessian )
  !
  !> @ingroup ARTn
  !> @snippet move_mode.f90 move_mode
  SUBROUTINE move_mode( nat, order, force, vel, etot, nsteppos, dt_curr, &
       alpha, alpha_init, dt_init, disp_code, displ_vec )

    !> [move_mode]
    USE d_artn_params, ONLY:  lbasin, iperp, irelax, push, &
         eigenvec, STR_MOVE , &
         filout
    use m_artn_report, only: prev_disp

    use h_artn_units, only: convert_time, unconvert_time, &
         unconvert_force, MASS, is_finite

    use m_error
    use m_artn_tools, only: ddot

    !use debug, only: report_atom_prop
    !
    IMPLICIT NONE
    !
    ! -- Arguments
    INTEGER, value,             INTENT(IN)    :: nat
    INTEGER,                    INTENT(IN)    :: order(nat)
    REAL(DP), DIMENSION(3,nat), INTENT(IN)    :: displ_vec
    REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: force !should be just out
    REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: vel
    REAL(DP),                   INTENT(IN)    :: alpha_init, dt_init
    REAL(DP),                   INTENT(INOUT) :: etot, alpha, dt_curr
    INTEGER,                    INTENT(INOUT) :: nsteppos
    INTEGER,                    INTENT(IN)    :: disp_code
    !
    ! -- Local Variables
    REAL(DP)                                  :: dt0, dt, tmp0, tmp1 !, dr(3,nat)
    logical :: all_ok
    !character(256) :: ctmp
    !
    ! do things depending on mode of the move
    ! NOTE force units of Ry/a.u. are assumed ...
    !
    ! write(*,*) ">>>:::  enter move_mode"
    ! write(*,*) "dt curr",dt_curr


    ! .. Convert the force & time
    !force = convert_force( displ_vec )
    dt  = convert_time( dt_curr )
    dt0 = convert_time( dt_init )   !%! Finally we don't touch dt_init

    !
    ! write(*,*) "move mode received:",STR_MOVE(disp_code)

    all_ok = all( is_finite(displ_vec) .eqv. .true. )
    if( .not. all_ok ) then
       !! nan or inf in displ_vec
       call err_set(ERR_OTHER, __FILE__,__LINE__,msg="NaN in displ_vec!")
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if


    ! ...Save actuall displacement
    prev_disp = disp_code


    SELECT CASE( STR_MOVE(disp_code) )
       !
    CASE( 'init' )
       !
       etot     = 1.D0
       vel(:,:) = 0.D0
       alpha    = 0.0_DP
       dt       = dt0
       nsteppos = 0
       !
       ! ...Displ_vec should be a Length
       ! write(*,*) ":: dt used in move_mode",dt
       ! write(*,*) "mass used in move_mode:",mass
       force(:,:) = displ_vec(:,order(:))*Mass/dt**2
       !
    CASE( 'perp' )
       !
       ! ...Displ_vec is fperp
       force(:,:) = displ_vec(:,order(:))
       !
       IF( iperp - 1 .eq. 0 ) THEN  !%! Because I increment iperp before to enter in move_mode
          ! for the first step forget previous velocity (prevent P < 0)
          etot     = 0.D0
          vel(:,:) = 0.D0
          alpha    = alpha_init
          dt       = dt0
          nsteppos = 5

          !
       ELSE
          !
          ! subtract the components that are parallel
          IF( lbasin ) THEN
             tmp0     = ddot( 3*nat, vel(:,:), 1, push(:,order(:)), 1 )
             tmp1     = ddot( 3*nat, push(:,:), 1, push(:,:), 1 )          !! Don't need to be ordered
             vel(:,:) = vel(:,:) - tmp0 / tmp1 * push(:,order(:))
             !print*, "MOVE MODE:", tmp0, tmp1
          ELSE
             tmp0     = ddot( 3*nat, vel(:,:)     , 1, eigenvec(:,order(:)), 1 )
             tmp1     = ddot( 3*nat, eigenvec(:,:), 1, eigenvec(:,:), 1 )  !! Don't need to be ordered
             vel(:,:) = vel(:,:) - tmp0 / tmp1 * eigenvec(:,order(:))
          ENDIF
          !
       ENDIF
       !
       !
    CASE( 'eign', 'over', 'smth', 'lanc' )
       !
       etot       = 0.D0
       vel(:,:)   = 0.D0
       alpha      = 0.0_DP
       dt         = dt0
       nsteppos   = 0
       force(:,:) = displ_vec(:,order(:))*Mass/dt**2
       !
    CASE( 'relx' )
       !forc_thr = 10D-8    !! QE dependent
       IF( irelax == 1 ) THEN
          alpha    = alpha_init
          dt       = dt0
       ENDIF
       !
       ! ... We reaload because it is unconverted at this place
       force(:,:) = displ_vec(:,order(:))
       !
    CASE( 'void' )
       force(:,:) = 0.0_DP
       vel(:,:) = 0.0_DP
       alpha = alpha_init
       dt = dt0

    case( 'rset' )
       ! vel(:,:)   = 0.D0
       ! alpha      = 0.0_DP
       ! dt         = dt0
       ! nsteppos   = 0
       force(:,:) = displ_vec(:,order(:))*Mass/dt**2

    CASE default
       !
       write(*,'(5x,"|> No parameter conversion in move_mode:",1x,a)') STR_MOVE(disp_code)
       !
    END SELECT

    !
    ! ...Unconvert the force & time
    dt_curr = unconvert_time( dt )
    force = unconvert_force( force )


    ! write(*,*) "exit move_mode"
    !> [move_mode]
  END SUBROUTINE move_mode



end module m_move_mode
