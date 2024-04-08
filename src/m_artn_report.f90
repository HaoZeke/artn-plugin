module m_artn_report
  use precision, only: DP
  implicit none



  !! counter for write_report, but also used in check_force_convergence
  INTEGER, SAVE :: iperp_save !< @brief number of steps in perpendicular relaxation

  !! counter for write_report, but set from artn()
  INTEGER, SAVE :: ilanc_save         !< @brief save current lanczos iteration


  ! output parameter
  INTEGER, SAVE :: prev_disp          !< @brief Save the previous displacement
  INTEGER, SAVE :: prev_push          !< @brief Save the previous push

  character(:), allocatable :: overwrite_msg

  interface

     !! write_struct.f90
     module subroutine write_struct( lat, nat, tau, atm, ityp, force, ener, fscale, form, fname )
       integer,          intent(in) :: nat
       integer,          intent(in) :: ityp(nat)
       character(len=3), intent(in) :: atm(*)
       real(dp),         intent(in) :: tau(3,nat)
       real(dp),         intent(in) :: lat(3,3)
       real(dp),         intent(in) :: force(3,nat)
       real(dp),         intent(in) :: ener
       real(dp),         intent(in) :: fscale
       character(len=10), intent(in) :: form
       character(*), intent(in) :: fname
     end subroutine write_struct
     module subroutine read_struct( lat, nat, tau, atm, ityp, force, form, fname )
       integer,          intent(in) :: nat
       integer,          intent(inout) :: ityp(nat)
       character(len=3), intent(inout) :: atm(*)
       real(dp),         intent(inout) :: tau(3,nat)
       real(dp),         intent(inout) :: lat(3,3)
       real(dp),         intent(inout) :: force(3,nat)
       character(len=10), intent(in) :: form
       character(*),     intent(in) :: fname
     end subroutine read_struct


     !! write_report.f90
     module subroutine write_initial_report( fout )
       character(len=255), intent(in) :: fout
     end subroutine write_initial_report
     module subroutine write_header_report()
     end subroutine write_header_report
     module subroutine write_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
       integer,  intent(in) :: nat
       integer, intent(in)  :: istep
       integer,  intent(in) :: if_pos(3,nat)
       real(dp), intent(in) :: force(3,nat)
       real(dp), intent(in) :: fpara(3,nat)
       real(dp), intent(in) :: fperp(3,nat)
       real(dp), intent(in) :: etot
       real(dp), intent(in) :: lowest_eigval
     end subroutine write_report
     module subroutine write_artn_step_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
       integer,  intent(in) :: nat, istep
       integer,  intent(in) :: if_pos(3,nat)
       real(dp), intent(in) :: force(3,nat),   &
            fpara(3,nat),   &
            fperp(3,nat)
       real(dp), intent(in) :: etot, lowest_eigval
     end subroutine write_artn_step_report
     module subroutine write_inter_report( pushfactor, de )
       integer, intent( in )     :: pushfactor
       real(dp), intent( in )    :: de(*)        !> list of energies
     end subroutine write_inter_report
     module subroutine write_end_report( lsaddle, lpush_final, de )
       logical, intent( in ) :: lsaddle, lpush_final
       real(dp), intent( in ), value :: de
     end subroutine write_end_report
     module subroutine write_fail_report( disp, estep )
       integer, intent( in ) :: disp
       real(dp), intent( in ):: estep
     end subroutine write_fail_report
     module subroutine write_comment( output, txt )
       character(*), intent( in ) :: output, txt
     end subroutine write_comment


  end interface

contains

  !> @details
  !! set initial values to module variables
  subroutine reset_report_params()
    use artn_params, only: VOID
    iperp_save = 0
    ilanc_save = 0
    prev_disp = VOID
    prev_push = VOID
  end subroutine reset_report_params

end module m_artn_report
