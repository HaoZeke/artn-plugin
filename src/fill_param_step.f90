submodule( artn_params )fill_param_step_r
  use m_error
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
    !  - typ_step        ORDERED by 'order' argument
    !  - force_step   ORDERED by 'order' argument
    !  - tau_step     ORDERED by 'order' argument
    !  - error
    !  - error_message

    use m_artn_data, only: natoms, lat, tau_step, force_step, etot_step, typ_step, nevalf
    use m_artn_data, only: tau_init
    use units, only : convert_energy, convert_force, convert_length
    use units, only: units_are_set, allocate_var

    implicit none
    INTEGER, INTENT(IN) :: nat, order(nat), ityp(nat)
    REAL(DP), INTENT(IN) :: box(3,3), etot, pos(3,nat), force(3,nat)
    LOGICAL, INTENT(OUT) :: error

    integer :: i, si
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

    !! test if order array has values from 1 to nat
    block
      logical :: test
      do si = 1, nat
         test = .false.
         check: do i = 1, nat
            if( order(i) .eq. si ) test=.true.
         end do check
         if( .not.test )exit
      end do
      if( .not. test ) call merr(__FILE__,__LINE__,kill=.true.)
    end block



    !! if any given parameters are NaN, return error
    IF( nat .ne. nat .or. &
         any(order .ne. order) .or. &
         any(box .ne. box) .or. &
         any(pos .ne. pos) .or. &
         any(force .ne. force) .or. &
         etot .ne. etot ) THEN
       error = .true.
       error_message = "Received a NaN value from engine"
       write(*,*) nat .ne. nat, any(order.ne.order), any(box.ne.box),any(pos.ne.pos),any(force.ne.force),etot.ne.etot
       return
    ENDIF

    if( .not. units_are_set) then
       error = .true.
       call err_set(ERR_UNITS,__FILE__,__LINE__,msg="units are not set!")
       call err_write(__FILE__,__LINE__)
       call merr(__FILE__,__LINE__,kill=.true.)
       return
    end if



    !! fill step data from engine
    natoms = nat
    lat = box
    etot_step = convert_energy( etot )
    nevalf = istep

    !! check allocation
    call allocate_var( nat, typ_step, 0 )
    typ_step(order(:)) = ityp(:)
    ! typ_step = ityp

    call allocate_var( 3, nat, force_step, 0.0_DP )
    force_step(:,order(:)) = convert_force( force(:,:) )
    ! force_step = convert_force( force(:,:) )

    ! ...IMORTANT: the position is not converted
    call allocate_var( 3, nat, tau_step, 0.0_DP )
    tau_step(:,order(:)) = pos(:,:)
    ! tau_step = pos


  END SUBROUTINE Fill_param_step


end submodule fill_param_step_r
