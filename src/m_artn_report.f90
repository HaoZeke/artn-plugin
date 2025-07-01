!
!> @author
!!   Matic Poberznik,
!!   Miha Gunde,
!!   Nicolas Salles,
!!   Antoine Jay
!!
!> @brief 
!!   Contains the I/O routines mainly related for the report output 
!!   and  
!!
module m_artn_report
  use h_artn_precision, only: DP
  implicit none



  !! counter for write_report, but also used in check_force_convergence
  INTEGER, SAVE :: iperp_save !< @brief number of steps in perpendicular relaxation

  !! counter for write_report, but set from artn()
  INTEGER, SAVE :: ilanc_save         !< @brief save current lanczos iteration


  ! output parameter
  INTEGER, SAVE :: prev_disp          !< @brief Save the previous displacement
  INTEGER, SAVE :: prev_push          !< @brief Save the previous push

  character(:), allocatable :: overwrite_msg

  ! array related to the report
  REAL(DP) :: debrief(8)              !< @brief Array contains the values for the debrief output



  !! write_struct.f90
  !........................................................................................
  !> @fn write_struc2file( which )
  !!
  !> @brief
  !!   Write current structure to file, where the filename is following the process of pARTn
  !!   for saddles: prefix_sad + nsaddle
  !!   for minima:  prefix_min + nmin
  !!
  !> @param[in]   which   keyword selecting the filename prefix
  !
  interface write_struc2file
    module procedure write_struc2file
  end interface 
  interface
     module subroutine write_struc2file( which )
       character(*), intent(in) :: which
     end subroutine write_struc2file
  end interface 

  !> @fn write_struct( lat, nat, tau, ityp, force, ener, fscale, form, fname )
  !!
  !> @brief
  !!   A subroutine that writes the structure to a file
  !!   All the list (position/force) are supposed ordered
  !!
  !> @param [in]  nat       number of atoms
  !> @param [in]  ityp      atom type
  !> @param [in]  atm       contains information on atomic types
  !> @param [in]  tau       atomic positions
  !> @param [in]  lat       lattice parameters in alat units
  !> @param [in]  force     list of atomic forces
  !> @param [in]  ener      energy of the current structure, in engine units
  !> @param [in]  fscale    factor for scaling the force
  !> @param [in]  form      format of the structure file (default xsf)
  !> @param [in]  fname     file name
  !
  interface write_struct
    module procedure write_struct
  end interface
  interface 
     module subroutine write_struct( lat, nat, tau, ityp, force, ener, fscale, form, fname )
       integer,          intent(in) :: nat
       integer,          intent(in) :: ityp(nat)
       real(dp),         intent(in) :: tau(3,nat)
       real(dp),         intent(in) :: lat(3,3)
       real(dp),         intent(in) :: force(3,nat)
       real(dp),         intent(in) :: ener
       real(dp),         intent(in) :: fscale
       character(len=10), intent(in) :: form
       character(*), intent(in) :: fname
     end subroutine write_struct
  end interface 
   
  !> @fn read_struct( lat, nat, tau, atm, ityp, force, form, fname )
  !!
  !> @brief
  !!   A subroutine that read the structure to a file (based on xsf_struct of QE)
  !!   Formatted as in write_struct().
  !!   Return the complete structure contained in the file: type, order, x, f, elt
  !!
  !> @param [inout]  nat       number of atoms
  !> @param [inout]  ityp      atom type
  !> @param [inout]  order     atom type
  !> @param [inout]  atm       contains information on atomic types
  !> @param [inout]  tau       atomic positions
  !> @param [inout]  lat       lattice parameters in alat units
  !> @param [inout]  force     list of atomic forces
  !> @param [in]     form      format of the structure file (default xsf)
  !> @param [in]     fname     file name
  !
  interface read_struct
    module procedure read_struct
  end interface 
  interface
     module subroutine read_struct( lat, nat, tau, atm, ityp, force, form, fname )
       integer,          intent(in) :: nat
       integer,          intent(inout) :: ityp(nat)
       character(len=*), intent(inout) :: atm(1:*)
       real(dp),         intent(inout) :: tau(3,nat)
       real(dp),         intent(inout) :: lat(3,3)
       real(dp),         intent(inout) :: force(3,nat)
       character(len=10), intent(in) :: form
       character(*),     intent(in) :: fname
     end subroutine read_struct
  end interface 


  !! write_report.f90
  !........................................................................................
  !> @fn write_initial_report( filout )
  !!
  !> @brief
  !!   Open and write the information of ARTn research in the ouput
  !!   defined by the channel IUARTNOUT and the file name FILOUT.
  !!   New file for output is created at open().
  !!
  !> @param[in]  filout       name of the file
  !!
  interface write_initial_report
    module procedure write_initial_report
  end interface 
  interface
     module subroutine write_initial_report( fout )
       character(len=255), intent(in) :: fout
     end subroutine write_initial_report
  end interface

  !> @fn write_header_report()
  !!
  !> @brief
  !!   write the header before the run. It contains the system units
  !
  interface write_header_report 
    module procedure write_header_report
  end interface
  interface 
     module subroutine write_header_report()
     end subroutine write_header_report
  end interface 

  !> @fn write_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
  !! 
  !> @brief
  !!   a subroutine that writes a report of the current step to the output file
  !!
  !> @param [in]  etot          energy of the system
  !> @param [in]  force         List of atomic forces
  !> @param [in]  fpara         List of parallel atomic forces
  !> @param [in]  fperp         List of perpendicular atomic forces
  !> @param [in]  lowest_eigval Lowest eigenvalue obtained by lanczos
  !> @param [in]  if_pos        Fix the atom or not
  !> @param [in]  istep         actual step of ARTn
  !> @param [in]  nat           Number of atoms
  !
  interface write_report 
    module procedure write_report
  end interface
  interface 
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
  end interface 


  !> @fn write_artn_step_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
  !! 
  !> @brief
  !!   a subroutine that writes a report each new ARTn step
  !!
  !> @param[in]  etot          energy of the system
  !> @param[in]  force         List of atomic forces
  !> @param[in]  fpara         List of parallel atomic forces
  !> @param[in]  fperp         List of perpendicular atomic forces
  !> @param[in]  lowest_eigval Lowest eigenvalue obtained by lanczos
  !> @param[in]  if_pos        Fix the atom or not
  !> @param[in]  istep         actual step of ARTn
  !> @param[in]  nat           Number of atoms
  !
  interface write_artn_step_report
    module procedure write_artn_step_report
  end interface
  interface 
     module subroutine write_artn_step_report( etot, force, fperp, fpara, lowest_eigval, if_pos, istep, nat )
       integer,  intent(in) :: nat, istep
       integer,  intent(in) :: if_pos(3,nat)
       real(dp), intent(in) :: force(3,nat),   &
            fpara(3,nat),   &
            fperp(3,nat)
       real(dp), intent(in) :: etot, lowest_eigval
     end subroutine write_artn_step_report
  end interface 


  !> @fn write_inter_report( pushfactor, de )
  !!
  !> @brief
  !!   intermediate report between the saddle convergence and the
  !!   various minimum relaxation
  !
  !! @param[in]  pushfactor   sens of the push over at saddle point
  !! @param[in]  de(*)        energetic parameters depending on which push over it is
  !
  interface write_inter_report
    module procedure write_inter_report 
  end interface
  interface 
     module subroutine write_inter_report( pushfactor, de )
       integer, intent( in )     :: pushfactor
       real(dp), intent( in )    :: de(*)        !> list of energies
     end subroutine write_inter_report
  end interface 


  !> @fn write_end_report( lsaddle, lpush_final, de )
  !!
  !> @brief
  !!   Report to finish the search
  !!
  !> @param[in]   lsaddle        flag for saddle point convergence
  !> @param[in]   lpush_final    flag for final push
  !> @param[in]   de             energetic parameter
  !
  interface write_end_report
    module procedure write_end_report
  end interface
  interface 
     module subroutine write_end_report( lsaddle, lpush_final, de )
       logical, intent( in ) :: lsaddle, lpush_final
       real(dp), intent( in ), value :: de
     end subroutine write_end_report
  end interface 


  !> @fn write_fail_report( disp, estep )
  !!
  !> @brief
  !!   Fail report
  !!
  !> @param[in]  disp        displacement parameters
  !> @param[in]  estep       Energy of actual step
  !
  interface write_fail_report  
    module procedure write_fail_report
  end interface
  interface 
     module subroutine write_fail_report( disp, estep )
       integer, intent( in ) :: disp
       real(dp), intent( in ):: estep
     end subroutine write_fail_report
  end interface 


  !> @fn write_comment( output, txt )
  !!
  !> @brief 
  !!   Write a comment in the ouput 
  !!
  !> @param[in]   output  output file 
  !> @param[in]   txt     message to write
  !
  interface write_comment
    module procedure write_comment
  end interface
  interface 
     module subroutine write_comment( output, txt )
       character(*), intent( in ) :: output, txt
     end subroutine write_comment
  end interface

contains

  !> @brief
  !!    set initial values to module variables
  subroutine reset_report_params()
    use d_artn_params, only: VOID
    iperp_save = 0
    ilanc_save = 0
    prev_disp = VOID
    prev_push = VOID
    debrief(:) = 0.0_DP
  end subroutine reset_report_params

end module m_artn_report
