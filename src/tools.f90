module tools
  use precision, only: DP

  implicit none


  interface
     module subroutine pbc( vec, at )
       REAL(DP), INTENT(INOUT) :: vec(3) !> input vector in atomic units
       REAL(DP), INTENT(IN) :: at(3,3)   !> lattice vectors
     end subroutine pbc

     module subroutine diag(n, A, eigvals, vec)
       INTEGER,              intent(in) :: n
       REAL(DP), DIMENSION(n,n), intent(inout) :: A
       REAL(DP), DIMENSION(n),   intent(out) :: eigvals
       INTEGER,              intent(in) :: vec
     end subroutine diag

     module subroutine center( vec, nat )
       integer, intent(in) :: nat
       real(DP), intent(inout) :: vec(3,nat)
     end subroutine center

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


  end interface

contains


end module tools
