
module m_artn_step
  use h_artn_precision, only: DP
  implicit none

  private
  public :: artn_step, artn_step_reset


  ! real(DP), parameter :: &
  !      dt_init    = 20.0_DP ,& !< @brief in units of ARTn (AU)
  !      alpha_init = 0.2_DP

  !! current values of fire parameters
  real(DP), save :: dt_init, alpha_init
  real(DP), save :: dt, alpha
  integer, save :: nsteppos
  real(DP), save, allocatable :: vel(:,:)

contains

  subroutine artn_step( nat, etot, eng_force, ityp, pos, box, if_pos, displ_vec, lconv )
    !! experimental routine to perform single step of artn research
    use m_error, only: err_write, merr
    use m_setup_artn, only: setup_artn, clean_artn
    use m_artn, only: artn
    use m_move_mode, only: move_mode
    use m_fire !, only: fire_init, fire_step
    use m_artn_units, only: convert_time, unconvert_time, convert_force, &
         unconvert_force, unconvert_length, convert_energy !, mass
    use artn_params, only: istep, elements, str_move
    implicit none
    INTEGER,            INTENT(IN)    :: nat              ! number of atoms
    REAL(DP),           INTENT(IN)    :: etot             ! total energy in current step
    REAL(DP),           INTENT(IN)    :: eng_force(3,nat) ! force calculated by the engine
    INTEGER,            INTENT(IN)    :: ityp(nat)        ! atom types
    REAL(DP),           INTENT(IN)    :: pos(3,nat)       ! positions
    REAL(DP),           INTENT(IN)    :: box(3,3)         ! lattice parameters in alat units; in columns box(:,i)
    INTEGER,            INTENT(IN)    :: if_pos(3,nat)    ! coordinates fixed by engine
    REAL(DP),           INTENT(OUT)   :: displ_vec(3,nat) ! displacement vector
    LOGICAL,            INTENT(OUT)   :: lconv            ! flag for controlling convergence

    CHARACTER(*), PARAMETER :: here = "artn_step"
    !
    integer :: order(nat)
    integer :: i, disp_code
    real(DP) :: force(3,nat)!, vel(3,nat)
    logical :: lerror
    real(DP) :: dt_init_a, dt_a
    integer :: typ(nat)
    real(DP) :: tau(3,nat)
    real(DP) :: aetot
    real(DP) :: fire_dt
    !
    integer :: ierr
    logical :: verbose

    verbose = .true.
    verbose = .false.

    if( verbose )write(*,*) "::>> enter artn_step", nat

    if( verbose .and. istep == 0 ) write(*,'(1x,a,"> Setup ARTn")') here
    call setup_artn( nat, lerror )
    if( lerror ) then
       call err_write(__FILE__,__LINE__)
       ! call merr(__FILE__,__LINE__,kill=.true.)
       lconv=.true.
       return
    end if

    if( istep == 0 ) then
       !! init fire (unconvert dt_init)
       ierr = fire_init()
       if( ierr /= 0 ) then
          call err_write(__FILE__,__LINE__)
          ! call merr( __FILE__,__LINE__,kill=.true.)
          lconv=.true.
          return
       end if
       !! initialize current values for dt and alpha
       !! dt is now in units of ARTn (AU)
       ierr = fire_get( "dt_init", dt_init )
       ierr = fire_get( "alpha_init", alpha_init )
       dt = dt_init
       alpha = alpha_init
       ! allocate velocity for fire
       if( allocated(vel))deallocate(vel)
       ALLOCATE(vel(3,nat), source=0.0_DP)
       !!
    end if


    if( verbose ) then
       block
         !! Write the position in file=xout at each step
         integer :: u0
         if( istep == 0 ) then
            open(newunit=u0, file="xout.xyz", status="replace" )
         else
            open(newunit=u0, file="xout.xyz", status="old", position="append" )
         end if
         write(u0, *) nat
         write(u0,'(a,9(1x,g12.5),a,1x,i0,1x,a,g12.5)') &
              'Lattice="',box,'" properties=id:I:1:species:I:1:pos:R:3 istep=',istep, "Energy=",etot
         do i = 1, nat
            write(u0,'(2(1x,i0),3(1x,g12.5))') i, ityp(i), pos(:,i)
         end do
         close(u0)
       end block
    end if


    force = eng_force
    do i = 1, nat
       order(i) = i
    end do
    aetot = etot
    typ = ityp

    !! copy input positions, to not modify the actual pos in artn
    !! (if this gets changed, remove the inclusion of tau_sad-tau_step for lbackward)
    tau = pos

    !! take force in engine units, return displ_vec (not always) in bohr
    if( verbose )write(*,*) here,"> ARTn()..."
    call artn( nat, aetot, force, typ, tau, order, box, if_pos, disp_code, displ_vec, lconv )

    if( verbose )write(*,*) here, "> step is: ",str_move(disp_code)
    if( verbose )write(*,*) here,"> displ_vec after ARTn", norm2(displ_vec)

    !! now: displ_vec = dr (bohr)

    !! convert dt from au into engine units
    dt_a = unconvert_time(dt)
    dt_init_a = unconvert_time( dt_init )

    !! take displ_vec from above, return force, fire params in engine units
    if( verbose )write(*,*) here,"> Move_Mode()..."
    call move_mode( nat, order, force, vel, aetot, nsteppos, &
         dt_a, alpha, alpha_init, dt_init_a, disp_code, displ_vec )

    !! skip calling fire on error, since displ_vec might not be set (NaN)
    block
      use m_artn_data, only: has_error
      !! need to do somethign better than this!!
      if( lconv .and. has_error ) return
    end block


    !! convert force and dt from engine units into artn units for fire algorithm
    force = convert_force(force)
    fire_dt = convert_time(dt_a)
    ! fire_dt = dt_a

    !! now :: force = displ_vec * mass / dt^2  (in artn units)

    !! take force from above, return displ_vec always
    if( verbose )write(*,*) here,"> Fire_Step()..."
    call fire_step( nat, force, nsteppos, vel, fire_dt, alpha, displ_vec )

    dt = fire_dt


    if( verbose )write(*,*) here,"> displ_vec after FIRE", norm2(displ_vec)
    !! displ_vec returned seems to be in bohr.
    ! unconvert for the engine
    displ_vec = unconvert_length(displ_vec)

    !! at push to backward relax, artn does not specify the full displ_vec, but only push from saddle,
    !! and the actual positions are modified. Here, want to avoid modif of actual positions, all is stored
    !! only in the displ_vec. Need to detect the step of backward push, and include the change
    !! in positions `tau` into displ_vec:
    block
      use artn_params, only: lbackward
      use m_artn_data, only: tau_sad, tau_step !, tau_init
      if( str_move(disp_code) == "relx" .and. lbackward ) then
         ! write(*,*) "push backward: step", istep
         displ_vec = displ_vec + tau_sad(:,:) - tau_step(:,:)

      elseif( str_move(disp_code) == "relx" .and. lconv ) then
         !! in this case, we are at convergence and positions are normally reset to initial in artn,
         !! however do not include this into displ_vec here, since the application
         !! might do something else.

      end if
    end block

    if( verbose )write(*,*) here,"> displ_vec after unconvert", norm2(displ_vec)

    ! ---
    ! If artn converges make clean exit
    !! Clean_artn() should not be called here, but outside.
    !! Reason: it causes some parameters to be reset, which is maybe not what the application expects.
    ! if( lconv )then
    !    write(*,*) here,"> Clean_ARTn()..."
    !    call clean_artn()
    ! endif
    ! ---

    !!dr = dt^2 * F/m
    if( verbose )write(*,*) "::>> exit artn_step"

  end subroutine artn_step



  !! C wrapper
  !!
  !! C-header
  !!~~~~~~~~~~~~~~~~{.c}
  !! void artn_step(
  !!                const int nat,
  !!                const double etot,
  !!                double *const force,
  !!                int const *ityp,
  !!                double *const pos,
  !!                const double *box,
  !!                const int *if_pos,
  !!                double *displ_vec,
  !!                bool *lconv);
  !!~~~~~~~~~~~~~~~~
  subroutine artn_cstep( cnat, cetot, ceng_force, ctyp, cpos, cbox, cif_pos, cdispl_vec, clconv )&
       bind(C, name="artn_step" )
    use, intrinsic :: iso_c_binding
    use h_artn_precision, only: DP
    use m_artn_tools, only: c_malloc
    implicit none
    integer( c_int ), intent(in), value :: cnat
    real( c_double ), intent(in), value :: cetot
    real( c_double ), intent(in) :: ceng_force(3,cnat)
    integer( c_int ), intent(in) :: ctyp(cnat)
    real( c_double ), intent(in) :: cpos(3,cnat)
    real( c_double ), intent(in) :: cbox(3,3)
    integer( c_int ), intent(in) :: cif_pos(3,cnat)
    ! type( c_ptr ) :: cdispl_vec
    real( c_double ), intent(out) :: cdispl_vec(3,cnat)
    logical( c_bool ), intent(out) :: clconv

    integer  :: nat
    real(DP) :: etot
    real(DP) :: eng_force(3,cnat)
    integer  :: ityp(cnat)
    real(DP) :: pos(3,cnat)
    real(DP) :: box(3,3)
    integer  :: if_pos(3,cnat)
    real(DP) :: displ_vec(3,cnat)
    logical  :: lconv
    ! real( c_double ), pointer :: rptr(:,:)

    nat = int( cnat )
    etot = real( cetot, DP )
    eng_force = real( ceng_force, DP )
    ityp = int( ctyp )
    pos = real( cpos, DP )
    box = real( cbox, DP )
    if_pos = int( cif_pos )

    call artn_step( nat, etot, eng_force, ityp, pos, box, if_pos, displ_vec, lconv )

    ! cdispl_vec = c_malloc( c_sizeof(0.0_c_double)*int(3*cnat,c_size_t) )
    ! call c_f_pointer( cdispl_vec, rptr, shape=[3, nat] )
    ! rptr = real( displ_vec, c_double )
    cdispl_vec=real(displ_vec, c_double)

    clconv = logical( lconv, c_bool )
  end subroutine artn_cstep


  subroutine artn_step_reset()bind(C,name="artn_step_reset")
    if( allocated(vel))deallocate(vel)
  end subroutine artn_step_reset

end module m_artn_step
