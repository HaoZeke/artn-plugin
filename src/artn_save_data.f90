module artn_save_data

  implicit none
  private
  public :: save_current_data

contains

  subroutine save_current_data( step, error_code )
    !! save data from artn_params into variables associated to step name
    use units
    use artn_params, only: artn_data_ptr, natoms, lat, types, etot_step, debrief, &
                           istep, tau_step, inewchance, error_message, lowest_eigval
    implicit none
    character(*), intent(in)               :: step
    integer, intent(in), optional   :: error_code

    logical :: input_from_lib

    input_from_lib = associated( artn_data_ptr )

    !! this routine is only useful when launching from interactive mode.
    if( .not. input_from_lib ) return

    !! common (always overwrite with new data)
    artn_data_ptr% nevalf = istep
    artn_data_ptr% inewchance = inewchance
    artn_data_ptr% has_error = .false.
    artn_data_ptr% error_code = 0
    artn_data_ptr% error_message = ""

    !! error signal
    if( present(error_code) ) then
       !!
       !! error_code = 0 means no error
       !!
       if( error_code /= 0 ) then
          artn_data_ptr% has_error = .true.
          artn_data_ptr% error_code = error_code
       end if
    end if

    !! particular to step name
    select case( step )

    case( "init" )
       artn_data_ptr% nat = natoms
       artn_data_ptr% lat = lat
       artn_data_ptr% energy_init = unconvert_energy( etot_step )
       artn_data_ptr% delr_init   = 0.0_DP
       if( allocated( artn_data_ptr% typ_init   ))deallocate( artn_data_ptr% typ_init )
       if( allocated( artn_data_ptr% coords_init))deallocate( artn_data_ptr% coords_init )
       allocate( artn_data_ptr% typ_init,    source=types )
       allocate( artn_data_ptr% coords_init, source=tau_step )

    case( "min1" )
       artn_data_ptr% has_min1 = .true.
       artn_data_ptr% energy_min1 = unconvert_energy( etot_step )
       artn_data_ptr% delr_min1   = debrief(7)
       artn_data_ptr% eigval_min1 = debrief(5)
       if( allocated( artn_data_ptr% typ_min1   ))deallocate( artn_data_ptr% typ_min1 )
       if( allocated( artn_data_ptr% coords_min1))deallocate( artn_data_ptr% coords_min1 )
       allocate( artn_data_ptr% typ_min1,    source=types )
       allocate( artn_data_ptr% coords_min1, source=tau_step )

    case( "min2" )
       artn_data_ptr% has_min2 = .true.
       artn_data_ptr% energy_min2 = unconvert_energy( etot_step )
       artn_data_ptr% delr_min2   = debrief(7)
       artn_data_ptr% eigval_min2 = debrief(5)
       if( allocated( artn_data_ptr% typ_min2   ))deallocate( artn_data_ptr% typ_min2 )
       if( allocated( artn_data_ptr% coords_min2))deallocate( artn_data_ptr% coords_min2 )
       allocate( artn_data_ptr% typ_min2,    source=types )
       allocate( artn_data_ptr% coords_min2, source=tau_step )

    case( "sad" )
       artn_data_ptr% has_sad = .true.
       artn_data_ptr% energy_sad = unconvert_energy( etot_step )
       artn_data_ptr% delr_sad   = debrief(7)
       artn_data_ptr% eigval_sad = debrief(5)
       if( allocated( artn_data_ptr% typ_sad   ))deallocate( artn_data_ptr% typ_sad )
       if( allocated( artn_data_ptr% coords_sad))deallocate( artn_data_ptr% coords_sad )
       allocate( artn_data_ptr% typ_sad,    source=types )
       allocate( artn_data_ptr% coords_sad, source=tau_step )

    case( "latest" )
       !! this is called in case of error
       artn_data_ptr% energy_latest = unconvert_energy( etot_step )
       artn_data_ptr% delr_latest   = debrief(7)
       artn_data_ptr% eigval_latest = unconvert_hessian(lowest_eigval)
       if( allocated( artn_data_ptr% typ_latest   ))deallocate( artn_data_ptr% typ_latest )
       if( allocated( artn_data_ptr% coords_latest))deallocate( artn_data_ptr% coords_latest )
       if( allocated( artn_data_ptr% error_message))deallocate( artn_data_ptr% error_message )
       allocate( artn_data_ptr% typ_latest,    source=types )
       allocate( artn_data_ptr% coords_latest, source=tau_step )
       allocate( artn_data_ptr% error_message, source=trim(error_message) )

    case default
       !! this should not happen
       write(*,*) "UNKNOWN STEP IN SAVE_CURRENT_DATA"
       stop
    end select

  end subroutine save_current_data

end module artn_save_data
