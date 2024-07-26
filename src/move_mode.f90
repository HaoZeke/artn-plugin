module m_move_mode
  use precision, only: DP
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
    USE artn_params, ONLY:  lbasin, iperp, irelax, push, &
         eigenvec, STR_MOVE , &
         filout
    use m_artn_report, only: prev_disp

    USE UNITS, Only: convert_time, unconvert_time, &
         unconvert_force, MASS, is_finite

    use m_error
    use m_tools, only: ddot

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
             print*, "MOVE MODE:", tmp0, tmp1
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


  !> @details
  !! C-wrapper to move_mode() routine.
  !! Visible as "move_mode()" from C.
  !!
  !! C-header:
  !!~~~~~~~~~~~~~~~~~~~~{.c}
  !! void move_mode(const int nat,
  !!                const int *order,
  !!                double *const f,
  !!                double *const vel,
  !!                double *etot,
  !!                int *nsteppos,
  !!                double *dt_curr,
  !!                double *alpha,
  !!                const double *alpha_init,
  !!                const double *dt_init,
  !!                int *disp,
  !!                double *disp_vec );
  !!~~~~~~~~~~~~~~~~~~~~
  !!
  subroutine move_mode_c( c_nat, c_order, c_force, c_vel, c_etot, c_nsteppos, c_dt_curr, &
       c_alpha, c_alpha_init, c_dt_init, c_disp, c_displ_vec ) bind(C,name="move_mode")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    integer( c_int ), value, intent(in)    :: c_nat                ! Size of list: Number of atoms
    integer( c_int ),        intent(in)    :: c_order(c_nat)       ! Order of engine atoms list
    real( c_double ),        intent(inout) :: c_force(3,c_nat)     ! force on atoms
    real( c_double ),        intent(inout) :: c_vel(3,c_nat)       ! atomic velicity
    real( c_double ),        intent(inout) :: c_etot               ! Actual energy total of the system
    integer( c_int ),        intent(inout) :: c_nsteppos           ! ??
    real( c_double ),        intent(inout) :: c_dt_curr            ! Value of dt of FIRE algorithm
    real( c_double ),        intent(inout) :: c_alpha              ! Value of alpha of FIRE algorithm
    real( c_double ),        intent(in)    :: c_alpha_init         ! Initial Value of alpha of FIRE algorithm
    real( c_double ),        intent(in)    :: c_dt_init            ! Initial Value of dt of FIRE algorithm
    integer( c_int ),        intent(in)    :: c_disp               ! Kind of actual displacement
    real( c_double ),        intent(in)    :: c_displ_vec(3,c_nat) ! Displacement field (unit lemgth/force/hessian )

    !! fortran variables
    integer  :: nat
    integer  :: order(c_nat)
    real(dp) :: displ_vec(3,c_nat)
    real(dp) :: force(3,c_nat)
    real(dp) :: vel(3,c_nat)
    real(dp) :: alpha_init, dt_init
    real(dp) :: etot, alpha, dt_curr
    integer  :: nsteppos
    integer  :: disp

    !! transfer input to F
    nat        = int( c_nat )
    order      = int( c_order )
    force      = real( c_force, DP )
    vel        = real( c_vel, DP )
    etot       = real( c_etot, DP )
    nsteppos   = int( c_nsteppos )
    dt_curr    = real( c_dt_curr, DP )
    alpha      = real( c_alpha, DP )
    alpha_init = real( c_alpha_init, DP )
    dt_init    = real( c_dt_init, DP )
    disp       = int( c_disp )
    displ_vec  = real( c_displ_vec, DP )

    call move_mode( nat, order, force, vel, etot, nsteppos, dt_curr, &
         alpha, alpha_init, dt_init, disp, displ_vec )

    !! transfer output to C
    c_force    = real( force, c_double )
    c_vel      = real( vel, c_double )
    c_etot     = real( etot, c_double )
    c_nsteppos = int( nsteppos, c_int )
    c_dt_curr  = real( dt_curr, c_double )
    c_alpha    = real( alpha, c_double )
  end subroutine move_mode_c




end module m_move_mode
