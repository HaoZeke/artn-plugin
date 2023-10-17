! module siesta_fire_p
!   !! this is just for checking with internal fire
!   use iso_c_binding, only: c_double
!   use units, only: DP

!   real( DP ), save :: dt_init
!   real( DP ), save :: alpha_init
!   character(len=3), allocatable :: atm(:)
!   integer, save :: istep = 0
! end module siesta_fire_p


subroutine artn_siesta2( force_c, etot_c, nat, ityp, atm, tau_c, order, at_c, if_pos, vel_c, &
                         dt_curr_c, alpha_curr_c, dt_init_c, alpha_init_c, nsteppos, lrelax, lconv )
  use units, only: DP
  use iso_c_binding, only: c_double
  use artn_params, only: MOVE
  ! use siesta_fire_p, only: istep
  implicit none
  !! input params in c precision
  real( c_double ), dimension(3, nat), intent(inout) :: force_c
  real( c_double ),                    intent(inout) :: etot_c
  integer,                             intent(in)    :: nat
  integer, dimension(nat),             intent(in)    :: ityp
  character(len=3),                    intent(in)    :: atm(*)
  real( c_double ), dimension(3,nat),  intent(inout) :: tau_c
  integer, dimension(nat),             intent(in)    :: order
  real( c_double ), dimension(3,3),    intent(in)    :: at_c
  integer, dimension(3,nat),           intent(in)    :: if_pos
  real( c_double ), dimension(3,nat),  intent(inout) :: vel_c
  real( c_double ),                    intent(inout) :: dt_curr_c
  real( c_double ),                    intent(inout) :: alpha_curr_c
  real( c_double ),                    intent(inout) :: dt_init_c
  real( c_double ),                    intent(inout) :: alpha_init_c
  integer,                             intent(inout) :: nsteppos
  logical,                             intent(out)   :: lrelax
  logical,                             intent(out)   :: lconv

  !! local vars in local precision
  real(DP), dimension(3,nat) :: displ_vec
  integer :: disp
  real(DP), dimension(3,nat) :: force, tau, vel
  real(DP), dimension(3,3) :: at
  real(DP) :: etot, dt_init, dt_curr, alpha_curr, alpha_init
  ! logical :: lconv

  integer :: i
  ! real(DP) :: rmax

  !! interface to libartn.a
  interface
    SUBROUTINE artn( force, etot, nat, ityp, atm, tau, order, at, if_pos, disp, displ_vec, lconv )
      USE units, ONLY: DP
      IMPLICIT NONE
      REAL(DP), INTENT(IN)         :: force(3,nat)     ! force calculated by the engine
      REAL(DP), INTENT(IN)         :: etot             ! total energy in current step
      INTEGER,  INTENT(IN), value  :: nat              ! number of atoms
      INTEGER,  INTENT(IN)         :: ityp(nat)        ! atom types
      CHARACTER(LEN=3), INTENT(IN) :: atm(*)           ! name of atom corresponding to ityp
      REAL(DP), INTENT(INOUT)      :: tau(3,nat)       ! atomic positions (needed for output only)
      INTEGER,  INTENT(IN)         :: order(nat)       ! Engine order of atoms
      REAL(DP), INTENT(IN)         :: at(3,3)          ! lattice parameters in alat units
      INTEGER,  INTENT(IN)         :: if_pos(3,nat)    ! coordinates fixed by engine
      INTEGER,  INTENT(OUT)        :: disp             ! integer of next step stage
      REAL(DP), INTENT(OUT)        :: displ_vec(3,nat) ! displacement vector communicated to move mode
      LOGICAL,  INTENT(OUT)        :: lconv
    END SUBROUTINE artn
    SUBROUTINE move_mode(nat, order, force, vel, etot, nsteppos, dt_curr, alpha, &
         alpha_init, dt_init, disp, displ_vec )
      use units, only : DP
      IMPLICIT NONE
      INTEGER, INTENT(IN), value                :: nat
      INTEGER, INTENT(IN)                       :: order(nat)
      REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: force
      REAL(DP), DIMENSION(3,nat), INTENT(INOUT) :: vel
      REAL(DP), INTENT(INOUT)                   :: etot
      INTEGER,  INTENT(INOUT)                   :: nsteppos
      REAL(DP), INTENT(INOUT)                   :: dt_curr
      REAL(DP), INTENT(INOUT)                   :: alpha
      REAL(DP), INTENT(IN)                      :: alpha_init
      REAL(DP), INTENT(IN)                      :: dt_init
      INTEGER, INTENT(IN)                       :: disp
      REAL(DP), DIMENSION(3,nat), INTENT(IN)    :: displ_vec
    END SUBROUTINE move_mode
 end interface

 ! istep = istep + 1

 !! convert from c precision input to dp
 force = real( force_c, DP )
 tau = real( tau_c, DP )
 vel = real( vel_c, DP )
 at = real( at_c, DP )
 etot = real( etot_c, DP )
 dt_curr = real( dt_curr_c, DP )
 alpha_curr = real( alpha_curr_c, DP )
 dt_init = real( dt_init_c, DP )
 alpha_init = real( alpha_init_c, DP )


#ifdef DEBUG
 block
   use artn_debug
   integer :: ierr
   character(len=256) :: err
 end block
#endif




 write(*,*) "artn siesta2 got:"
 write(*,*) nat
 write(*,*) at
 do i = 1, nat
    write(*,'(i3,3f12.6)') ityp(i), tau(:,i)
 end do

 call artn( force, etot, nat, ityp, atm, tau, order, at, if_pos, disp, displ_vec, lconv )

 write(*,*) "artn siesta2 has displ_vec:",norm2(displ_vec)
 do i = 1, nat
    write(*,*) i, displ_vec(:,i)
 end do

 write(*,*) "artn siesta send to move mode next params:"
 write(*,*) "dt curr", dt_curr
 write(*,*) "alpha_curr",alpha_curr
 write(*,*) "nsteppos", nsteppos

 call move_mode( nat, order, force, vel, etot, &
                 nsteppos, dt_curr, alpha_curr, alpha_init, dt_init, disp, displ_vec )

 write(*,*) "artn siesta move mode generated next params:"
 write(*,*) "dt curr", dt_curr
 write(*,*) "alpha_curr",alpha_curr
 write(*,*) "nsteppos", nsteppos
 write(*,*) "vel, force"
 do i = 1, nat
    write(*,'(3f10.6,4x,3f10.6)') vel(:,i), force(:,i)
 end do
 write(*,*) "tau"
 do i = 1, nat
    write(*,*) i, tau(:,i)
 end do


 !! get some info
 ! rmax = 8.0_DP
 ! call fire2_integration( istep, nat, force, vel, dt_curr, alpha_curr, nsteppos, rmax )

 !! send signal when relaxing
 lrelax = .false.
 if( MOVE(disp) .eq. 'relx' ) lrelax = .true.


 !! convert back to proper precision output
 force_c = real( force, c_double )
 vel_c = real( vel, c_double )
 alpha_curr_c = real( alpha_curr, c_double )
 dt_curr_c = real( dt_curr, c_double )
 tau_c = real( tau, c_double )
 write(*,*) "alpha_curr_c",alpha_curr_c
 write(*,*) "dt_curr_c", dt_curr_c
 write(*,*) "returning from artn siesta2"
end subroutine artn_siesta2

! subroutine get_atm( nat, ityp )
!   !! we can't extract atm type strings from siesta it seems,
!   !! so just make them X01, X02, X03, X## etc, where ## is the
!   !! integer assigned to this type in siesta
!   use siesta_fire_p
!   implicit none
!   integer, intent(in) :: nat
!   integer, dimension(nat), intent(in) :: ityp

!   integer :: i, j, k, ntyp
!   integer, dimension(nat) :: pp

!   pp = ityp
!   ntyp = 0
!   k = 0
!   do i = 1, nat
!      if( pp(i) .eq. 0) cycle
!      k = pp(i)
!      ntyp = ntyp + 1
!      !! loop over all, zero all equal to k
!      do j = 1, nat
!         if( pp(j) .eq. k) pp(j) = 0
!      end do
!   end do

!   allocate( atm(1:ntyp) )
!   do i = 1, ntyp
!      write(atm(i), '(a1,i2.2)' ) "X",i
!   end do

! end subroutine get_atm






!! used only for local debug and info
! subroutine fire2_integration( istep, n, f, v, dt, alpha, delaystep, rmax )

!   !> @brief
!   !!    Fire intgration following FIRE in lammps

!   use units, only : DP
!   ! use artn_params, only : u => iunartout, filout
!   implicit none

!   integer, intent( IN ) :: istep, n, delaystep
!   REAL(DP), intent( in ) :: f(3,n), v(3,n), dt, alpha
!   real(DP), intent( out ) :: rmax

!   integer :: last_neg, step_start, nmov, i, u

!   real(DP) :: vdotv, vdotf, fdotf, a1, a2, dtv, dtf, dtfm, ftm2v, mass, &
!               dmax, vmax, dtgrow, dtshrink, dtmin, dtmax,  &
!               alfa, alpha0, alpha_shrink
!   real(DP) :: rsum
!   real(DP) :: x(3,n), vloc(3,n), dr2(n)
!   logical :: flagv0, halfback

!   real(DP), external :: ddot, dsum

!   !! -- Parameters
!   halfback = .true.
!   ftm2v = 9648.53_DP
!   mass = 1.0_DP
!   dmax = 0.5_DP
!   dtgrow = 1.1
!   dtshrink = 0.5
!   dtmin = 6.0e-6
!   dtmax = 0.006
!   alpha0 = 0.0
!   alpha_shrink = 0.9
!   !! --------------------


!   if( istep == 1 )step_start = istep
!   vdotv = ddot( 3*n, v, 1, v, 1 )
!   vdotf = ddot( 3*n, v, 1, f, 1 )
!   fdotf = ddot( 3*n, f, 1, f, 1 )

!   dtv = dt

!   flagv0 = .false.
!   if( vdotf > 0.0_DP )then
!     a1 = 1. - alpha
!     if( fdotf < 1.0e-8 )then; a2 = 0.0
!     else; a2 = alpha * sqrt( vdotv / fdotf )
!     endif
!     !! delaystep
!     if( istep - last_neg > delaystep )then
!       dtv = MIN(dt*dtgrow, dtmax)
!       alfa = alpha * alpha_shrink
!     endif
!     call dcopy( 3*n, v, 1, vloc, 1 )
!   else
!     last_neg = istep
!     !! delaystep
!     if( .not.(istep - step_start < delaystep) )then
!       alfa = alpha0
!       if( dt*dtshrink >= dtmin )dtv = dt*dtshrink
!     endif
!     if( halfback ) x = x - 0.5 * dtv * v
!     flagv0 = .true.
!     vloc = 0.0
!   endif

!   !! now we work with vloc

!   dtfm = dtv * ftm2v / mass
!   if( flagv0 ) vloc = f * dtfm

!   ! ...Rescale dtv
!   !dtv = dt
!   vmax = MAXVAL( ABS(vloc) )
!   if( dtv*vmax > dmax )dtv = dmax / vmax

!   if( flagv0 )vloc = 0.0_DP


!   ! ...Euler integration

!   dtf = dtv * ftm2v
!   dtfm = dtf / mass
!   vloc = vloc + dtfm * f
!   if( vdotf > 0.0_DP )vloc = a1 * vloc + a2 * f
!   x = x + dtv * vloc


!   ! ...Analysis

!   !write(*,'("******* FIRE INTEGRATION ANALYSIS::",x,i0)') istep
!   !write(*,'("* MAX displacment",x,f10.4)') MAXVAL(ABS(x))
!   !write(*,'("* sum displcmeemt",x,f10.4)') sqrt( dsum(3*n,x) )

!   rmax = 0.0
!   dr2 = 0.0
!   do i = 1,n
!      dr2(i) = dot_product( x(:,i), x(:,i))
!      rmax = MAX(rmax, dr2(i))
!   enddo
!   nmov = 0
!   rsum = 0.0
!   do i = 1,n
!      if( dr2(i) > rmax*(1.-0.05)**2 )then
!        nmov = nmov + 1
!        rsum = rsum + sqrt(dr2(i))
!      endif
!   enddo
!   rmax = sqrt( rmax )

!   OPEN ( newunit=u, FILE = "report.FIRE2", FORM = 'formatted', STATUS = 'unknown', POSITION = 'append' )

!   write(u,'(5x,"|> ",i3," FIRE integration: rmax",x,g10.4,x,"| sum_d",x,g10.4,x,"| ",i0,x,g10.4)') &
!      istep,  rmax, sqrt( dsum(3*n,x) ), nmov, rsum

!   close( unit=u, STATUS='KEEP' )


! end subroutine fire2_integration




