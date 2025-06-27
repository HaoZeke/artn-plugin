submodule( m_option ) restart_r
  use artn_params
  use m_artn_report, only: read_struct
  implicit none

contains

  !> @details
  !! write a file with artn parameters and data needed to restart a calculation
  module subroutine write_restart()
    use m_error
    use artn_params, only: restartfname
    use artn_params, only: linit, lperp, leigen, llanczos, lbasin, lpush_over, lrelax, in_lanczos_at_min
    use artn_params, only: iartn, istep, iinit, ieigen, iperp, irelax, ismooth, inewchance, iover
    use artn_params, only: nlanc, ifound, isearch, ifails, nperp_step, nmin, nsaddle
    use artn_params, only: fpush_factor, artn_resume

    use d_artn_data, only: natoms, lat
    use d_artn_data, only: typ_init, tau_init, push_init, etot_init, delr_init
    use d_artn_data, only: typ_step, tau_step, force_step, eigen_step, eigval_step, delr_step, etot_step

    implicit none
    integer :: u0, ios
    character(len=128) :: msg

    namelist/params/ &  !! values for artn_params
         !! flags
         linit, lperp, leigen, llanczos, lbasin, lpush_over, lrelax, in_lanczos_at_min, &

         !! counters
         iartn, istep, iinit, ieigen, iperp, irelax, ismooth, inewchance, iover, &
         nlanc, ifound, isearch, ifails, nperp_step, nmin, nsaddle, fpush_factor, artn_resume

    namelist/data/ &   !! values from d_artn_data
         natoms, lat, &

         !! init state data
         typ_init, tau_init, push_init, etot_init, delr_init, &

         !! current step data
         typ_step, tau_step, force_step, eigen_step, eigval_step, delr_step, etot_step


    if( istep == 0 ) return

    open(newunit=u0, file=trim(restartfname), status="replace", action="write", iostat=ios, iomsg=msg)
    if( ios /= 0 ) then
       write(*,*) trim(msg)
       call merr(__FILE__,__LINE__,kill=.true.)
    end if

    !! write params
    write(u0,nml=params)

    !! write data
    write(u0,nml=data)

    close( u0, status="keep")
  end subroutine write_restart



  !> @details
  !! read variables from a restart file, and overwrite the data to continue computation
  !! from the restart point.
  module subroutine read_restart( lerror )
    !! set push_initial_vector = push_init
    use m_error
    use artn_params, only: restartfname
    use artn_params, only: linit, lperp, leigen, llanczos, lbasin, lpush_over, lrelax, in_lanczos_at_min
    use artn_params, only: iartn, istep, iinit, ieigen, iperp, irelax, ismooth, inewchance, iover
    use artn_params, only: nlanc, ifound, isearch, ifails, nperp_step, nmin, nsaddle
    use artn_params, only: fpush_factor, artn_resume
    use artn_params, only: push_initial_vector

    use d_artn_data, only: natoms, lat
    use d_artn_data, only: typ_init, tau_init, push_init, etot_init, delr_init
    use d_artn_data, only: typ_step, tau_step, force_step, eigen_step, eigval_step, delr_step, etot_step
    implicit none

    logical, intent(out) :: lerror
    integer :: u0, ios
    character(len=128) :: msg

    namelist/params/ &  !! values for artn_params
         !! flags
         linit, lperp, leigen, llanczos, lbasin, lpush_over, lrelax, in_lanczos_at_min, &

         !! counters
         iartn, istep, iinit, ieigen, iperp, irelax, ismooth, inewchance, iover, &
         nlanc, ifound, isearch, ifails, nperp_step, nmin, nsaddle, fpush_factor, artn_resume

    namelist/data/ &   !! values from d_artn_data
         natoms, lat, &

         !! init state data
         typ_init, tau_init, push_init, etot_init, delr_init, &

         !! current step data
         typ_step, tau_step, force_step, eigen_step, eigval_step, delr_step, etot_step


    lerror = .false.

    open(newunit=u0, file=trim(restartfname), status="old", action="read", iostat=ios, iomsg=msg)
    if( ios /= 0 ) then
       write(*,*) trim(msg)
       lerror = .true.
       call err_set(ERR_FILE,__FILE__,__LINE__,msg=trim(msg))
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    !! read params
    read(u0,nml=params)

    !! read data
    read(u0,nml=data)

    if( allocated(push_initial_vector))deallocate(push_initial_vector)
    allocate( push_initial_vector, source=push_init)

    close( u0, status="keep")

  end subroutine read_restart


end submodule restart_r
