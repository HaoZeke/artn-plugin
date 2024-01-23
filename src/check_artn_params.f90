subroutine check_artn_params( nat, error )
  !! check for coherence among the current artn parameters
  use artn_params
  implicit none

  integer, intent(in) :: nat
  logical, intent(out) :: error

  character(len=256) :: msg

  error = .false.

  if( any(push_ids .gt. nat) ) then
     error = .true.
     write(msg,"(3x,a,1x,i0)") "ERROR:push_ids cannot contain indices larger than value of natoms =",nat
  end if



  !! write error message to global error_message
  if( error ) error_message = trim(error_message)//achar(10)//trim(msg)


end subroutine check_artn_params
