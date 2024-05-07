! module siesta_fire_p
!   !! this is just for checking with internal fire
!   use iso_c_binding, only: c_double
!   use units, only: DP

!   real( DP ), save :: dt_init
!   real( DP ), save :: alpha_init
!   character(len=3), allocatable :: atm(:)
!   integer, save :: istep = 0
! end module siesta_fire_p


subroutine artn_siesta2( nat, force_c, etot_c, ityp, atm, tau_c, order, at_c, if_pos, vel_c, &
                         dt_curr_c, alpha_curr_c, dt_init_c, alpha_init_c, nsteppos, lrelax, lconv )
  use, intrinsic :: iso_c_binding, only: c_double
  use precision, only: DP
  use artn_params, only: STR_MOVE
  use m_artn, only: artn
  use m_move_mode, only: move_mode
  use m_setup_artn, only: setup_artn2
  use m_error, only: err_write, merr
  ! use siesta_fire_p, only: istep
  implicit none
  !! input params in c precision
  integer,                             intent(in)    :: nat
  real( c_double ), dimension(3, nat), intent(inout) :: force_c
  real( c_double ),                    intent(inout) :: etot_c
  integer, dimension(nat),             intent(inout) :: ityp
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
  integer :: disp_code
  real(DP), dimension(3,nat) :: force, tau, vel
  real(DP), dimension(3,3) :: at
  real(DP) :: etot, dt_init, dt_curr, alpha_curr, alpha_init
  logical :: lerror

  !integer :: i
  ! real(DP) :: rmax



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



  call setup_artn2( nat, lerror )
  if( lerror ) then
     call err_write(__FILE__,__LINE__)
     call merr(__FILE__,__LINE__,kill=.true.)
     return
  end if

  ! write(*,*) "artn siesta2 got:"
  ! write(*,*) nat
  ! write(*,*) at
  ! do i = 1, nat
  !    write(*,'(i3,3f12.6)') ityp(i), tau(:,i)
  ! end do

  ! call artn( force, etot, nat, ityp, atm, tau, order, at, if_pos, disp, displ_vec, lconv )
  call artn( nat, etot, force, ityp, tau, order, at, if_pos, disp_code, displ_vec, lconv )

  ! write(*,*) "artn siesta2 has displ_vec:",norm2(displ_vec)
  ! do i = 1, nat
  !    write(*,*) i, displ_vec(:,i)
  ! end do

  write(*,*) "DISP CODE AFTER ARTN:",STR_MOVE(disp_code)
  block
    use artn_params, only: nperp_step, nperp_limitation, nperp
    write(*,*) "nperp_step:",nperp_step, nperp
    write(*,*) allocated(nperp_limitation)
    if( allocated(nperp_limitation))write(*,'(*(i0,1x))')nperp_limitation
  end block

  ! write(*,*) "artn siesta send to move mode next params:"
  ! write(*,*) "dt curr", dt_curr
  ! write(*,*) "alpha_curr",alpha_curr
  ! write(*,*) "nsteppos", nsteppos

  call move_mode( nat, order, force, vel, etot, &
       nsteppos, dt_curr, alpha_curr, alpha_init, dt_init, disp_code, displ_vec )

  ! write(*,*) "artn siesta move mode generated next params:"
  ! write(*,*) "dt curr", dt_curr
  ! write(*,*) "alpha_curr",alpha_curr
  ! write(*,*) "nsteppos", nsteppos
  ! write(*,*) "vel, force"
  ! do i = 1, nat
  !    write(*,'(3f10.6,4x,3f10.6)') vel(:,i), force(:,i)
  ! end do
  ! write(*,*) "tau"
  ! do i = 1, nat
  !    write(*,*) i, tau(:,i)
  ! end do


  !! get some info
  ! rmax = 8.0_DP
  ! call fire2_integration( istep, nat, force, vel, dt_curr, alpha_curr, nsteppos, rmax )

  !! send signal when relaxing
  lrelax = .false.
  if( STR_MOVE(disp_code) .eq. 'relx' ) lrelax = .true.


  !! convert back to proper precision for output
  force_c = real( force, c_double )
  vel_c = real( vel, c_double )
  alpha_curr_c = real( alpha_curr, c_double )
  dt_curr_c = real( dt_curr, c_double )
  tau_c = real( tau, c_double )
  ! write(*,*) "alpha_curr_c",alpha_curr_c
  ! write(*,*) "dt_curr_c", dt_curr_c
  ! write(*,*) "returning from artn siesta2"

end subroutine artn_siesta2




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




