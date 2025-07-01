submodule( m_artn )finalize_routine
  implicit none

contains

  !> @brief 
  !>   Finalize the research before to leave ARTn.
  !!   Set all parameters do be ready for a future research.
  !!
  !> @param[in]   lconv       logical flag about ARTn convergence
  !> @param[in]   lerror      logical on error convergence
  !> @param[out]  disp_code   ARTn code to define the actual step 
  !> @param[out]  displ_vec   Atoic Displacement   
  !> @return      ierr        flag error 
  !
  module function block_finalize( lconv, lerror, disp_code, displ_vec )result(ierr)
    use d_artn_data, only: natoms
    use d_artn_data, only: etot_step
    use d_artn_params, only: flag_false
    use d_artn_params, only: verbose, lend
    use d_artn_params, only: filout, RELX, error_message, VOID
    use d_artn_params, only: istep
    use d_artn_params, only: lmove_nextmin, lserialize_output
    ! use d_artn_params, only: artn_data_ptr
    use m_artn_report, only: write_fail_report, write_comment
    implicit none
    logical, intent(in) :: lconv
    logical, intent(in) :: lerror
    integer, intent(out) :: disp_code
    real(DP), intent(out) :: displ_vec(3,natoms)
    integer :: ierr

    character(len=128) :: msg

    ierr = 0

    IF( verbose > 1 )THEN
       call write_comment( filout, "BLOCK FINALIZE.." )
       write(msg, "(a,1x,i0)") "number of steps:",istep
       call write_comment( filout, trim(msg) )
    ENDIF

    !... SCHEMA FINILIZATION
    lend = lconv
    !
    ! next displacement should be zero
    displ_vec = 0.0_DP
    ! disp_code = VOID
    disp_code = RELX    !! Mode RELX to fill force = displ_vec and converge


    call flag_false()
    !
    IF( lerror ) THEN
       ! there is an error, write report
       error_message = 'STOPPING DUE TO ERROR:'//trim(error_message)
       call write_fail_report( void, etot_step )
       call err_set(ERR_OTHER, __FILE__, __LINE__, msg=trim(error_message))
       ierr = ERR_OTHER
    ENDIF

    !

    ! IF( lserialize_output ) call artn_data_ptr% dump_generated()
    !
  end function block_finalize

end submodule finalize_routine
