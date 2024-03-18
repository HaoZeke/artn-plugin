module tools
  use precision, only: DP

  implicit none


  interface

     !! pbc.f90
     module subroutine pbc( vec, at )
       REAL(DP), INTENT(INOUT) :: vec(3) !> input vector in atomic units
       REAL(DP), INTENT(IN) :: at(3,3)   !> lattice vectors
     end subroutine pbc


     !! diag.f90
     module subroutine diag(n, A, eigvals, vec)
       INTEGER,              intent(in) :: n
       REAL(DP), DIMENSION(n,n), intent(inout) :: A
       REAL(DP), DIMENSION(n),   intent(out) :: eigvals
       INTEGER,              intent(in) :: vec
     end subroutine diag


     !! center.f90
     module subroutine center( vec, nat )
       integer, intent(in) :: nat
       real(DP), intent(inout) :: vec(3,nat)
     end subroutine center


     !! string_tools.f90
     module integer function parser( instrg, FS, args)result(nargs)
       CHARACTER(len=*),              intent( in ) :: instrg
       character(len=1),              intent( in ) :: FS
       CHARACTER(len=:), allocatable, intent( inout ) :: args(:)
     end function parser
     module subroutine read_line(fd, line, end_of_file)
       integer, intent(in) :: fd
       character(len=256), intent(out) :: line
       logical, optional, intent(out) :: end_of_file
     end subroutine read_line


     !! make_filename.f90
     module subroutine make_filename( f, prefix, n )
       character(*), intent(out) :: f
       character(*), intent(in) :: prefix
       integer,      intent(inout) :: n
     end subroutine make_filename


     !! sum_force.f90
     module function dsum( n, f)result(res)
       integer, intent(in) :: n
       real(DP), intent(in) :: f(*)
       real(DP) :: res
     end function dsum
     module subroutine sum_force( force, nat, force_tot )
       INTEGER, INTENT(IN) :: nat
       REAL(DP), INTENT(IN) :: force(3,nat)
       REAL(DP), INTENT(OUT) :: force_tot
     end subroutine sum_force


     !! random.f90
     module subroutine random_displacement( vec )
       real(DP), intent(inout ) :: vec(3)
     end subroutine random_displacement
     module subroutine neigh_random_displacement( nat, id, rcut, vec )
       integer, intent( in ) :: id, nat
       real(DP), intent( in ) :: rcut
       real(DP), intent( out ) :: vec(3,nat)
     end subroutine neigh_random_displacement
     module subroutine random_array( n, v, bias )
       integer, intent( in ) :: n
       real(DP), intent( out ) :: v(*)
       real(DP), intent( in ), optional :: bias(*)
     end subroutine random_array


  end interface

contains


end module tools
