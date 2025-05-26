submodule( m_artn_data )save_step_data_routine
  use m_error
  implicit none
contains


  module subroutine save_step_data( which, ierr )
    use artn_params, only: istep, push_initial_vector
    use artn_params, only: delr_vec
    use artn_params, only: prefix_min, prefix_sad, struc_format_out
    use m_setup_artn, only: read_counter_file
    use units, only: allocate_var
    use m_tools, only: sum_force, compute_delr_vec
    implicit none
    character(*), intent(in) :: which
    integer, intent(out), optional :: ierr
    real(DP) :: this_delr

    if(present(ierr))ierr = 0

    !! compute delr; for which="init", delr=0.0
    if( which /= "init" ) then
       call allocate_var( 3, natoms, delr_vec, 0.0_DP)
       call compute_delr_vec( natoms, tau_step, tau_init, lat, delr_vec )
       call sum_force( delr_vec, natoms, this_delr )
    end if

    nevalf = istep

    select case( which )
    case( "init" )
       allocate( typ_init, source= typ_step )
       allocate( tau_init, source= tau_step )
       allocate( push_init, source = push_initial_vector )
       etot_init = etot_step
       delr_init = 0.0_DP

    case( "sad" )
       has_sad = .true.
       etot_sad = etot_step
       ! delr_sad = delr_step
       delr_sad = this_delr
       eigval_sad = eigval_step
       nevalf_sad = istep
       allocate( typ_sad, source = typ_step )
       allocate( tau_sad, source = tau_step )
       allocate( eigen_sad, source = eigen_step )
       fname_sad = get_latest_struc_fname( trim(prefix_sad), trim(struc_format_out) )

    case( "min1" )
       has_min1 = .true.
       etot_min1 = etot_step
       ! delr_min1 = delr_step
       delr_min1 = this_delr
       eigval_min1 = eigval_step
       nevalf_min1 = istep
       allocate( typ_min1, source = typ_step )
       allocate( tau_min1, source = tau_step )
       ! allocate( eigen_min1, source = eigen_step ) !! not computed
       fname_min1 = get_latest_struc_fname( trim(prefix_min), trim(struc_format_out) )

    case( "min2" )
       has_min2 = .true.
       etot_min2 = etot_step
       ! delr_min2 = delr_step
       delr_min2 = this_delr
       eigval_min2 = eigval_step
       nevalf_min2 = istep
       allocate( typ_min2, source = typ_step )
       allocate( tau_min2, source = tau_step )
       ! allocate( eigen_min2, source = eigen_step ) !! not computed
       fname_min2 = get_latest_struc_fname( trim(prefix_min), trim(struc_format_out) )

    case default
       if(present(ierr))ierr = ERR_OTHER
       call err_set(ERR_OTHER, __FILE__,__LINE__,msg="unknown <which> name: "//which)
       return
    end select

  end subroutine save_step_data


  function get_latest_struc_fname( prefix, format_out )result(fname)
    use m_setup_artn, only: read_counter_file
    implicit none
    character(*), intent(in) :: prefix
    character(*), intent(in) :: format_out
    character(len=maxlen_fname) :: fname

    integer :: n, strlen
    character(len=64) :: tmp
    character(:), allocatable :: tmp1

    fname=""
    if( trim(format_out) == "none" ) return

    !! read current counter
    n = read_counter_file( trim(prefix)//"counter" )
    !! if nothing has been written yet, set n to 1
    if( n == 0 ) n = 1

    !! write filename
    !! postfix
    write(tmp, "(i0,a,a)") n,".",trim(format_out)
    !! whole string unlimited length
    allocate( tmp1, source=trim(prefix)//trim(tmp) )
    !! length to copy
    strlen = min( maxlen_fname, len_trim(tmp1) )
    fname(1:strlen) = tmp1(1:strlen)

    deallocate(tmp1)
  end function get_latest_struc_fname


end submodule save_step_data_routine
