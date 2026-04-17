submodule(d_artn_params)fill_param_step_r
  use m_artn_error
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
  MODULE function Fill_param_step( nat, box, order, ityp, pos, etot, force ) result(ierr)
    !
    ! overwrite variables from d_artn_params:
    !  - natoms
    !  - lat
    !  - etot_step
    !  - typ_step        ORDERED by 'order' argument
    !  - force_step   ORDERED by 'order' argument
    !  - tau_step     ORDERED by 'order' argument

    use d_artn_data, only: natoms, lat, tau_step, force_step, etot_step, typ_step, nevalf
    use d_artn_data, only: eigen_step
    use h_artn_units, only : convert_energy, convert_force, convert_length
    use h_artn_units, only: units_are_set, allocate_var, is_nan, is_inf

    implicit none
    INTEGER, INTENT(IN) :: nat, order(nat), ityp(nat)
    REAL(DP), INTENT(IN) :: box(3,3), etot, pos(3,nat), force(3,nat)
    integer :: ierr

    character(len=32) :: varname

    ierr = 0

    !! Error if any index in the order array is out of scope (indicate lost atoms in lammps).
    IF( any(order .lt. 1) .or. &
         any(order .gt. nat) ) THEN
       ! signal error
       ierr = ARTN_ERROR
       call err_set( ierr, __FILE__,__LINE__, &
            msg="order array contains invalid values. Should be contiguous on range [1:nat]")
       return
    ENDIF

#ifdef DEBUG
    !! test if order array has values from 1 to nat
    block
      logical :: test
      integer :: si
      test = .false.
      do si = 1, nat
         test = .false.
         check: do i = 1, nat
            if( order(i) .eq. si ) test=.true.
         end do check
         if( .not.test )exit
      end do
      if( .not. test ) call merr(__FILE__,__LINE__,kill=.true.)
    end block
#endif


    !! if any given parameters are NaN, return error
    varname=""
    if( is_nan(nat)        .or. is_inf(nat)        ) varname = trim(varname)//":nat"
    if( any(is_nan(box))   .or. any(is_inf(box))   ) varname = trim(varname)//":box"
    if( any(is_nan(order)) .or. any(is_inf(order)) ) varname = trim(varname)//":order"
    if( any(is_nan(pos))   .or. any(is_inf(pos))   ) varname = trim(varname)//":pos"
    if( any(is_nan(force)) .or. any(is_inf(force)) ) varname = trim(varname)//":force"
    if( is_nan(etot)       .or. is_inf(etot)       ) varname = trim(varname)//":etot"
    if( trim(varname) .ne. "" ) then
       ! signal error
       ierr = ARTN_ERROR
       call err_set(ierr, __FILE__, __LINE__, &
            msg="Received NaN or Inf form engine in variable(s)"//trim(varname) )
       return
    end if



    if( .not. units_are_set ) then
       ierr = ARTN_ERROR
       call err_set(ierr,__FILE__,__LINE__, &
            msg="engine_units are not set (or make_units() was never called)")
       return
    end if



    !! fill step data from engine
    natoms = nat
    lat = box
    etot_step = convert_energy( etot )
    nevalf = istep

    !! check allocation
    ! call allocate_var( nat, typ_step, src_val=0 )
    call allocate_var( nat, typ_step  )
    typ_step(order(:)) = ityp(:)
    ! typ_step = ityp

    ! call allocate_var( 3, nat, force_step, src_val=0.0_DP )
    call allocate_var( 3, nat, force_step )
    force_step(:,order(:)) = convert_force( force(:,:) )
    ! force_step = convert_force( force(:,:) )

    ! ...IMORTANT: the position is not converted
    ! call allocate_var( 3, nat, tau_step, src_val=0.0_DP )
    call allocate_var( 3, nat, tau_step )
    tau_step(:,order(:)) = pos(:,:)
    ! tau_step = pos

    !! allocate array for eigen_step, the value is filled by lanczos
    ! call allocate_var( 3, nat, eigen_step, src_val=0.0_DP )
    call allocate_var( 3, nat, eigen_step )

  END function Fill_param_step


end submodule fill_param_step_r
