module m_tools
  use precision, only: DP

  implicit none

  public


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


     !! compute_delr.f90
     module subroutine compute_delr_vec( nat, pos, old_pos, lat, delr )
       INTEGER, intent( in ) :: nat
       REAL(DP), intent( in ) :: pos(3,nat)
       real(dp), intent(in) :: lat(3,3)
       REAL(DP), intent( in ) :: old_pos(3,nat)
       REAL(DP), intent( out ) :: delr(3,nat)
     end subroutine compute_delr_vec


     !! center.f90
     module subroutine center( vec, nat )
       integer, intent(in) :: nat
       real(DP), intent(inout) :: vec(3,nat)
     end subroutine center


     !! string_tools.f90
     module integer function parser( instrg, FS, args)result(nargs)
       CHARACTER(len=*),              intent( in ) :: instrg
       character(len=1),              intent( in ) :: FS
       ! CHARACTER(len=:), allocatable, intent( inout ) :: args(:)
       CHARACTER(len=:), allocatable, intent( out ) :: args(:)
     end function parser
     module subroutine read_line(fd, line, end_of_file)
       integer, intent(in) :: fd
       character(len=256), intent(out) :: line
       logical, optional, intent(out) :: end_of_file
     end subroutine read_line
     module elemental Function to_lower( str )Result( string )
       Character(*), Intent(IN) :: str
       Character(LEN(str))      :: string
     end function to_lower
     MODULE FUNCTION c2f_string(ptr) RESULT(f_string)
       use, intrinsic :: iso_c_binding, only: c_ptr
       TYPE(c_ptr), INTENT(IN) :: ptr
       CHARACTER(LEN=:), ALLOCATABLE :: f_string
     end FUNCTION c2f_string
     module function f2c_string( str ) result(ptr)
       use, intrinsic :: iso_c_binding, only: c_ptr
       character(*), intent(in) :: str
       type( c_ptr ) :: ptr
     end function f2c_string
     module function c2f_char( cstring )result(fstring)
       use, intrinsic :: iso_c_binding, only: c_char
       character(len=1,kind=c_char), intent(in) :: cstring(*)
       character(:), allocatable :: fstring
     end function c2f_char
     module elemental FUNCTION is_numeric(string)
       CHARACTER(len=*), INTENT(IN) :: string
       LOGICAL :: is_numeric
     end function is_numeric



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


     !! perpforce.f90
     module subroutine perpforce( force, if_pos, push, fperp, fpara, nat )
       INTEGER,  INTENT(IN)     :: nat
       REAL(DP), INTENT(IN)     :: push(3,nat)
       REAL(DP), INTENT(IN)     :: force(3,nat)
       REAL(DP), INTENT(OUT)    :: fpara(3,nat)
       REAL(DP), INTENT(OUT)    :: fperp(3,nat)
       INTEGER,  INTENT(IN)     :: if_pos(3,nat)
     end subroutine perpforce
     module subroutine field_split( n, field, mask, fref, fperp, fpara )
       INTEGER,  INTENT(IN)     :: n
       REAL(DP), INTENT(IN)     :: field(*)
       REAL(DP), INTENT(IN)     :: fref(*)
       INTEGER,  INTENT(IN)     :: mask(*)
       REAL(DP), INTENT(OUT)    :: fpara(*)
       REAL(DP), INTENT(OUT)    :: fperp(*)
     end subroutine field_split


     !! check_force_convergence.f90
     module subroutine check_force_convergence( nat, force, if_pos, fperp, fpara, lforc_conv, lsaddle_conv )
       INTEGER,  INTENT(IN)  :: nat
       REAL(DP), INTENT(IN)  :: force(3,nat)
       REAL(DP), INTENT(IN)  :: fperp(3,nat)
       REAL(DP), INTENT(IN)  :: fpara(3,nat)
       INTEGER,  INTENT(IN)  :: if_pos(3,nat)
       LOGICAL,  INTENT(OUT) :: lforc_conv, lsaddle_conv
     end subroutine check_force_convergence


     !! push_over_procedure.f90
     module subroutine push_over_procedure( nat, v0, push_factor, displ_vec )
       integer, intent(in)    :: nat
       real(dp), intent(in)   :: v0(3,nat)
       integer, intent(in)    :: push_factor
       real(dp), intent(out)  :: displ_vec(3,nat)
     end subroutine push_over_procedure


     !! random.f90
     module subroutine initialize_random_seed(zseed)
       integer, intent(inout) :: zseed
     end subroutine initialize_random_seed
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


     !! permute.f90
     module subroutine permute_int1d( dim1, array, order )
       integer, intent(in) :: dim1
       integer, intent(inout) :: array(dim1)
       integer, intent(in) :: order(dim1)
     end subroutine permute_int1d
     module subroutine unpermute_int1d( dim1, array, order)
       integer, intent(in) :: dim1
       integer, intent(inout) :: array(dim1)
       integer, intent(in) :: order(dim1)
     end subroutine unpermute_int1d
     module subroutine permute_real2d( dim1, array, order )
       integer, intent(in) :: dim1
       real(DP), intent(inout) :: array( 3, dim1 )
       integer, intent(in) :: order(dim1)
     end subroutine permute_real2d
     module subroutine unpermute_real2d( dim1, array, order )
       integer, intent(in) :: dim1
       real(DP), intent(inout) :: array( 3, dim1 )
       integer, intent(in) :: order(dim1)
     end subroutine unpermute_real2d


  end interface


  !! C malloc function
  interface
     function c_malloc(size) bind(C, name="malloc")
       use, intrinsic :: iso_c_binding, only: c_size_t, c_ptr
       integer(c_size_t), intent(in), value :: size
       type(c_ptr) :: c_malloc
     end function c_malloc
  end interface


  !! interfaces to blas
  interface
     pure function ddot(n, dx, incx, dy, incy) result(dot)
       import :: dp
       integer,  intent(in) :: n      !! number of elements in input vector(s)
       real(dp), intent(in) :: dx(*)  !! array, dimension ( 1 + ( N - 1 )*abs( INCX ) )
       integer,  intent(in) :: incx   !! storage spacing between elements of DX
       real(dp), intent(in) :: dy(*)  !! array, dimension ( 1 + ( N - 1 )*abs( INCY ) )
       integer,  intent(in) :: incy   !! storage spacing between elements of DY
       real(dp) :: dot
     end function ddot

     pure function dnrm2(n, x, incx) result(nrm2)
       import :: dp
       integer,  intent(in) :: n      !! number of elements in input vector(s)
       real(dp), intent(in) :: x(*)   !! array, dimension ( 1 + ( N - 1 )*abs( INCX ) )
       integer,  intent(in) :: incx   !! storage spacing between elements of X
                                      !! If INCX > 0, X(1+(i-1)*INCX) = x(i) for 1 <= i <= n
                                      !! If INCX < 0, X(1-(n-i)*INCX) = x(i) for 1 <= i <= n
                                      !! If INCX = 0, x isn't a vector so there is no need to call
                                      !! this subroutine. If you call it anyway, it will count x(1)
                                      !! in the vector norm N times.
       real(dp) :: nrm2
     end function dnrm2

  end interface

contains


end module m_tools
