submodule( m_artn )finalize_routine
  implicit none

contains

  !> @brief
  !>   Finalize the research before to leave ARTn.
  !!   Set all parameters do be ready for a future research.
  !!
  !> @param[in]   lconv       logical flag about ARTn convergence
  !> @param[in]   ierr        integer
  !> @param[out]  disp_code   ARTn code to define the actual step
  !> @param[out]  displ_vec   Atoic Displacement
  !> @return      ierr        flag error
  !
  module subroutine block_finalize( lconv, ierr, disp_code, displ_vec )
    use d_artn_data, only: natoms
    use d_artn_data, only: etot_step
    use d_artn_params, only: flag_false
    use d_artn_params, only: verbose, lend
    use d_artn_params, only: filout, RELX, VOID
    use d_artn_params, only: istep
    ! use d_artn_params, only: lserialize_output
    use m_artn_report, only: write_fail_report, write_comment
    use m_artn_error
    implicit none
    logical, intent(in) :: lconv
    integer, intent(in) :: ierr
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3,natoms)

    character(len=128) :: msg

    !... SCHEMA FINILIZATION


    ! manage the error output:
    select case( ierr )
    case( 0 )
       ! no error, do nothing
    case( ARTN_FAILURE )
       ! failure: output only when verbose>0
       if( verbose>0 ) then
          ! to screen
          call err_write(__FILE__,__LINE__)
          ! to file
          call write_fail_report( void, etot_step, errmsg )
          !
       end if
       !
    case default
       ! all other errors, output always
       ! to screen
       call err_write(__FILE__,__LINE__)
       ! to file
       call write_fail_report( void, etot_step, errmsg )
       !
    end select

    lend = lconv
    !
    ! next displacement should be zero
    displ_vec = 0.0_DP
    ! disp_code = VOID
    disp_code = RELX    !! Mode RELX to fill force = displ_vec and converge

    ! put control flags to false
    call flag_false()

    ! write to file
    IF( verbose > 1 )THEN
       call write_comment( filout, "BLOCK FINALIZE.." )
       write(msg, "(a,1x,i0)") "number of steps:",istep
       call write_comment( filout, trim(msg) )
    ENDIF


    ! IF( lserialize_output ) call artn_data_ptr% dump_generated()
    !
  end subroutine block_finalize

end submodule finalize_routine
