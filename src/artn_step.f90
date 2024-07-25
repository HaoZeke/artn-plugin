
module m_artn_step
  use precision, only: DP
  implicit none

  private
  public :: artn_step


  real(DP), parameter :: &
       dt_init    = 20.0_DP ,& !< @brief in units of ARTn (AU)
       alpha_init = 0.2_DP

  !! current values of fire parameters
  real(DP), save :: dt, alpha
  integer, save :: nsteppos

contains

  subroutine artn_step( nat, etot, eng_force, ityp, pos, box, if_pos, displ_vec, lconv )
    !! experimental routine to perform single step of artn research
    use m_error, only: err_write, merr
    use m_setup_artn, only: setup_artn2
    use m_artn, only: artn
    use m_move_mode, only: move_mode
    use m_fire, only: fire_init, fire_step
    use units, only: convert_time, unconvert_time, mass, convert_force, unconvert_force, unconvert_length
    use artn_params, only: istep
    implicit none
    INTEGER,            INTENT(IN)    :: nat               !  number of atoms
    REAL(DP),           INTENT(IN)    :: etot              !  total energy in current step
    REAL(DP),           INTENT(IN)    :: eng_force(3,nat)  !  force calculated by the engine
    INTEGER,            INTENT(IN)    :: ityp(nat)         !  atom types
    REAL(DP),           INTENT(IN)    :: pos(3,nat)        !  atomic positions (needed for output only)
    REAL(DP),           INTENT(IN)    :: box(3,3)          !  lattice parameters in alat units
    INTEGER,            INTENT(IN)    :: if_pos(3,nat)     !  coordinates fixed by engine
    REAL(DP),           INTENT(OUT)   :: displ_vec(3,nat)  !  atomic positions (needed for output only)
    LOGICAL,            INTENT(OUT)   :: lconv             !  flag for controlling convergence
    !
    integer :: order(nat)
    integer :: i, disp_code
    real(DP) :: force(3,nat), vel(3,nat)
    logical :: lerror
    real(DP) :: dt_init_a, dt_a
    integer :: typ(nat)
    real(DP) :: tau(3,nat)
    real(DP) :: aetot
    real(DP) :: fire_dt
    !
    integer :: ierr

    if( istep == 0 ) then
       !! initialize current values for dt and alpha
       !! dt is now in units of ARTn (AU)
       dt = dt_init
       alpha = alpha_init
       mass = 1.0_DP
       !! initialize fire
       ierr = fire_init()
    end if


    block
      integer :: i, u0
      if( istep == 0 ) then
         open(newunit=u0, file="xout", status="replace" )
      else
         open(newunit=u0, file="xout", status="old", position="append" )
      end if
      write(u0, *) nat
      write(u0,*) 'Lattice="',box,'" properties=id:I:1:species:I:1:pos:R:3 istep=',istep
      do i = 1, nat
         write(u0,*) i, ityp(i), pos(:,i)
      end do
      close(u0)
    end block

    call setup_artn2( nat, lerror )
    if( lerror ) then
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if


    force = eng_force
    do i = 1, nat
       order(i) = i
    end do
    aetot = etot
    typ = ityp
    tau = pos


    !! take force in engine units, return displ_vec (not always) in bohr
    call artn( nat, aetot, force, typ, tau, order, box, if_pos, disp_code, displ_vec, lconv )
    write(*,*) "first 3 displ_vec after artn", norm2(displ_vec)
    write(*,*) displ_vec(:,1)
    write(*,*) displ_vec(:,2)
    write(*,*) displ_vec(:,3)

    !! now: displ_vec = dr (bohr)


    !! convert dt from au into engine units
    dt_a = unconvert_time(dt)
    dt_init_a = unconvert_time(dt_init)


    write(*,*) "alpha entring move_mode",alpha
    write(*,*) "dt entering move_mode",dt_a
    write(*,*) "dt_init_a",dt_init_a
    write(*,*) "norm2(vel) entering move_mode",norm2(vel)
    !! take displ_vec from above, return force, fire params in engine units
    call move_mode( nat, order, force, vel, aetot, nsteppos, &
         dt_a, alpha, alpha_init, dt_init_a, disp_code, displ_vec )

    write(*,*) "alpha exiting move_mode",alpha
    write(*,*) "dt exiting move_mode",dt_a
    write(*,*) "first 3 force after move_mode in eng"
    write(*,*) force(:,1)
    write(*,*) force(:,2)
    write(*,*) force(:,3)
    !! convert force from engine units into ry/bohr
    ! force = convert_force(force)

    write(*,*) "first 3 force after move_mode in au"
    write(*,*) force(:,1)
    write(*,*) force(:,2)
    write(*,*) force(:,3)

    !! now :: force = displ_vec * mass / dt^2  (in artn units)

    !! get dt in ARTn units
    dt = convert_time(dt_a)

    ! dt = convert_time(dt)
    !! dt in units of caller
    ! fire_dt = unconvert_time(dt)
    ! fire_dt = dt
    fire_dt = dt_a
    ! fire_dt = convert_time(dt)
    ! fire_dt = 1.0
    
    ! convert force to ARTn units 
    force = convert_force( force ) 

    write(*,*) "fire dt",fire_dt
    !! take force from above, return displ_vec always
    call fire_step( nat, force, nsteppos, vel, fire_dt, alpha, displ_vec )
    !! displ_vec returned seems to be in bohr.
    ! displ_vec = unconvert_length(displ_vec)
    ! unconvert force
    force = unconvert_force( force ) 
    write(*,*) "first 3 displ_vec", norm2(displ_vec)
    write(*,*) displ_vec(:,1)
    write(*,*) displ_vec(:,2)
    write(*,*) displ_vec(:,3)
    write(*,*) "exit artn_step"

    !!dr = dt^2 * F/m


    !! store dt in units of me
    ! dt = convert_time(fire_dt)
    ! dt = fire_dt
    write(*,*) "dt end",dt
  end subroutine artn_step
  !! C wrapper
  subroutine artn_cstep( cnat, cetot, ceng_force, ctyp, cpos, cbox, cif_pos, cdispl_vec, clconv )&
       bind(C, name="artn_step" )
    use, intrinsic :: iso_c_binding
    use precision, only: DP
    use m_tools, only: c_malloc
    implicit none
    integer( c_int ), intent(in), value :: cnat
    real( c_double ), intent(in), value :: cetot
    real( c_double ), intent(in) :: ceng_force(3,cnat)
    integer( c_int ), intent(in) :: ctyp(cnat)
    real( c_double ), intent(in) :: cpos(3,cnat)
    real( c_double ), intent(in) :: cbox(3,3)
    integer( c_int ), intent(in) :: cif_pos(3,cnat)
    type( c_ptr ) :: cdispl_vec
    ! real( c_double ), intent(out) :: cdispl_vec(3,cnat)
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
    real( c_double ), pointer :: rptr(:,:)

    nat = int( cnat )
    etot = real( cetot, DP )
    eng_force = real( ceng_force, DP )
    ityp = int( ctyp )
    pos = real( cpos, DP )
    box = real( cbox, DP )
    if_pos = int( cif_pos )

    call artn_step( nat, etot, eng_force, ityp, pos, box, if_pos, displ_vec, lconv )

    cdispl_vec = c_malloc( c_sizeof(0.0_c_double)*int(3*cnat,c_size_t) )
    call c_f_pointer( cdispl_vec, rptr, shape=[3, nat] )
    rptr = real( displ_vec, c_double )

    clconv = logical( lconv, c_bool )
  end subroutine artn_cstep

end module m_artn_step
