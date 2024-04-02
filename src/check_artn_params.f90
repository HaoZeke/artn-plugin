submodule( artn_params ) check_params

  use artn_params
  implicit none

contains

  module subroutine check_artn_params( nat, error )
    !! check for coherence among the current artn parameters
    implicit none

    integer, intent(in) :: nat
    logical, intent(out) :: error

    character(len=256) :: msg

    error = .false.

    if( push_mode == "rad") then
       !
       !! some index in push_ids > nat
       if( any(push_ids .gt. nat) ) then
          error = .true.
          write(msg,"(3x,a,1x,i0)") "ERROR:push_ids cannot contain indices larger than value of natoms =",nat
          error_message = trim(error_message)//achar(10)//trim(msg)
       end if
       !
       !! no push_ids set
       IF( sum(push_ids) == 0 ) then
          error = .true.
          write(msg,"(3x,a)") "push_mode = 'rad' need a list of atoms: define push_ids keyword "
          error_message = trim(error_message)//achar(10)//trim(msg)
       end IF
       !
    endif

    !! check if integers are positive, within bounds

    !! check if real values are reasonable

    !! check if arrays are ok


    !! check on characters
    !! converge_property possible: maxval, norm
    block
      character(*), dimension(*), parameter :: chr = &
           [character(len=6) :: "maxval", "norm" ]
      call check_str( "converge_property", 2, chr, error, msg )
      if( error ) then
         error_message = trim(error_message)//achar(10)//trim(msg)
      end if
    end block

    !! struc_format_out possible: xsf, xyz, none
    block
      character(*), dimension(*), parameter :: chr = &
           [character(len=4) :: "xsf", "xyz", "none" ]
      call check_str( "struc_format_out", 3, chr, error, msg )
      if( error ) then
         error_message = trim(error_message)//achar(10)//trim(msg)
      end if
    end block

    !! engine_units possible values: qe, quantum_espresso, lammps/real, lammps/metal, lammps/lj
    block
      character(*), dimension(*), parameter :: chr = &
           [character(len=16) :: "qe", "quantum_espresso", "lammps/metal", "lammps/real", "lammps/lj" ]
      call check_str( "engine_units", 5, chr, error, msg )
      if( error ) then
         error_message = trim(error_message)//achar(10)//trim(msg)
      end if
    end block


    !! incompatible input combinations::
    !! >> lpush_over = .false. && lmove_nextmin = .true.
    !! >> push_add_const for index which is not in push_ids
    !! >> push_add_const with push_mode /= "list"

  end subroutine check_artn_params




  !! local routine
  subroutine check_str( name, n, val, error, errmsg )
    !! check if string variable with <name> has any of the values from the array "val"
    !! If not, then return error=.true. with a message.
    implicit none
    character(*), intent(in) :: name
    integer,      intent(in) :: n
    character(*), intent(in) :: val(n)
    logical,      intent(out) :: error
    character(256), intent(out) :: errmsg

    integer :: i
    character(256) :: actual_val

    error = .true.
    errmsg=""

    !! find actual value of variable <name>
    select case( name )
    case( "converge_property" ); actual_val = trim(converge_property)
    case( "struc_format_out"); actual_val = trim(struc_format_out)
    case( "engine_units" ); actual_val = trim(engine_units)
    case default
       write(*,*) "unknown name in check_str:",trim(name)
       write(*,*) "at file, line: ",__FILE__, __LINE__
       stop
    end select

    !! loop through val array, the actual value of <name> should be equal
    !! to one of them. If not, error.
    do i = 1, n
       if( trim(actual_val) .eq. trim(val(i)) ) error=.false.
    end do

    if( error ) then
       write(errmsg, "(a,1x,a,1x,a,a,a,*(1x,a,:,','))") &
            name,"has unsupported value:", trim(actual_val), achar(10),&
            "Possible values are:",(trim(val(i)),i=1,n)
    end if

  end subroutine check_str


end submodule check_params
