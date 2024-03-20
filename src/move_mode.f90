module m_move_mode
  use precision, only: DP
  implicit none

contains

  !! C wrapper to move_mode
  subroutine move_mode_c( c_nat, c_order, c_force, c_vel, c_etot, c_nsteppos, c_dt_curr, &
       c_alpha, c_alpha_init, c_dt_init, c_disp, c_displ_vec ) bind(C,name="move_mode_c")
    use, intrinsic :: iso_c_binding, only: c_int, c_double
    integer( c_int ), value,              intent(in)    :: c_nat
    integer( c_int ),                     intent(in)    :: c_order(c_nat)
    real( c_double ), dimension(3,c_nat), intent(inout) :: c_force
    real( c_double ), dimension(3,c_nat), intent(inout) :: c_vel
    real( c_double ),                     intent(inout) :: c_etot
    integer( c_int ),                     intent(inout) :: c_nsteppos
    real( c_double ),                     intent(inout) :: c_dt_curr
    real( c_double ),                     intent(inout) :: c_alpha
    real( c_double ),                     intent(in)    :: c_alpha_init
    real( c_double ),                     intent(in)    :: c_dt_init
    integer( c_int ),                     intent(in)    :: c_disp
    real( c_double ), dimension(3,c_nat), intent(in)    :: c_displ_vec

    integer                    :: nat
    integer                    :: order(c_nat)
    real(dp), dimension(3,c_nat) :: displ_vec
    real(dp), dimension(3,c_nat) :: force
    real(dp), dimension(3,c_nat) :: vel
    real(dp)                   :: alpha_init, dt_init
    real(dp)                   :: etot, alpha, dt_curr
    integer                    :: nsteppos
    integer                    :: disp

    !! transfer input to F
    nat = int( c_nat )
    order = int( c_order )
    force = real( c_force, DP )
    vel = real( c_vel, DP )
    etot = real( c_etot, DP )
    nsteppos = int( c_nsteppos )
    dt_curr = real( c_dt_curr, DP )
    alpha = real( c_alpha, DP )
    alpha_init = real( c_alpha_init, DP )
    dt_init = real( c_dt_init, DP )
    disp = int( c_disp )
    displ_vec = real( c_displ_vec, DP )

    call move_mode( nat, order, force, vel, etot, nsteppos, dt_curr, alpha, alpha_init, dt_init, disp, displ_vec )

    !! transfer output
    c_force = real( force, c_double )
    c_vel = real( vel, c_double )
    c_etot = real( etot, c_double )
    c_nsteppos = int( nsteppos, c_int )
    c_dt_curr = real( dt_curr, c_double )
    c_alpha = real( alpha, c_double )
  end subroutine move_mode_c



  !> @author Matic Poberznik,
  !!         Miha Gunde,
  !!         Nicolas Salles
  !
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
  !> @param [in]    disp        Kind of actual displacement
  !> @param [in]    displ_vec   Displacement field (unit lemgth/force/hessian )
  !
  !> @ingroup ARTn
  !> @snippet move_mode.f90 move_mode
  SUBROUTINE move_mode( nat, order, force, vel, etot, nsteppos, dt_curr, alpha, alpha_init, dt_init, disp, displ_vec )

    !> [move_mode]
    USE artn_params, ONLY:  lbasin, iperp, irelax, push, &
         eigenvec, MOVE , &
         prev_disp, filout

    USE UNITS, Only: convert_time, unconvert_time, &
         unconvert_force, MASS
    use precision, only: DP

    !use debug, only: report_atom_prop
    !
    IMPLICIT NONE
    !
    ! -- Arguments
    INTEGER, value,             INTENT(IN)    :: nat
    INTEGER,                    INTENT(IN)    :: order(nat)
    REAL(DP), DIMENSION(3,nat), INTENT(IN)    :: displ_vec
    REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: force
    REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: vel
    REAL(DP),                   INTENT(IN)    :: alpha_init, dt_init
    REAL(DP),                   INTENT(INOUT) :: etot, alpha, dt_curr
    INTEGER,                    INTENT(INOUT) :: nsteppos
    INTEGER,                    INTENT(IN)    :: disp
    !
    ! -- Local Variables
    REAL(DP)                                  :: dt0, dt, tmp0, tmp1 !, dr(3,nat)
    REAL(DP), EXTERNAL                        :: ddot,dnrm2, dsum
    !INTEGER                                   :: u0
    !character(256) :: ctmp
    !
    ! do things depending on mode of the move
    ! NOTE force units of Ry/a.u. are assumed ...
    !
    ! .. Convert the force & time
    !force = convert_force( displ_vec )
    dt  = convert_time( dt_curr )
    dt0 = convert_time( dt_init )   !%! Finally we don't touch dt_init
    !u0  = 73

    !


    ! ...Save actuall displacement
    prev_disp = disp


    SELECT CASE( MOVE(disp) )
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

    CASE default
       !
       write(*,'(5x,"|> No parameter conversion in move_mode:",1x,a)') MOVE(disp)
       !
    END SELECT

    !
    ! ...Unconvert the force & time
    dt_curr = unconvert_time( dt )
    force = unconvert_force( force )


    !> [move_mode]
  END SUBROUTINE move_mode





end module m_move_mode
