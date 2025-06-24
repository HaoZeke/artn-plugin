submodule( m_setup_artn )start_guess_routines
  use m_artn_precision, only: DP !, EPS
  use m_error
  implicit none


contains

  !> @brief
  !!    Initialize the push and eigenvec arrays following the mode keyword
  !
  !> @par Purpose
  !  ============
  !> MIHA <= Move in push_init \n
  !! use force input as mask for push_ids when calling push_init for eigenvec. \n
  !! Why? To not generate initial lanczos vec for fixed atoms.
  !
  !> @param[in]   nat        number of point
  !! @param[out]  push       array(3*nat) push of atom
  !! @param[out]  eigenvec   array(3*nat) eigenvec for lanczos
  !
  MODULE FUNCTION start_guess( nat, push, eigenvec )result( lerror )
    !
    USE m_artn_data, ONLY : lat, tau_step
    USE artn_params, ONLY : push_mode, push_step_size, push_step_size_per_atom,    &
                            push_add_const, push_dist_thr, eigen_step_size,        &
                            push_guess, eigenvec_guess, push_ids, filout, verbose, &
                            lUSER_CHOOSE_PER_ATOM, push_initial_vector
    !
    IMPLICIT NONE
    !
    ! Arguments
    INTEGER,  INTENT(IN)  :: nat
    REAL(DP), INTENT(OUT) :: push(3,nat)
    REAL(DP), INTENT(OUT) :: eigenvec(3,nat)
    LOGICAL :: lerror
    !
    ! Local variables
    !character(*), parameter :: here = "start_guess"
    INTEGER               :: dummy(nat)
    REAL(DP)              :: push_size
    INTEGER               :: u0, iat
    real(DP)              :: array_zero(4,nat)
    integer :: ierr
    !
    lerror = .false.
    IF( verbose>1 ) OPEN(NEWUNIT=u0, FILE=filout, FORM='formatted', POSITION='append', STATUS='unknown')
    ! write(*,*) "in start guess:"
    ! write(*,*) "push_mode",trim(push_mode)
    ! write(*,*) "eigenvec guess",trim(eigenvec_guess)
    !
    ! The PUSH vector
    SELECT CASE( TRIM(push_mode) )
       !
    CASE( 'all', 'list', 'rad' )
       !
       IF( verbose>1 ) WRITE(u0,'(5x,"|> First PUSH vectors almost RANDOM")')
       !
       push_size = push_step_size
       IF( lUSER_CHOOSE_PER_ATOM ) push_size = push_step_size_per_atom
       !
       ! generate push vector
       CALL generate_push_init( nat, tau_step, lat, push_ids, push_dist_thr, push_add_const, &
            push_size, push_mode, push )
       !write(*,*) here,"> ", push
       !
    CASE( 'file' )
       !
       ! read from file
       IF( verbose >1 ) WRITE(u0,'(5x,"|> PUSH vectors read in file",1x,a)') TRIM(push_guess)
       ierr = read_guess( nat, push, push_guess )
       if( ierr /= 0 ) then
          call err_write(__FILE__, __LINE__ )
          lerror = .true.
          return
       end if
       !
    CASE( "input" )
       !
       ! do nothing here, push vector is already present
    END SELECT
    !
    ! ... Print the displacement if not all atoms involved
    IF( verbose >2 .AND. (TRIM(push_mode) .NE.'all') ) THEN
        WRITE(u0,'(5x,"|> PUSH Vector is:")')
        DO iat=1, nat
           IF ( ANY(ABS(push(:, iat)) > 0.0_DP) ) THEN
              WRITE(u0,'(5x,"|> atom",i8, " dx= ", f6.4, " dy= ", f6.4, " dz= ",f6.4)')&
              iat, push(1, iat), push(2, iat), push(3, iat)
           ENDIF
        ENDDO
    ENDIF
    !
    ! generate EIGENVEC:
    SELECT CASE( trim(eigenvec_guess) )
       !
    CASE( 'file' )
       !
       !! read from file
       IF( verbose>1 ) WRITE(u0,'(5x,"|> First EIGEN vectors read in file",1x,a)') TRIM(eigenvec_guess)
       ierr = read_guess( nat, eigenvec, eigenvec_guess )
       if( ierr /= 0 ) then
          call err_write(__FILE__, __LINE__ )
          lerror = .true.
          return
       end if
       !
    CASE( 'input' )
       !
       ! do nothing here, eigenvec is already present
       ! write(*,*) "eigenvec guess from input"
       ! write(*,*) eigenvec(:,1)

    CASE default
       !
       !! generate random
       IF( verbose>1 ) WRITE(u0,'(5x,"|> First EIGEN vectors RANDOM")')
       ! push_add_const = 0
       ! write(*,*) "in eigenvec guess default:"
       ! write(*,*) allocated(push_add_const)
       ! allocate( array_zero, source=push_add_const)
       array_zero = 0.0_DP
       !! Replace Mask on norm(force) by keyword 'list_force'.
       !! keyword 'bias_force' = orient the randomness on the actual atomic forces
       call generate_push_init( nat, tau_step, lat, dummy, push_dist_thr, array_zero, &
                                eigen_step_size, 'list_force', eigenvec )
            ! eigen_step_size, 'list_push', eigenvec )
       ! write(*,*) "eigen step size",eigen_step_size
       ! write(*,*) "--> after generate_init_pus ev(1,1)",eigenvec(1,1)
       !
    END SELECT
    !
    IF( verbose>1 ) CLOSE(UNIT=u0, STATUS='KEEP')
    !
    ! allocate and save the initial push vector, to avoid reading from initp file.
    ! for the 'double random' vector when losing eigenvalue
    !
    IF( allocated(push_initial_vector))deallocate( push_initial_vector )
    ALLOCATE( push_initial_vector, source = push )
    !
  END FUNCTION start_guess


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
  function READ_GUESS( nat, vec, filename ) result( ierr )
    !
    !> [read_guess]
    use m_artn_units, only : unconvert_length
    use artn_params,  only : push_dist_thr, push_ids, push_step_size, words
    use m_artn_tools, only : parser, read_line, is_numeric
    use m_artn_tools, only : random_displacement, neigh_random_displacement !! could be in this module
    implicit none

    integer,      intent( in ) :: nat
    REAL(DP),     intent( out ) :: vec(3,nat)
    character(*), intent( in ) :: filename
    integer :: ierr

    character(len=256) :: line, msg
    !character(:), allocatable :: words(:)
    integer :: i, n, u0, nwords, idx, j, ios
    logical :: file_exists, neiglist


    ierr = 0
    !PRINT*, "   ** ENTER IN READ_GUESS()"

    ! ...Look at the file

    inquire( file=filename, exist=file_exists )
    if( .not.file_exists ) then
       ierr = ERR_FILE
       call err_set(ierr, __FILE__, __LINE__, msg="Filename does not exist: "//filename )
       return
    end if




    !  ...Initialization

    if( allocated(push_ids) )deallocate(push_ids)
    neiglist = .false.
    !if( push_dist_thr > 0.0e-8 ) neiglist = .true.
    if( push_dist_thr > EPS ) neiglist = .true.
    !print*, "DIST_THR", dist_thr, unconvert_length( dist_thr )



    ! ...Read file

    OPEN( newunit=u0, file=filename, ACTION="READ", iostat=ios, iomsg=msg )
    if( ios /= 0 ) then
       ierr = ERR_FILE
       call err_set(ierr, __FILE__, __LINE__, msg=trim(msg) )
       return
    end if


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
             ierr = ERR_OTHER
             call err_set(ierr, __FILE__, __LINE__, msg="index proposed are not valid: "//words(1) )
             return
          endif
          push_ids(i) = idx

          !print*, "   ** push_ids", idx
          do j = 2,4
             IF( is_numeric(trim(words(j))) )then
                read(words(j),*) vec(j-1,idx)
                !ELSEIF( words(j) == "*" )THEN         !! Idea for more flexibility
                !  mask(j-1,idx)
             ELSE
                ierr = ERR_OTHER
                call err_set(ierr, __FILE__, __LINE__, msg="Displacements proposed are not valid" )
                return
             ENDIF
          enddo
          !!> @warning :: Maybe put a test the norm of the user vector to compare to the
          !!   push_step_size parameters.
          !print*, idx, "constrain disp:", vec(:,idx)

       case default
          ierr = ERR_OTHER
          call err_set(ierr, __FILE__, __LINE__, msg="Empty line" )
          return

       end select

       ! ...Add the neigbors
       if( neiglist )call neigh_random_displacement( nat, idx, push_dist_thr, vec )

    enddo


    CLOSE( u0 )
    !> [read_guess]

  end function READ_GUESS


end submodule start_guess_routines
