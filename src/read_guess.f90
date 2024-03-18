
!.....................................................................................................
!> @authors
!!   Matic Poberznik
!!   Miha Gunde
!!   Nicolas Salles
!
!> @brief Read field direction from file
!
!> @par Purpose
!  ============
!
!> @verbatim
!>   Read the configuration from a file formatted xyz but as we want to customise 
!>   the push, the position are the push: no position means random displacement
!>   Can list only a part of particle in the system.
!> @endverbatim
!
!> @ingroup Control
!
!> @param[in]     nat       number of atoms  
!> @param[out]    vec       initial push
!> @param[in]     filename  input file name
!>
!> @snippet read_guess.f90 read_guess
!>
SUBROUTINE READ_GUESS( nat, vec, filename )
  !
  !> [read_guess]
  use precision, only: DP
  use units,       only : unconvert_length
  use artn_params, only : warning, iunartout, push_dist_thr, push_ids, push_step_size, words
  use m_tools,       only : parser, read_line
  use m_tools, only: random_displacement, neigh_random_displacement !! could be in this module
  implicit none

  integer,      intent( in ) :: nat
  REAL(DP),     intent( out ) :: vec(3,nat)
  character(*), intent( in ) :: filename

  character(len=256) :: line
  !character(:), allocatable :: words(:)
  integer :: i, n, u0, nwords, idx, j
  logical :: ok, neiglist


  !PRINT*, "   ** ENTER IN READ_GUESS()"

  ! ...Look at the file

  inquire( file=filename, exist=ok )
  if( .not.ok )CALL warning( iunartout, 'READ_GUESS','File does not find')



  !  ...Initialization

  if( allocated(push_ids) )deallocate(push_ids)
  neiglist = .false.
  if( push_dist_thr > 0.0e-8 ) neiglist = .true.
  !print*, "DIST_THR", dist_thr, unconvert_length( dist_thr )



  ! ...Read file

  OPEN( newunit=u0, file=filename, ACTION="READ" )

  READ(u0,*) n
  allocate(push_ids(n))
  READ(u0,*)

  do i = 1, n

     idx = 0
     call read_line( u0, line )
     nwords = parser( trim(line), " ", words )

     select case( nwords )

       !! Only the atom index
       case( 1 )
         IF( is_numeric(words(1)) )read(words(1),*) idx
         push_ids(i) = idx
         call random_displacement( vec(:,idx) )
         vec(:,idx) = vec(:,idx) * push_step_size
         !print*, idx, "random disp:", vec(:,idx)


       !! Atom index and push direction constrain
       case( 2: )
         IF( is_numeric(words(1)) )then
           read(words(1),*) idx
         else
           call warning( iunartout, 'READ_GUESS', 'index  proposed are not valid', words )
         endif
         push_ids(i) = idx

         !print*, "   ** push_ids", idx
         do j = 2,4
            IF( is_numeric(trim(words(j))) )then
              read(words(j),*) vec(j-1,idx)
            !ELSEIF( words(j) == "*" )THEN         !! Idea for more flexibility 
            !  mask(j-1,idx)
            ELSE
              call warning( iunartout, 'READ_GUESS', 'Displacement propose are not valid', words )
            ENDIF
         enddo
         !!> @warning :: Maybe put a test the norm of the user vector to compare to the 
         !!   push_step_size parameters. 
         !print*, idx, "constrain disp:", vec(:,idx)

       case default
         call warning( iunartout, 'READ_GUESS', 'Empty line' )
         exit

     end select

     ! ...Add the neigbors
     if( neiglist )call neigh_random_displacement( nat, idx, push_dist_thr, vec )

  enddo


  CLOSE( u0 )
  !> [read_guess]

CONTAINS
  !......................................................
  !> @brief
  !!   test if the string represent a number or not
  !
  !> @param[in]    string   input string
  !> @return       logical  
  !
  elemental FUNCTION is_numeric(string)
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(IN) :: string
    LOGICAL :: is_numeric
    REAL :: x
    INTEGER :: e,n
    CHARACTER(len=12) :: fmt

    n = LEN_TRIM(string)
    WRITE(fmt,'("(F",I0,".0)")') n
    READ(string,fmt,IOSTAT=e) x
    is_numeric = (e == 0)
  END FUNCTION is_numeric

END SUBROUTINE READ_GUESS





