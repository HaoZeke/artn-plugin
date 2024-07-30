submodule( artn_params )serialize_routines
  use m_error
  use m_artn_data
  implicit none

contains

  module subroutine dump_input( fname )
    use units, only: defined_var, unconvert_param
    implicit none
    character(*), intent(in) :: fname

    integer :: ios, u0, n
    character(len=128) :: msg
    character(len=1024) :: line
    integer :: dt(8)
    namelist/pac/push_add_const

    open( newunit=u0, file=fname, status="replace", action="write", iostat=ios, iomsg=msg )
    if( ios /= 0 ) then
       call err_set(ERR_FILE, __FILE__,__LINE__,msg=trim(msg))
       call err_write(__FILE__,__LINE__)
       return
    end if


    !! get date and time
    call date_and_time( values = dt )
    write(u0, *) "!! This input file was written by the function dump_input(),"
    write(u0, "(1x,a,1x,i0,a1,i0,a1,i0,1x,a,1x,i0.2,a1,i0.2,a1,i0.2//)") "!! launched on:", &
         dt(3),".",dt(2),".",dt(1),"at:",dt(5),":",dt(6),":",dt(7)


    !! write the namelist for input manually, since there could be unallocated things ...
    !! begin writing
    write(u0, *) "&ARTN_PARAMETERS"

    !! write the defined values

    !! first write units
    if( defined_var(engine_units) ) write(u0, 223) "engine_units = ",trim(engine_units)

    !! integer
    write(u0, 221) "verbose          =", verbose
    write(u0, 221) "zseed            =", zseed
    write(u0, 221) "nperp            =", nperp
    write(u0, 221) "nevalf_max       =", nevalf_max
    write(u0, 221) "ninit            =", ninit
    write(u0, 221) "neigen           =", neigen
    write(u0, 221) "lanczos_max_size =", lanczos_max_size
    write(u0, 221) "lanczos_min_size =", lanczos_min_size
    write(u0, 221) "nsmooth          =", nsmooth
    write(u0, 221) "nnewchance       =", nnewchance
    write(u0, 221) "nrelax_print     =", nrelax_print
    write(u0, 221) "restart_freq     =", restart_freq

    !! real
    write(u0, 222) "push_dist_thr    =",push_dist_thr
    write(u0, 222) "delr_thr         =",delr_thr
    write(u0, 222) "push_over        =",push_over
    write(u0, 222) "alpha_mix_cr     =",alpha_mix_cr

    !! real, initialised to NAN
    if( defined_var(forc_thr                )) write(u0, 222) &
         "forc_thr          =", unconvert_param( "forc_thr", forc_thr )

    if( defined_var(eigval_thr              )) write(u0, 222) &
         "eigval_thr        =", unconvert_param( "eigval_thr", eigval_thr )

    if( defined_var(etot_diff_limit         )) write(u0, 222) &
         "etot_diff_limit   =", unconvert_param( "etot_diff_limit", etot_diff_limit )

    if( defined_var(push_step_size          )) write(u0, 222) &
         "push_step_size    =", unconvert_param( "push_step_size", push_step_size )

    if( defined_var(push_step_size_per_atom )) write(u0, 222) &
         "push_step_size_per_atom=", unconvert_param( "push_step_size_per_atom", push_step_size_per_atom )

    if( defined_var(eigen_step_size         )) write(u0, 222) &
         "eigen_step_size   =", unconvert_param( "eigen_step_size", eigen_step_size )

    if( defined_var(current_step_size       )) write(u0, 222) &
         "current_step_size =", unconvert_param( "current_step_size", current_step_size )

    if( defined_var(lanczos_disp            )) write(u0, 222) &
         "lanczos_disp      =", unconvert_param( "lanczos_disp", lanczos_disp )

    !! str initialised to NAN
    if( defined_var( push_mode      )) write(u0,223) "push_mode      =", trim(push_mode)
    if( defined_var( push_guess     )) write(u0,223) "push_guess     =", trim(push_guess)
    if( defined_var( eigenvec_guess )) write(u0,223) "eigenvec_guess =", trim(eigenvec_guess)

    !! str
    !! filin is this file, no need to write
    if( defined_var( filout           )) write(u0,223) "filout           =", trim(filout)
    if( defined_var( initpfname       )) write(u0,223) "initpfname       =", trim(initpfname)
    if( defined_var( eigenfname       )) write(u0,223) "eigenfname       =", trim(eigenfname)
    if( defined_var( restartfname     )) write(u0,223) "restartfname     =", trim(restartfname)
    if( defined_var( prefix_min       )) write(u0,223) "prefix_min       =", trim(prefix_min)
    if( defined_var( prefix_sad       )) write(u0,223) "prefix_sad       =", trim(prefix_sad)
    if( defined_var( struc_format_out )) write(u0,223) "struc_format_out =", trim(struc_format_out)

    !! logicals
    write(u0,224) "lmove_nextmin         =", lmove_nextmin
    write(u0,224) "lnperp_limitation     =", lnperp_limitation
    write(u0,224) "lrestart              =", lrestart
    write(u0,224) "lpush_final           =", lpush_final
    write(u0,224) "lanczos_always_random =", lanczos_always_random
    write(u0,224) "lanczos_at_min        =", lanczos_at_min
    write(u0,224) "lserialize_output     =", lserialize_output

    !! allocatables
    if( allocated( converge_property )) write(u0,223) "converge_property =",converge_property
    if( allocated( nperp_limitation )) write(u0,221) "nperp_limitation =", nperp_limitation
    if( allocated( push_ids         )) write(u0,221) "push_ids         =", push_ids
    !! push_add_const can be long...
    if( allocated( push_add_const   )) then
       !! nml format is more compact
       write(line,nml=pac)
       !! cut the &nml, and final /
       line = trim(adjustl(line(5:)))
       n = len_trim(line)
       line = trim(adjustl(line(1:n-4)))
       write(u0, "(2x,a)") trim(line)
    end if

221 format( 2x,a,1x,*(i0,:,",",1x))   !! integer
222 format( 2x,a,1x,*(g0.6,:,",",1x)) !! real
223 format( 2x,a,1x,"'",a,"'")                !! string
224 format( 2x,a,1x,l4)               !! bool

    !! finish writing
    write(u0,*) "/ "
    write(u0,*) " "
    close(u0, status="keep")
  end subroutine dump_input
  !! C-wrapper
  module subroutine cdump_input( cname )bind(C,name="dump_input")
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    call dump_input( fname )
    deallocate( fname )
  end subroutine cdump_input


  !> @details dump the generated data from m_artn_data
  module subroutine dump_data( fname )
    character(*), intent(in) :: fname
    integer :: u0, ios
    character(len=128) :: msg

    namelist/info/engine_units, natoms, lat, has_error, nevalf, has_sad, has_min1, has_min2
    namelist/struc_init/typ_init, tau_init, push_init, etot_init, delr_init
    namelist/struc_step/typ_step, tau_step, force_step, eigen_step, etot_step, delr_step, eigval_step
    namelist/struc_sad/typ_sad, tau_sad, eigen_sad, nevalf_sad, etot_sad, delr_sad, eigval_sad
    namelist/struc_min1/etot_min1, delr_min1, eigval_min1, nevalf_min1, typ_min1, tau_min1
    namelist/struc_min2/etot_min2, delr_min2, eigval_min2, nevalf_min2, typ_min2, tau_min2

    open(newunit=u0, file=fname, iostat=ios, iomsg=msg, action="write", status="replace")
    if( ios /= 0 ) then
       write(*,*) "ERROR opening file: ",fname
       write(*,*) trim(msg)
       call merr(__FILE__,__LINE__, kill=.true.)
    end if

    !! write info
    write(u0, nml=info)

    !! write init state
    write(u0, nml=struc_init)

    !! write current step
    write(u0, nml=struc_step)

    !! if has_sad, write sad
    if( has_sad ) write(u0, nml=struc_sad )

    !! write the minima
    if( has_min1 ) write(u0, nml=struc_min1)
    if( has_min2 ) write(u0, nml=struc_min2)
    close(u0, status="keep")

  end subroutine dump_data
  !! C wrapper
  module subroutine cdump_data( cname )bind(C, name="dump_data" )
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    call dump_data( fname )
    deallocate( fname )
  end subroutine cdump_data



  !! return ierr if file does not exist
  module function read_datadump( fname )result(ierr)
    use units, only: make_units
    implicit none
    character(*), intent(in) :: fname
    integer :: ierr
    integer :: ios, u0
    character(len=128) :: msg
    logical :: lerr
    namelist/info/engine_units, natoms, lat, has_error, nevalf, has_sad, has_min1, has_min2
    namelist/struc_init/typ_init, tau_init, push_init, etot_init, delr_init
    namelist/struc_step/typ_step, tau_step, force_step, eigen_step, etot_step, delr_step, eigval_step
    namelist/struc_sad/typ_sad, tau_sad, eigen_sad, nevalf_sad, etot_sad, delr_sad, eigval_sad
    namelist/struc_min1/etot_min1, delr_min1, eigval_min1, nevalf_min1, typ_min1, tau_min1
    namelist/struc_min2/etot_min2, delr_min2, eigval_min2, nevalf_min2, typ_min2, tau_min2

    open( newunit=u0, file=fname,status="old",iostat=ios,iomsg=msg,action="read")
    if( ios /= 0 ) then
       ierr = ERR_FILE
       write(*,*) "ERROR opening file: ",fname
       write(*,*) trim(msg)
       call err_set( ERR_FILE, __FILE__,__LINE__,msg=trim(msg))
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    !! read info
    read(u0, nml=info, iostat=ios, iomsg=msg)
    if( ios /= 0 ) then
       ierr = ERR_OTHER
       write(*,*) trim(msg)
       call err_set(ierr, __FILE__,__LINE__,msg="error reading nml=info: "//trim(msg))
       return
    end if
    if( natoms < 0 ) then
       ierr = ERR_OTHER
       call err_set(ierr, __FILE__,__LINE__,msg="natoms has negative value. No data contained in dump?")
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if

    !! make units
    call make_units( engine_units, lerr )
    if( lerr ) then
       ierr = ERR_UNITS
       call err_set(ierr, __FILE__,__LINE__,msg="error in make_units!")
       call merr(__FILE__, __LINE__,kill=.true.)
       return
    end if


    !! allocate init state
    allocate( typ_init(1:natoms) )
    allocate( tau_init(1:3,1:natoms) )
    allocate( push_init( 1:3, 1:natoms) )
    !! read init state
    read(u0, nml=struc_init, iostat=ios, iomsg=msg )
    if( ios /= 0) then
       ierr = ERR_OTHER
       write(*,*) trim(msg)
       call err_set(ierr, __FILE__, __LINE__, msg="error reading nml=struc_init: "//trim(msg))
       return
    end if


    !! allocate current step
    allocate( typ_step(1:natoms))
    allocate( tau_step(1:3, 1:natoms))
    allocate( force_step(1:3,1:natoms))
    allocate( eigen_step(1:3,1:natoms))
    !! read step data
    read( u0, nml=struc_step, iostat=ios, iomsg=msg)
    if( ios /= 0) then
       ierr = ERR_OTHER
       write(*,*) trim(msg)
       call err_set(ierr, __FILE__, __LINE__, msg="error reading nml=struc_step: "//trim(msg))
       return
    end if

    !! allocate saddle
    if( has_sad ) then
       allocate( typ_sad(1:natoms))
       allocate(tau_sad(1:3,1:natoms))
       allocate(eigen_sad(1:3,1:natoms))
       !! read
       read( u0, nml=struc_sad, iostat=ios, iomsg=msg)
       if( ios /= 0) then
          ierr = ERR_OTHER
          write(*,*) trim(msg)
          call err_set(ierr, __FILE__, __LINE__, msg="error reading nml=struc_sad: "//trim(msg))
          return
       end if
    end if

    !! allocate min1
    if( has_min1 ) then
       allocate( typ_min1(1:natoms))
       allocate( tau_min1(1:3,1:natoms))
       !! read
       read( u0, nml=struc_min1, iostat=ios, iomsg=msg)
       if( ios /= 0) then
          ierr = ERR_OTHER
          write(*,*) trim(msg)
          call err_set(ierr, __FILE__, __LINE__, msg="error reading nml=struc_min1: "//trim(msg))
          return
       end if
    end if

    !! allocate min1
    if( has_min2 ) then
       allocate( typ_min2(1:natoms))
       allocate( tau_min2(1:3,1:natoms))
       !! read
       read( u0, nml=struc_min2, iostat=ios, iomsg=msg)
       if( ios /= 0) then
          ierr = ERR_OTHER
          write(*,*) trim(msg)
          call err_set(ierr, __FILE__, __LINE__, msg="error reading nml=struc_min2: "//trim(msg))
          return
       end if
    end if

    close(u0, status="keep")

  end function read_datadump
  !! C- wrapper
  module function cread_datadump( cname )result(cerr)bind(C, name="read_datadump" )
    use, intrinsic :: iso_c_binding
    use m_tools, only: c2f_char
    character(len=1, kind=c_char), intent(in) :: cname(*)
    integer(c_int) :: cerr
    character(:), allocatable :: fname
    allocate( fname, source=c2f_char(cname))
    cerr = int(read_datadump( fname ), c_int )
    deallocate( fname )
  end function cread_datadump


end submodule serialize_routines
