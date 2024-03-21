submodule( m_artn_report )write_struct_routines
  use precision, only: DP
  implicit none
contains

  !> @brief
  !!   A subroutine that writes the structure to a file (based on xsf_struct of QE)
  !!   All the list (position/force) are supposed ordered
  !
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
  MODULE SUBROUTINE write_struct( lat, nat, tau, atm, ityp, force, ener, fscale, form, fname )
    !
    IMPLICIT NONE
    ! -- Arguments
    INTEGER,          INTENT(IN) :: nat            !> number of atoms
    INTEGER,          INTENT(IN) :: ityp(nat)      !> atom type
    CHARACTER(LEN=3), INTENT(IN) :: atm(*)         !> contains information on atomic types
    REAL(DP),         INTENT(IN) :: tau(3,nat)     !> atomic positions
    REAL(DP),         INTENT(IN) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),         INTENT(IN) :: force(3,nat)   !> list of atomic forces
    REAL(DP),         INTENT(IN) :: ener           !> energy of the structure, in engine units
    REAL(DP),         INTENT(IN) :: fscale         !> factor for scaling the force
    CHARACTER(LEN=10), INTENT(IN) :: form           !> format of the structure file (default xsf)
    !CHARACTER(LEN=255), INTENT(IN) :: fname        !> file name
    CHARACTER(*), INTENT(IN) :: fname        !> file name)
    !
    ! -- Local Variables
    integer ::  ios, u0
    character(len=128) :: msg
    CHARACTER(:), ALLOCATABLE :: output

    ! no output of structures
    IF( trim(form) .eq. "none" ) RETURN

    ! ... Open the file with the good extention
    allocate( output, source = TRIM(fname)//"."//TRIM(form) )
    open ( NEWUNIT=u0, FILE=output, FORM='formatted',  STATUS='unknown', IOSTAT=ios, IOMSG=msg )
    if( ios /= 0 ) then
       write(*,*) "ERROR with file:",trim(output)
       write(*,*) trim(msg)
       ! call merr( __FILE__, __LINE__ )
    end if



    ! ... Select the format of the file
    SELECT CASE( form )

    CASE( 'xsf' )
       CALL write_xsf( lat, nat, tau, atm, ityp, force*fscale, u0 )

    CASE( 'xyz')
       CALL write_xyz( lat, nat, tau, ityp, force*fscale, u0, ener )

    CASE DEFAULT
       WRITE (u0,*) " ** LIB::ARTn::WRITE_STRUC::Specified structure format not supported"

    END SELECT


    ! ... Close the file
    CLOSE (UNIT = u0 , STATUS = 'KEEP')
  END SUBROUTINE write_struct

  !> @brief
  !!   A subroutine that read the structure to a file (based on xsf_struct of QE)
  !!   Formatted as in write_struct().
  !!   Return the complete structure contained in the file: type, order, x, f, elt
  !
  !> @param [inout]  nat       number of atoms
  !> @param [inout]  ityp      atom type
  !> @param [inout]  order     atom type
  !> @param [inout]  atm       contains information on atomic types
  !> @param [inout]  tau       atomic positions
  !> @param [inout]  lat       lattice parameters in alat units
  !> @param [inout]  force     list of atomic forces
  !> @param [in]     form      format of the structure file (default xsf)
  !> @param [in]     fname     file name
  MODULE SUBROUTINE read_struct( lat, nat, tau, atm, ityp, force, form, fname )
    !
    IMPLICIT NONE
    ! -- Arguments
    INTEGER,          INTENT(IN) :: nat            !> number of atoms
    INTEGER,          INTENT(INOUT) :: ityp(nat)      !> atom type
    CHARACTER(LEN=3), INTENT(INOUT) :: atm(*)         !> contains information on atomic types
    REAL(DP),         INTENT(INOUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),         INTENT(INOUT) :: lat(3,3)       !> lattice parameters in alat units
    REAL(DP),         INTENT(INOUT) :: force(3,nat)   !> list of atomic forces
    CHARACTER(LEN=10), INTENT(IN) :: form           !> format of the structure file (default xsf)
    CHARACTER(*),     INTENT(IN) :: fname          !> file name
    !
    ! -- Local Variables
    !INTEGER ::  ios
    CHARACTER(:), ALLOCATABLE :: input
    !INTEGER, allocatable :: tmp_type(:), tmp_order(:)

    ! ... Open the file with the good extention
    allocate( input, source = TRIM(fname)//"."//TRIM(form) )

    !allocate( tmp_type, source=ityp )
    !allocate( tmp_order, source=order )

    ! ... Select the format of the file
    SELECT CASE( form )

    CASE( 'xsf' )
       CALL read_xsf( lat, nat, tau, atm, ityp, force, input )

    CASE( 'xyz')
       CALL read_xyz( lat, nat, tau, ityp, force, input )

    CASE( 'none' )
       !! do nothing

    CASE DEFAULT
       write (*,*) " ** LIB::ARTn::READ_STRUC::Specified structure format not supported"
       ! call merr( __FILE__, __LINE__ )

    END SELECT


  END SUBROUTINE read_struct





  !> @brief
  !!   write the position in xsf format
  !
  !> @param [in]  lat       lattice parameters in alat units
  !> @param [in]  nat       number of atoms
  !> @param [in]  tau       atomic positions
  !> @param [in]  atm       contains information on atomic types
  !> @param [in]  ityp      atom type
  !> @param [in]  force     list of atomic forces
  !> @param [in]  ounit     output fortran unit
  !
  SUBROUTINE write_xsf( lat, nat, tau, atm, ityp, force, ounit )
    !
    USE UNITS, only : unconvert_force, B2A
    USE artn_params, only : engine_units, words
    use m_tools, only: parser, to_lower
    IMPLICIT NONE
    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    CHARACTER(LEN=3),   INTENT(IN) :: atm(*)         !> contains information on atomic types
    INTEGER,            INTENT(IN) :: ounit          !> output fortran unit
    REAL(DP),           INTENT(IN) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(IN) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(IN) :: force(3,nat)   !> forces
    ! -- LOCAL VARIABLES
    INTEGER :: na
    !character(:), allocatable :: words(:)
    logical :: lqe

    !
    ! ...Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 )print*, "WRITE_XSF::WE DONT KNOW THE ENGINE"
    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif
    !print*, "WRITE_XSF::", lqe, words(:)

    !
    ! ...The Header
    WRITE(ounit,*) 'CRYSTAL'
    WRITE(ounit,*) 'PRIMVEC'
    !WRITE(ounit,'(2(3F15.9/),3f15.9)') at_angs
    WRITE(ounit,'(2(3F15.9/),3f15.9)') lat*B2A
    WRITE(ounit,*) 'PRIMCOORD'
    WRITE(ounit,*) nat, 1

    !
    ! ...If QE engine we convert the length from Borh to Angstrom
    if( lqe )then
       DO na=1,nat
          WRITE(ounit,'(a3,3x,6f15.9)') atm(ityp(na)), tau(:,na)*B2A, unconvert_force( force(:,na) )
       ENDDO
    else
       DO na=1,nat
          WRITE(ounit,'(a3,3x,6f15.9)') atm(ityp(na)), tau(:,na) , unconvert_force( force(:,na) )
       ENDDO
    endif


  END SUBROUTINE write_xsf

  !> @brief
  !!   read the position in xsf format
  !
  !> @param [out]  lat       lattice parameters in alat units
  !> @param [in]   nat       number of atoms
  !> @param [out]  tau       atomic positions
  !> @param [in]   atm       contains information on atomic types
  !> @param [in]   ityp      atom type
  !> @param [out]  force     list of atomic forces
  !> @param [in]   fname     output file name
  !
  SUBROUTINE read_xsf( lat, nat, tau, atm, ityp, force, fname )
    !
    USE UNITS, only : convert_force, B2A,   &
         convert_length
    use artn_params, only : engine_units, words
    use m_tools, only: parser, to_lower
    implicit none

    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    CHARACTER(LEN=3),   INTENT(OUT) :: atm(*)         !> contains information on atomic types
    REAL(DP),           INTENT(OUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(OUT) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(OUT) :: force(3,nat)   !> forces
    CHARACTER(*),       INTENT(IN) :: fname           !> file name
    ! -- LOCAL VARIABLES
    INTEGER :: na, u0, ios
    !REAL(DP) :: at_angs(3,3)
    !character(:), allocatable :: words(:)
    logical :: lqe

    !
    ! ...Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 )print*, "WRITE_XSF::WE DONT KNOW THE ENGINE"
    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif

    !
    ! ...OPEN/READ the file
    OPEN( newunit=u0, file=fname)

    READ( u0,* )
    READ( u0,* )
    READ( u0,* ) lat(:,1)
    READ( u0,* ) lat(:,2)
    READ( u0,* ) lat(:,3)
    READ( u0,* )
    READ( u0,* ) na, ios

    IF( na /= nat )print*, "* PROBLEM IN READ_XSF:: Different number of atoms", nat, na

    DO na=1,nat
       !iloc = order(na)
       READ( u0,* ) atm(ityp(na)), tau(:,na), force(:,na)
    ENDDO

    CLOSE( u0 )

    !
    ! ...If QE we convert
    IF( lQE )THEN
       lat   = lat*1/B2A
       tau   = tau*1/B2A
    ELSE
       lat = convert_length( lat )
    ENDIF
    force = convert_force( force )


  END SUBROUTINE read_xsf



  !> @brief
  !!   write the position in xyz format
  !
  !> @param [in]  lat       lattice parameters in alat units
  !> @param [in]  nat       number of atoms
  !> @param [in]  tau       atomic positions
  !> @param [in]  ityp      atom type
  !> @param [in]  f         list of atomic forces
  !> @param [in]  ounit     output fortran unit
  !> @param [in]  ener      Energy of actual step
  !
  SUBROUTINE write_xyz( lat, nat, tau, ityp, f, ounit, ener )
    !
    USE UNITS, only : unconvert_force, B2A
    USE artn_params, only : engine_units, words
    use m_tools, only: parser, to_lower
    IMPLICIT NONE
    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    INTEGER,            INTENT(IN) :: ounit          !> output fortran unit
    REAL(DP),           INTENT(IN) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(IN) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(IN) :: f(3,nat)       !> forces
    REAL(DP),           INTENT(IN) :: ener
    ! -- LOCAL VARIABLES
    INTEGER :: na, ios
    !character(:), allocatable :: words(:)
    logical :: lqe

    !
    ! ...Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 )print*, "WRITE_XYX::WE DONT KNOW THE ENGINE"
    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif


    !
    ! ...Header
    WRITE(ounit,*) nat

11  format(a,1x,9(f0.6,1x),a,a,a,f0.9)
10  format(i2,3x,3(f0.9,1x),3x,3(f0.9,1x),3x,i0)

    IF( lQE )THEN
       WRITE(ounit,fmt=11) 'Lattice="',lat(:,:)*B2A,'"', &
            ' properties=species:I:1:pos:R:3:forces:R:3:id:I:1',' energy=',ener
       DO na=1,nat
          WRITE( ounit, fmt=10, IOSTAT=ios ) ityp(na), tau(:,na)*B2A , unconvert_force( f(:,na) ), na
       ENDDO
    ELSE
       WRITE(ounit,fmt=11) 'Lattice="',lat(:,:),'"', &
            ' properties=species:I:1:pos:R:3:forces:R:3:id:I:1',' energy=',ener
       DO na=1,nat
          !! ityp is never permuted it seems. That's ok.
          WRITE( ounit, fmt=10, IOSTAT=ios ) ityp(na), tau(:,na) , unconvert_force( f(:,na) ), na
       ENDDO
    ENDIF

  END SUBROUTINE write_xyz


  !> @brief
  !!   read the position in xyz format
  !
  !> @param [out]  lat       lattice parameters in alat units
  !> @param [in]   nat       number of atoms
  !> @param [out]  tau       atomic positions
  !> @param [in]   ityp      atom type
  !> @param [out]  force     list of atomic forces
  !> @param [in]   fname     output file name
  !
  SUBROUTINE read_xyz( lat, nat, tau, ityp, force, fname )
    !
    USE UNITS, only : convert_force
    implicit none

    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(OUT) :: ityp(nat)      !> atom type
    REAL(DP),           INTENT(OUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(OUT) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(OUT) :: force(3,nat)   !> forces
    CHARACTER(*),       INTENT(IN) :: fname           !> file name

    ! -- LOCAL VARIABLES
    INTEGER :: na, u0, i
    !REAL(DP) :: x(3), f(3)
    lat=0
    OPEN( newunit=u0, file=fname )

    READ( u0,* ) na
    !! we dont read the lattice...
    READ( u0,* )

    IF( na /= nat )print*, "* PROBLEM IN READ_XYZ:: Different number of atoms", nat, na

    DO na=1,nat
       !iloc = order(na)
       READ( u0,* ) ityp(na), tau(:,na), force(:,na), i

       !READ( u0,* ) i, x, f, iloc
       !ityp(iloc) = i
       !order(na) = iloc
       !tau(:,iloc) = x
       !force(:,iloc) = f
    ENDDO
    !> this should be external
    force = convert_force( force )  !> this should be external

    CLOSE( u0 )

  END SUBROUTINE read_xyz



end submodule write_struct_routines
