submodule( artn_params )fill_param_step_r
  implicit none
contains
  !---------------------------------------------------------------------------
  !> @brief \b FILL_PARAM_STEP
  !
  !> @par Purpose
  !  ============
  !>   Fill the *_step arrays on which ARTn works on (positions and forces).\n
  !!   For parallel Engine each proc has list from 1 to natproc.
  !!   So there is a global index [1:nat] and local index nproc*[1:natproc]:
  !!   IMPORTANT: All the array are ordered and the POSITIONS ARE NOT CONVERTED.
  !> @verbatim
  !!   array_eng( i ) is ordered such that order( i ) = iat (Ordered)
  !!   => array( iat ) = array_eng( i )
  !!   Then array( order(i) ) = array_eng( i )
  !> @endverbatim
  !
  !> @param[in]  nat      number of atoms
  !! @param[in]  box      box parameters
  !! @param[in]  order    index order of engine
  !! @param[in]  pos      atomic position
  !! @param[in]  etot     energy of the system
  !! @param[in]  force    atomic force
  !! @param[out] error    failure indicator
  !
  MODULE SUBROUTINE Fill_param_step( nat, box, order, ityp,  pos, etot, force, error )
    !
    ! overwrite variables from artn_params:
    !  - natoms
    !  - lat
    !  - etot_step
    !  - types        ORDERED by 'order' argument
    !  - force_step   ORDERED by 'order' argument
    !  - tau_step     ORDERED by 'order' argument
    !  - error
    !  - error_message

    use units, only : convert_energy, convert_force, convert_length

    INTEGER, INTENT(IN) :: nat, order(nat), ityp(nat)
    REAL(DP), INTENT(IN) :: box(3,3), etot, pos(3,nat), force(3,nat)
    LOGICAL, INTENT(OUT) :: error

    !! reset the error message
    error = .false.
    error_message = ""

    !! Error if any index in the order array is out of scope (indicate lost atoms in lammps).
    IF( any(order .lt. 1) .or. &
         any(order .gt. nat)  ) THEN

       !! signal failure
       error = .true.
       error_message = "order array contains invalid values. Should be [1:nat]"
       return
    ENDIF

    !! if any given parameters are NaN, return error
    IF( nat .ne. nat .or. &
         any(order .ne. order) .or. &
         any(box .ne. box) .or. &
         any(pos .ne. pos) .or. &
         any(force .ne. force) .or. &
         etot .ne. etot ) THEN
       error = .true.
       error_message = "Received a NaN value from engine"
       return
    ENDIF


    natoms = nat
    lat = box
    etot_step = convert_energy( etot )
    types(order(:)) = ityp(:)
    force_step(:,order(:)) = convert_force( force(:,:) )
    ! ...IMORTANT: the position is not converted
    tau_step(:,order(:)) = pos(:,:)
    !tau_step(:,order(:)) = convert_length( pos(:,:) )

  END SUBROUTINE Fill_param_step


end submodule fill_param_step_r
