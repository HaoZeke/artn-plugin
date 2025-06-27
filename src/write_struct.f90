submodule( m_artn_report )write_struct_routines
  use h_artn_precision, only: DP
  use m_artn_error
  implicit none
contains

  !> @details
  !! Write current structure to file, where the filename is following the process of pARTn
  !! for saddles: prefix_sad + nsaddle
  !! for minima:  prefix_min + nmin
  !!
  module subroutine write_struc2file( which )
    use d_artn_data, only: natoms, lat, typ_step, tau_step, force_step, etot_step
    use d_artn_params, only: struc_format_out, artn_resume
    use d_artn_params, only: prefix_min, prefix_sad
    use d_artn_params, only: nsaddle, nmin
    use m_artn_tools, only: make_filename
    use m_artn_error, only: err_set, merr
    use h_artn_units, only: unconvert_energy
    implicit none
    character(*), intent(in) :: which

    character(len=256) :: outfile
    real(DP) :: ener

    !! no output
    if( struc_format_out == "none" ) return

    select case( which )
    case( "saddle", "sad" )
       call make_filename( outfile, prefix_sad, nsaddle )
    case( "min1", "min2" )
       call make_filename( outfile, prefix_min, nmin )
    case default
       !! invalid <which>
       call err_set(-1, __FILE__,__LINE__,msg="invalid <which>: "//which )
       call merr(__FILE__,__LINE__,kill=.true.)
    end select

    !! energy in engine units
    ener = unconvert_energy( etot_step )
    ! write to file
    CALL write_struct( lat, natoms, tau_step, typ_step, force_step, &
         ener, 1.0_DP, struc_format_out, outfile )

    ! ...Save the filename to resume
    artn_resume = trim(artn_resume)//" | "//trim(outfile)//'.'//trim(struc_format_out)

  end subroutine write_struc2file



  !> @brief
  !!   A subroutine that writes the structure to a file
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
  MODULE SUBROUTINE write_struct( lat, nat, tau, ityp, force, ener, fscale, form, fname )
    !
    use d_artn_params, only: elements
    IMPLICIT NONE
    ! -- Arguments
    INTEGER,          INTENT(IN) :: nat            !> number of atoms
    INTEGER,          INTENT(IN) :: ityp(nat)      !> atom type
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
    logical :: err
    !character(len=3), dimension(nat) :: atm

    ! no output of structures
    IF( trim(form) .eq. "none" ) RETURN

    ! ... Open the file with the good extention
    allocate( output, source = TRIM(fname)//"."//TRIM(form) )
    open ( NEWUNIT=u0, FILE=output, FORM='formatted',  STATUS='unknown', IOSTAT=ios, IOMSG=msg )
    if( ios /= 0 ) then
       call err_set(ERR_FILE,__FILE__,__LINE__,msg=trim(msg))
       call err_write(__FILE__,__LINE__)
       call merr( __FILE__, __LINE__,kill=.true.)
    end if



    ! ... Select the format of the file
    SELECT CASE( form )

    CASE( 'xsf' )
       !! need elements
       if( .not. allocated(elements)) then
          call err_set(ERR_OTHER, __FILE__, __LINE__, msg="elements array not allocated!")
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
          err = .true.
          return
       end if

       ! CALL write_xsf( lat, nat, tau, atm, ityp, force*fscale, u0, err )
       CALL write_xsf( lat, nat, tau, elements, ityp, force*fscale, u0, err )
       if( err ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if

    CASE( 'xyz')
       CALL write_xyz( lat, nat, tau, ityp, force*fscale, u0, ener, err )
       if( err ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if

    CASE( 'vasp')
       CALL write_vasp( lat, nat, tau, ityp, u0, ener, err )
       if( err ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if

    CASE DEFAULT
       WRITE(msg,"(a,1x,a)") "Specified structure format not supported:",trim(form)
       call err_set(ERR_OTHER,__FILE__,__LINE__,msg=trim(msg))
       call err_write(__FILE__,__LINE__)
       call merr( __FILE__, __LINE__,kill=.true.)

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
    use d_artn_params, only: elements
    IMPLICIT NONE
    ! -- Arguments
    INTEGER,          INTENT(IN) :: nat            !> number of atoms
    INTEGER,          INTENT(INOUT) :: ityp(nat)      !> atom type
    CHARACTER(LEN=*), INTENT(INOUT) :: atm(1:*)         !> contains information on atomic types
    REAL(DP),         INTENT(INOUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),         INTENT(INOUT) :: lat(3,3)       !> lattice parameters in alat units
    REAL(DP),         INTENT(INOUT) :: force(3,nat)   !> list of atomic forces
    CHARACTER(LEN=10), INTENT(IN) :: form           !> format of the structure file (default xsf)
    CHARACTER(*),     INTENT(IN) :: fname          !> file name
    !
    ! -- Local Variables
    !INTEGER ::  ios
    CHARACTER(:), ALLOCATABLE :: input
    logical :: err
    character(len=128) :: msg
    !INTEGER, allocatable :: tmp_type(:), tmp_order(:)

    ! ... Open the file with the good extention
    allocate( input, source = TRIM(fname)//"."//TRIM(form) )

    !allocate( tmp_type, source=ityp )
    !allocate( tmp_order, source=order )

    ! ... Select the format of the file
    SELECT CASE( form )

    CASE( 'xsf' )
       CALL read_xsf( lat, nat, tau, atm, ityp, force, input, err )
       if( err ) then
          call err_write(__FILE__, __LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if

    CASE( 'xyz')
       CALL read_xyz( lat, nat, tau, ityp, force, input, err )
       if( err ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if
    
    CASE( 'vasp')
       CALL read_vasp( lat, nat, tau, force, input, err )
       if( err ) then
          call err_write(__FILE__,__LINE__)
          call merr(__FILE__,__LINE__,kill=.true.)
       end if


    CASE( 'none' )
       !! do nothing

    CASE DEFAULT
       write(msg,"(a,1x,a)") "Specified structure format not supported:",trim(form)
       call err_set(ERR_OTHER,__FILE__,__LINE__,msg=trim(msg))
       call err_write(__FILE__,__LINE__)
       call merr( __FILE__, __LINE__, kill=.true. )

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
  SUBROUTINE write_xsf( lat, nat, tau, atm, ityp, force, ounit, err )
    !
    USE h_artn_units, only : unconvert_force, B2A
    USE d_artn_params, only : engine_units, words
    use m_artn_tools, only: parser, to_lower
    IMPLICIT NONE
    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    CHARACTER(LEN=*),   INTENT(IN) :: atm(1:*)       !> contains information on atomic types
    INTEGER,            INTENT(IN) :: ounit          !> output fortran unit
    REAL(DP),           INTENT(IN) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(IN) :: lat(3,3)       !> lattice parameters in alat units
    REAL(DP),           INTENT(IN) :: force(3,nat)   !> forces
    LOGICAL,            INTENT(out) :: err
    ! -- LOCAL VARIABLES
    INTEGER :: na
    !character(:), allocatable :: words(:)
    logical :: lqe
    character(len=128) :: msg

    err = .false.
    !
    ! ...Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 )then
       write(msg,"(a)") "WE DONT KNOW THE ENGINE_UNITS"
       call err_set(ERR_UNITS,__FILE__, __LINE__, msg=trim(msg) )
       err = .true.
       return
    end if

    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif
    !
    ! ...The Header
    WRITE(ounit,*) 'CRYSTAL'
    WRITE(ounit,*) 'PRIMVEC'
    !
    ! ...If QE engine we convert the length from Bohr to Angstrom
    if( lqe )then
       WRITE(ounit,'(2(3F15.9/),3f15.9)') lat*B2A
       WRITE(ounit,*) 'PRIMCOORD'
       WRITE(ounit,*) nat, 1
       DO na=1,nat
          WRITE(ounit,'(a3,3x,6f15.9)') atm(ityp(na)), tau(:,na)*B2A, unconvert_force( force(:,na) )
       ENDDO
    else
       WRITE(ounit,'(2(3F15.9/),3f15.9)') lat !lattice not convetred in bohr
       WRITE(ounit,*) 'PRIMCOORD'
       WRITE(ounit,*) nat, 1
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
  SUBROUTINE read_xsf( lat, nat, tau, atm, ityp, force, fname, err )
    !
    USE h_artn_units, only : convert_force, B2A,   &
         convert_length
    use d_artn_params, only : engine_units, words
    use d_artn_params, only: elements
    use m_artn_tools, only: parser, to_lower
    implicit none

    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    CHARACTER(LEN=*),   INTENT(OUT) :: atm(1:*)         !> contains information on atomic types
    REAL(DP),           INTENT(OUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(OUT) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(OUT) :: force(3,nat)   !> forces
    CHARACTER(*),       INTENT(IN) :: fname           !> file name
    LOGICAL,            INTENT(OUT) :: err
    ! -- LOCAL VARIABLES
    INTEGER :: na, u0, ios
    !REAL(DP) :: at_angs(3,3)
    !character(:), allocatable :: words(:)
    logical :: lqe
    character(len=128) :: msg


    err = .false.
    if( .not. allocated(elements) ) then
       allocate( elements(1:300), source="XXX")
    end if

    !
    ! ...Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 ) then
       call err_set(ERR_UNITS, __FILE__,__LINE__,msg="THE ENGINE IS UNKNOWN")
       err = .true.
       return
    end if
    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif

    !
    ! ...OPEN/READ the file
    OPEN( newunit=u0, file=fname, iostat=ios, iomsg=msg)
    if( ios /= 0 ) then
       call err_set(ERR_FILE,__FILE__,__LINE__,msg=trim(msg))
       err = .true.
       return
    end if


    READ( u0,* )
    READ( u0,* )
    READ( u0,* ) lat(:,1)
    READ( u0,* ) lat(:,2)
    READ( u0,* ) lat(:,3)
    READ( u0,* )
    READ( u0,* ) na, ios

    IF( na /= nat ) then
       write(msg,"(a,1x,i0,1x,i0)") "PROBLEM IN READ_XSF:: Different number of atoms", nat, na
       call err_set(ERR_OTHER, __FILE__, __LINE__,msg=trim(msg))
       err = .true.
       return
    end IF


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
  SUBROUTINE write_xyz( lat, nat, tau, ityp, f, ounit, ener, err )
    !
    USE h_artn_units, only : unconvert_force, B2A
    USE d_artn_params, only : engine_units, words
    use m_artn_tools, only: parser, to_lower
    IMPLICIT NONE
    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    INTEGER,            INTENT(IN) :: ounit          !> output fortran unit
    REAL(DP),           INTENT(IN) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(IN) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(IN) :: f(3,nat)       !> forces
    REAL(DP),           INTENT(IN) :: ener
    LOGICAL,            INTENT(OUT) :: err
    ! -- LOCAL VARIABLES
    INTEGER :: na, ios
    !character(:), allocatable :: words(:)
    logical :: lqe

    err = .false.
    !
    ! ...Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 )then
       call err_set(ERR_UNITS, __FILE__,__LINE__, msg="WE DONT KNOW THE ENGINE" )
       err = .true.
       return
    end if

    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif


    !
    ! ...Header
    WRITE(ounit,'(i0)') nat

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
  SUBROUTINE read_xyz( lat, nat, tau, ityp, force, fname, err )
    !
    USE h_artn_units, only : convert_force
    implicit none

    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(OUT) :: ityp(nat)      !> atom type
    REAL(DP),           INTENT(OUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(OUT) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(OUT) :: force(3,nat)   !> forces
    CHARACTER(*),       INTENT(IN) :: fname           !> file name
    LOGICAL,            INTENT(OUT) :: err

    ! -- LOCAL VARIABLES
    INTEGER :: na, u0, i, ios
    character(len=128) :: msg
    !REAL(DP) :: x(3), f(3)

    err = .false.
    lat=0
    OPEN( newunit=u0, file=fname, iostat=ios, iomsg=msg )
    if( ios /= 0 ) then
       call err_set(ERR_FILE, __FILE__,__LINE__,msg=trim(msg))
       err = .true.
       return
    end if


    READ( u0,* ) na
    !! we dont read the lattice...
    READ( u0,* )

    IF( na /= nat ) THEN
       write(msg,"(a,1x,i0,1x,i0)") "PROBLEM IN READ_XYZ:: Different number of atoms", nat, na
       call err_set(ERR_OTHER, __FILE__,__LINE__,msg=trim(msg))
       err = .true.
       return
    end IF


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

  SUBROUTINE write_vasp( lat, nat, tau, ityp, ounit, ener, err )
    !USE h_artn_units,       ONLY : unconvert_force, B2A
    USE d_artn_params, ONLY : engine_units, words
    USE m_artn_tools,     ONLY : parser, to_lower
    !
    IMPLICIT NONE
    ! -- ARGUMENTS
    INTEGER,            INTENT(IN) :: nat            !> number of atoms
    INTEGER,            INTENT(IN) :: ityp(nat)      !> atom type
    INTEGER,            INTENT(IN) :: ounit          !> output fortran unit
    REAL(DP),           INTENT(IN) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(IN) :: lat(3,3)       !> lattice parameters in alat units
    REAL(DP),           INTENT(IN) :: ener
    LOGICAL,            INTENT(OUT):: err
    ! -- LOCAL VARIABLES
    INTEGER                        :: na, ios
    INTEGER                        :: nb_spe, isp
    INTEGER                        :: spe(20), nb_isp(20)
    LOGICAL                        :: new
    LOGICAL                        :: lqe

    err = .false.
    !
    ! ... Extract the engine
    lqe = .false.
    na = parser( trim(engine_units), "/", words )
    if( na == 0 )then
       call err_set(ERR_UNITS, __FILE__,__LINE__, msg="WE DONT KNOW THE ENGINE" )
       err = .true.
       return
    end if
    !
    if( na >= 1 )then
       select case( to_lower(words(1)) )
       case( 'qe', 'quantum_espresso' ); lqe = .true.
       case default; lqe = .false.
       end select
    endif
    !
    ! ... Count the number of atoms of each specy (specific to CONTCAR format)

    nb_spe = 1              ! Initialization of the number of species
    nb_isp(nb_spe) = 0      ! Number of species 1 initialized
    spe(nb_spe) = ityp(1)   ! Id of species 1
    do na=1, nat
      do isp=1, nb_spe
         if ( ityp(na) == spe(isp) ) then  ! 
            nb_isp(isp) = nb_isp(isp) + 1
            new = .false.
         else
            new = .true.
         end if
      end do
      if ( new ) then 
         nb_spe = nb_spe + 1
         nb_isp(nb_spe) = 1
         spe(nb_spe) = ityp(na)
      end if 
    end do
    !!
    !! ...Header
    !WRITE(ounit,"(3x,a,f3.15)", iostat=ios) 'generate by ARTN for VASP engine, Energy= ', ener
    !! 
    !WRITE(ounit,'(a)', IOSTAT=ios) '1.000'
    !WRITE(ounit,"(3x,3(f3.15,3x))", IOSTAT=ios) lat(:,1)
    !WRITE(ounit,"(3x,3(f3.15,3x))", IOSTAT=ios) lat(:,2)
    !WRITE(ounit,"(3x,3(f3.15,3x))", IOSTAT=ios) lat(:,3)
    !write(ounit,*) (nb_isp(isp), isp=1, nb_spe)
    !WRITE(ounit,'(a)') 'Cartesian'
    !DO na=1,nat
    !   WRITE( ounit, "(3x,3(f3.15,3x))", IOSTAT=ios ) tau(:,na) 
    !ENDDO
    ! ...Header
    WRITE(ounit,*, iostat=ios) 'generate by ARTN for VASP engine, Energy= ', ener
    ! 
    WRITE(ounit,'(a)', IOSTAT=ios) '1.000'
    WRITE(ounit,*, IOSTAT=ios) lat(:,1)
    WRITE(ounit,*, IOSTAT=ios) lat(:,2)
    WRITE(ounit,*, IOSTAT=ios) lat(:,3)
    write(ounit,*) (nb_isp(isp), isp=1, nb_spe)
    WRITE(ounit,'(a)') 'Cartesian'
    DO na=1,nat
       WRITE( ounit,*, IOSTAT=ios ) tau(:,na) 
    ENDDO

  END SUBROUTINE write_vasp


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
  SUBROUTINE read_vasp( lat, nat, tau, force, fname, err )
    !
    USE h_artn_units, only : convert_force
    implicit none

    ! -- ARGUMENTS
    INTEGER,            INTENT(IN)  :: nat            !> number of atoms
    REAL(DP),           INTENT(OUT) :: tau(3,nat)     !> atomic positions
    REAL(DP),           INTENT(OUT) :: lat(3,3)        !> lattice parameters in alat units
    REAL(DP),           INTENT(OUT) :: force(3,nat)   !> forces
    CHARACTER(*),       INTENT(IN)  :: fname           !> file name
    LOGICAL,            INTENT(OUT) :: err

    ! -- LOCAL VARIABLES
    INTEGER :: na, u0, ios
    character(len=128) :: msg
    !REAL(DP) :: x(3), f(3)
    REAL(DP) :: ABC(3,3), vol
    write(*,*) 'not fully implemented'
    stop

    err = .false.
    lat=0
    OPEN( newunit=u0, file=fname, iostat=ios, iomsg=msg )
    if( ios /= 0 ) then
       call err_set(ERR_FILE, __FILE__,__LINE__,msg=trim(msg))
       err = .true.
       return
    end if
    !
    ! first line is a comment 
    READ( u0,* )
    READ( u0,* ) vol
    READ( u0,* ) ABC(1,1), ABC(1,2), ABC(1,3)
    READ( u0,* ) ABC(2,1), ABC(2,2), ABC(2,3)
    READ( u0,* ) ABC(3,1), ABC(3,2), ABC(3,3)
    READ( u0,* ) 

    IF( na /= nat ) THEN
       write(msg,"(a,1x,i0,1x,i0)") "PROBLEM IN READ_XYZ:: Different number of atoms", nat, na
       call err_set(ERR_OTHER, __FILE__,__LINE__,msg=trim(msg))
       err = .true.
       return
    end IF


    DO na=1,nat
       !iloc = order(na)
       READ( u0,* ) tau(:,na)

    ENDDO
    !> this should be external
    force = convert_force( force )  !> this should be external

    CLOSE( u0 )

  END SUBROUTINE read_vasp


end submodule write_struct_routines
