!> @author
!!  Matic Poberznik, 
!!  Miha Gunde, 
!!  Nicolas Salles,
!!  Antoine Jay
!!
!> @brief
!!   Contains all usefull routine to do everything
!
module m_artn_tools
  use h_artn_precision, only: DP

  implicit none

  public

  !! newline
  character(*), parameter :: C_NL = new_line('a')
  !! tab = 6*space
  character(*), parameter :: C_TAB = &
       achar(32)//achar(32)//achar(32)//&
       achar(32)//achar(32)//achar(32)



  !! pbc.f90
  !......................................................................
  !> @fn pbc( vec, at, bg )
  !!
  !> @brief
  !!   A function that takes into account periodic boundary conditions,
  !!   based on the pbc function of the contraints_module of QE
  !!
  !> @param [inout] vec   input vector in atomic units
  !> @param [in]    at    lattice vectors in columns, at(:,1)=a, at(:,2)=b, at(:,3)=c
  !> @param [in]    bg    inverse lattice
  !!
  interface pbc 
    module procedure pbc
  end interface
  interface
     module subroutine pbc( vec, at, bg )
       REAL(DP), INTENT(INOUT) :: vec(3) !> input vector in atomic units
       REAL(DP), INTENT(IN) :: at(3,3)   !> lattice vectors
       REAL(DP), INTENT(IN) :: bg(3,3)   !> inverse lattice vectors
     end subroutine pbc
  end interface 

  !> @fn invmat3x3(mat,inv)
  !!
  !> @brief
  !!   Subroutine that calculates the inverse of a 3x3 matrix
  !!
  !> @param [in]  mat   Matrix to inverse
  !> @param [out] inv   Inverse of the Matrix
  !!
  interface invmat3x3
    module procedure invmat3x3
  end interface
  interface
     MODULE SUBROUTINE invmat3x3(mat,inv)
       REAL(DP), INTENT(IN) :: mat(3,3)
       REAL(DP), INTENT(OUT) :: inv(3,3)
     END SUBROUTINE invmat3x3
  end interface



  !! diag.f90
  !.......................................................................
  !> @fn diag(n, A, eigvals, vec)
  !!
  !> @brief Diagonalize Matrix
  !!
  !> @par Purpose
  !  ============
  !> assuming a general square matrix (can be nonsymmetric). \n
  !! On output A is overwritten by eigenvectors in rows, if vec=0, then
  !! A is just 0.0 on output.
  !!
  !> @param[in]     n         dimension of matrix A
  !! @param[in,out] A         matrix to be diagonalised, overwritten by eigenvectors on output
  !! @param[out]    eigvals   output vector of eigenvalues, not sorted!
  !! @param[in]     vec       0 if don't want to compute eigenvectors, 1 otherwise
  !
  interface diag 
    module procedure diag
  end interface
  interface
     module subroutine diag(n, A, eigvals, vec)
       INTEGER,              intent(in) :: n
       REAL(DP), DIMENSION(n,n), intent(inout) :: A
       REAL(DP), DIMENSION(n),   intent(out) :: eigvals
       INTEGER,              intent(in) :: vec
     end subroutine diag
  end interface 


  !! compute_delr.f90
  !..........................................................................
  !> @fn compute_delr_vec( nat, pos, old_pos, lat, delr )
  !!
  !> @brief
  !!   compute the displacement vector for each atom with respect to old_pos
  !
  !> @param[in]  nat       number of atoms
  !! @param[in]  pos       actual position of atoms in 3 dimension
  !! @param[in]  old_pos   reference atomic position
  !! @param[in]  lat       box parameters
  !! @param[out] delr      displacement of each atom
  !
  interface compute_delr_vec 
    module procedure compute_delr_vec
  end interface
  interface
     module subroutine compute_delr_vec( nat, pos, old_pos, lat, delr )
       INTEGER, intent( in ) :: nat
       REAL(DP), intent( in ) :: pos(3,nat)
       real(dp), intent(in) :: lat(3,3)
       REAL(DP), intent( in ) :: old_pos(3,nat)
       REAL(DP), intent( out ) :: delr(3,nat)
     end subroutine compute_delr_vec
  end interface 


  !! center.f90
  !.........................................................................
  !> @fn center( vec, nat )
  !!
  !> @brief
  !!   takes as input a vector of size (3,nat) and centers it
  !!
  !> @param[in]     nat    number of atom
  !! @param[inout]  vec    output vector
  !
  interface center 
    module procedure center
  end interface
  interface
     module subroutine center( vec, nat )
       integer, intent(in) :: nat
       real(DP), intent(inout) :: vec(3,nat)
     end subroutine center
  end interface


  !! string_tools.f90
  !................................................................................
  !> @fn parser( instrg, FS, args)result(nargs)
  !!
  !> @brief
  !!   Parse the instrg thank to the Field Separator FS and return
  !!   the list of string and the number of element in the list
  !!
  !> @todo
  !!   HAVE TO BE ADAPTED FOR MULTIPLE FS
  !!
  !> @param[in]   instrg   input string
  !> @param[in]   FS       Field Separator (one for the moment)
  !> @param[out]  args     arrays of string
  !> @return      nargs    number of string in output
  !
  interface parser 
    module procedure parser
  end interface
  interface
     module integer function parser( instrg, FS, args)result(nargs)
       CHARACTER(len=*),              intent( in ) :: instrg
       character(len=1),              intent( in ) :: FS
       ! CHARACTER(len=:), allocatable, intent( inout ) :: args(:)
       CHARACTER(len=:), allocatable, intent( out ) :: args(:)
     end function parser
  end interface

  !> @fn read_line(fd, line, end_of_file)
  !!
  !> @brief
  !!   Read a line, makes possible to use # for comment lines, skips empty lines,
  !!   is pretty much a copy from QE.
  !!
  !> @details  Quantum ESPRESSO routine
  !!
  !> @param[in]   fd            file descriptor
  !! @param[out]  line          what it reads
  !! @param[out]  end_of_file   logical to signal the EOF
  !
  interface read_line
    module procedure read_line
  end interface
  interface
     module subroutine read_line(fd, line, end_of_file)
       integer, intent(in) :: fd
       character(len=256), intent(out) :: line
       logical, optional, intent(out) :: end_of_file
     end subroutine read_line
  end interface


  !> @fn to_lower( str )Result( string )
  !!
  !> @brief
  !!   Changes a string to lower case
  !!
  !> @param[in]   str     input
  !> @returns     string  output
  interface to_lower
    module procedure to_lower 
  end interface
  interface
     module function to_lower( str )Result( string )
       Character(*), Intent(IN) :: str
       Character(LEN(str))      :: string
     end function to_lower
  end interface 

  interface
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
  end interface

  !> @fn is_numeric(string) 
  !> @brief
  !!   test if the string represent a number or not
  !!
  !> @param[in]    string   input string
  !> @return       logical  
  !
  interface is_numeric
    module procedure  is_numeric
  end interface
  interface
     module elemental FUNCTION is_numeric(string)
       CHARACTER(len=*), INTENT(IN) :: string
       LOGICAL :: is_numeric
     end function is_numeric
  end interface


  !! make_filename.f90
  !.....................................................................
  !> @fn make_filename( f, prefix, n )
  !!
  !> @brief
  !!    build a filename from the prefix and the number n
  !!
  !> @param[out]    f        filename
  !> @param[in]     prefix   prefix for filename
  !> @param[inout]  n        integer for the file name
  ! 
  interface make_filename
    module procedure make_filename
  end interface
  interface
     module subroutine make_filename( f, prefix, n )
       character(*), intent(out) :: f
       character(*), intent(in) :: prefix
       integer,      intent(inout) :: n
     end subroutine make_filename
  end interface


  !! sum_force.f90
  !................................................................................
  !> @fn dsum( n, f)result(res)
  !!
  !> @brief
  !!   sum the component square of the field in the mood of ddot of lib lapack
  !!   The unroll loop can be faster than previous version
  !!
  !> @note Come from blas library
  !!
  !> @param[in]   n     number of field's component 
  !! @param[in]   f     field f(n)
  !! @return      res   sum of square if the field f
  !
  interface dsum
    module procedure dsum
  end interface
  interface
     module function dsum( n, f)result(res)
       integer, intent(in) :: n
       real(DP), intent(in) :: f(*)
       real(DP) :: res
     end function dsum
  end interface

  !> @fn sum_force( force, nat, force_tot )
  !!
  !> @brief
  !!   subroutine that sums the forces on all atoms and returns the total force
  !!
  !> @param [in]  nat       Size of list: number of atoms
  !> @param [in]  force     List of atomic forces
  !> @param [out] force_tot Sum of the list of forces
  !
  interface sum_force
    module procedure sum_force
  end interface
  interface
     module subroutine sum_force( force, nat, force_tot )
       INTEGER, INTENT(IN) :: nat
       REAL(DP), INTENT(IN) :: force(3,nat)
       REAL(DP), INTENT(OUT) :: force_tot
     end subroutine sum_force
  end interface


  !! split_field.f90
  !............................................................................
  
     !! Not used anymore
  interface
     module subroutine perpforce( force, if_pos, push, fperp, fpara, nat )
       INTEGER,  INTENT(IN)     :: nat
       REAL(DP), INTENT(IN)     :: push(3,nat)
       REAL(DP), INTENT(IN)     :: force(3,nat)
       REAL(DP), INTENT(OUT)    :: fpara(3,nat)
       REAL(DP), INTENT(OUT)    :: fperp(3,nat)
       INTEGER,  INTENT(IN)     :: if_pos(3,nat)
     end subroutine perpforce
  end interface

  !> @fn split_field( n, field, mask, fref, fperp, fpara )
  !!
  !> @brief
  !!   Extract the parallel and perpendicular component of field
  !!   followig a reference field (fref) according to a mask.
  !!   (Generalization of perpforce)
  !!
  !> @param[in]     n           number of point in the field
  !! @param[in]     field       Field input
  !! @param[in]     mask        Constrain in field
  !! @param[in]     fref        Parallel direction field reference
  !! @param[out]    fperp       Perpendicular force field following dir field
  !! @param[out]    fpara       Parallel force field following dir field
  !
  !interface split_field 
  !  module procedure split_field
  !end interface
  interface
     module subroutine split_field( n, field, mask, fref, fperp, fpara )
       INTEGER,  INTENT(IN)     :: n
       REAL(DP), INTENT(IN)     :: field(*)
       REAL(DP), INTENT(IN)     :: fref(*)
       INTEGER,  INTENT(IN)     :: mask(*)
       REAL(DP), INTENT(OUT)    :: fpara(*)
       REAL(DP), INTENT(OUT)    :: fperp(*)
     end subroutine split_field
  end interface


!     !! check_force_convergence.f90
!     module subroutine check_force_convergence( nat, force, if_pos, fperp, fpara, lforc_conv, lsaddle_conv )
!       INTEGER,  INTENT(IN)  :: nat
!       REAL(DP), INTENT(IN)  :: force(3,nat)
!       REAL(DP), INTENT(IN)  :: fperp(3,nat)
!       REAL(DP), INTENT(IN)  :: fpara(3,nat)
!       INTEGER,  INTENT(IN)  :: if_pos(3,nat)
!       LOGICAL,  INTENT(OUT) :: lforc_conv, lsaddle_conv
!     end subroutine check_force_convergence
!
!
!     !! push_over_procedure.f90
!     module subroutine push_over_procedure( nat, v0, push_factor, displ_vec )
!       integer, intent(in)    :: nat
!       real(dp), intent(in)   :: v0(3,nat)
!       integer, intent(in)    :: push_factor
!       real(dp), intent(out)  :: displ_vec(3,nat)
!     end subroutine push_over_procedure


  !! random.f90
  !......................................................................
  !> @todo copy/paste the doc
  interface
     module subroutine artn_random_number( z )
       real(dp), intent(out) :: z
     end subroutine artn_random_number
     module subroutine artn_random_initialize(zseed)
       integer, intent(inout) :: zseed
     end subroutine artn_random_initialize
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


  !! permute.f90
  !......................................................................
  !> @todo Copy/paste the doc
  interface
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


end module m_artn_tools
