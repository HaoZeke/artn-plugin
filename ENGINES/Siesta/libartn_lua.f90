module libartn_lua

  !< @brief
  !! this module contains functions that are called from lua.
  !! It compiles into the shared library `libartn_lua.so`, which is then
  !! imported into the lua script by: `require("libartn_lua")`

  use iso_c_binding
  use :: lua
  use mpi

  implicit none

  ! interface
  !    subroutine print_stack(lua)bind(C,name="print_stack")
  !      import :: c_ptr
  !      type( c_ptr ), intent(in), value :: lua
  !    end subroutine print_stack
  ! end interface

contains

  !> @brief
  !! this subroutine constructs the interface object to lua,
  !! it needs to exist, and needs to register all functions
  !! from this module that could be called from lua.
  subroutine luaopen_libartn_lua(lua)bind(c)
    type( c_ptr ), intent(in), value :: lua

    ! call lua_register( lua, "set1d", c_funloc(set1d) )
    ! call lua_register( lua, "set2d", c_funloc(set2d) )
    call lua_register( lua, "artn_luasiesta", c_funloc(artn_luasiesta) )
    call lua_register( lua, "artn_step", c_funloc(artn_step) )
    call lua_register( lua, "artn_setup", c_funloc(artn_setup) )
    call lua_register( lua, "printstruc", c_funloc(printstruc) )
    call lua_register( lua, "artn_err_write", c_funloc(artn_err_write))
    call lua_register( lua, "artn_set_param", c_funloc(artn_set_param))
    call lua_register( lua, "artn_set_runparam", c_funloc(artn_set_runparam))
    call lua_register( lua, "artn_get_data", c_funloc(artn_get_data))
    call lua_register( lua, "artn_get_runparam", c_funloc(artn_get_runparam))
    call lua_register( lua, "artn_destroy", c_funloc(artn_destroy))
  end subroutine luaopen_partn_lua



  !! ========== functions visible from lua ========
  !!
  !! all functions visible from lua must have the same prototype shape which is:
  !!
  !! >>> function funcname( lua ) result( nret ) bind(c)
  !! >>>   type( c_ptr ), value, intent(in) :: lua
  !! >>>   integer( c_int ) :: nret
  !! >>>
  !! >>>   ... do things
  !! >>>   ... set nret
  !! >>>
  !! >>> end function funcname
  !!
  !! To call this function from lua, first need to register it in luaopen_* subroutine,
  !! then call from lua like:
  !!
  !!     require("interf_lua")
  !!     m = funcname( arg1, arg2, arg3, ... )    # the number of arguments is not pre-defined
  !!
  !! The communication of data from lua to C/fortran happens through a
  !! "virtual stack", which works like this:
  !! when you call 'm=funcname( arg1, arg2 )' from lua, the variables arg1 and arg2 are put
  !! on the stack. Then in the C/fortran implementation of 'funcname', we have to read this
  !! data from the virtual stack.
  !! In order to send data back to lua at the end, we have to put the data on the 'virtual stack',
  !! and tell the result 'nret' how many variables we are returning.
  !! One array, no matter the size or dimension, counts as one variable.
  !!


  function artn_luasiesta(lua) result(nret)bind(C,name="artn_luasiesta")
    !! call this function from lua like:
    !! ATTENTION: The order of args is super important!
    !!
    !!    lconv,
    !!    lrelax,
    !!    alpha_curr,
    !!    dt_curr,
    !!    nsteppos,
    !!    vel,
    !!    force,
    !!    tau  = artn_luasiesta(
    !!                           vel,
    !!                           nsteppos,
    !!                           dt_curr,
    !!                           dt_init,
    !!                           alpha_curr,
    !!                           alpha_init,
    !!                           if_pos,
    !!                           order,
    !!                           at,
    !!                           tau,
    !!                           ityp,
    !!                           etot,
    !!                           force,
    !!                           nat
    !!                                )
    !!
    !!========================================
    !! This function should work for serial and parallel siesta.
    !!
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer( c_int ) :: nret

    real( c_double ), allocatable :: force(:,:), tau(:,:)
    real( c_double ), allocatable :: displ_vec(:,:), vel(:,:)
    integer, allocatable :: if_pos(:,:)
    integer, allocatable :: ityp(:), order(:), pp(:)
    real( c_double ), dimension(3,3) :: at
    real( c_double ) :: etot
    real( c_double ) :: alpha_init, alpha_curr
    real( c_double ) :: dt_init, dt_curr
    integer :: nat, nsteppos
    integer( c_int ) :: n
    logical :: lrelax, lconv
    integer( c_int ) :: irelax, iconv

    integer :: rank, ierr
    logical :: is_mpi
    integer :: i, j, k, ntyp
    integer :: disp
    character(len=3), allocatable :: atm(:)

    rank = 0
    !! check if we are in mpi
    call mpi_initialized( is_mpi, ierr)
    if( is_mpi ) then
       !! get rank
       call mpi_comm_rank( MPI_COMM_WORLD, rank, ierr )
    end if

    if( rank .eq. 0 ) then
       write(*,*) "enter artn_luasiesta"
       ! call print_stack(lua)
    end if

    !! read last arg, adn remove it from stack. should be nat
    if( rank .eq. 0) then
       n = lua_tonumber(lua, -1)
       call lua_pop(lua, 1)
       nat = int( n )
    end if
    if( is_mpi ) then
       !! distribute nat
       call mpi_barrier(MPI_COMM_WORLD, ierr)
       call mpi_bcast( nat, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    end if

    !! allocate for all cpu:
    allocate( displ_vec(1:3,1:nat),source=0.0_c_double )
    allocate( vel(1:3,1:nat))
    allocate( force(1:3,1:nat) )
    allocate( tau(1:3,1:nat))

    lrelax = .false.

    !! compute on single cpu
    if( rank.eq.0) then

       !! allocate working arrays for rank 0 only

       !! Receive all args from function call, read them from last to first.
       !! The arguments enter on the virtual stack from lua,
       !! after reading each argument, remove it from stack: lua_pop(lua, 1)

       !! read last arg, should be forces
       call receive_2D_arr( lua, 3, nat, force)
       call lua_pop(lua, 1)

       !! read next arg, should be etot
       etot = lua_tonumber(lua, -1)
       call lua_pop(lua,1)

       !! read next arg, atomic types ityp
       allocate( ityp(1:nat))
       call receive_1D_arr_int( lua, nat, ityp)
       call lua_pop(lua, 1)

       !! read next arg, positions tau
       call receive_2D_arr(lua, 3, nat, tau)
       call lua_pop(lua, 1)

       !! read next arg, lattice vectors at
       call receive_2D_arr(lua, 3, 3, at )
       call lua_pop(lua, 1)

       !! read next arg, order of atomic indices
       allocate( order(1:nat))
       call receive_1D_arr_int( lua, nat, order )
       call lua_pop(lua, 1)

       !! read next arg, the atomic coords ifxed by engine if_pos
       allocate( if_pos(1:3,1:nat))
       call receive_2D_arr_int( lua, 3, nat, if_pos )
       call lua_pop(lua, 1)

       !! read next arg, alpha_init
       alpha_init = lua_tonumber( lua, -1)
       call lua_pop(lua, 1)

       !! read next arg, alpha_curr
       alpha_curr = lua_tonumber(lua, -1)
       call lua_pop(lua, 1 )

       !! read next arg, dt_init
       dt_init = lua_tonumber( lua, -1)
       call lua_pop(lua, 1)

       !! read next arg, dt_curr
       dt_curr = lua_tonumber( lua, -1)
       call lua_pop(lua, 1)

       !! read next arg, nsteppos
       n = lua_tonumber( lua, -1)
       call lua_pop(lua, 1)
       nsteppos = int(n)

       ! write(*,*) "here a"
       !! read next arg, velocities from fire
       call receive_2D_arr( lua, 3, nat, vel )
       ! write(*,*) "here"
       call lua_pop(lua, 1)

       !! get atm(*)
       !! we don't know it from siesta, just write X01, X02, etc.
       allocate( pp, source=ityp )
       !! count ntyp
       ntyp = 0
       do i = 1, nat
          if( pp(i) .eq. 0 ) cycle
          k = pp(i)
          ntyp = ntyp + 1
          do j = 1, nat
             if( pp(j) .eq. k ) pp(j) = 0
          end do
       end do
       deallocate( pp )
       allocate( atm(1:ntyp))
       do i = 1, ntyp
          write( atm(i), '(a1,i2.2)') "X",i
       end do

       ! write(*,*) "geenrated atm"
       ! do i = 1, ntyp
       !    write(*,*) i, atm(i)
       ! end do


       write(*,*) "f2 received etot in rydberg",etot
       write(*,*) "f2 got struc:"
       write(*,*) nat
       write(*,*) 'Lattice="',at,'"'
       do i = 1, nat
          write(*,*) ityp(i), tau(:,i), if_pos(:,i)
       end do
       write(*,*) "f2 received force:"
       do i = 1, nat
          write(*,*) i, force(:,i)
       end do

       write(*,*) "f2 received dt: init, curr", dt_init, dt_curr
       write(*,*) "f2 received alpha: init, curr", alpha_init, alpha_curr
       write(*,*) "f2 received nsteppos:",nsteppos
       !!
       !! do something
       !!



       !! call artn_siesta interface
       ! call artn_siesta2( nat, force, etot, ityp, atm, tau, order, at, if_pos, vel, &
       !      dt_curr, alpha_curr, dt_init, alpha_init, nsteppos, lrelax, lconv )
       call artn_siesta2( nat, force, etot, ityp, tau, order, at, if_pos, vel, &
            dt_curr, alpha_curr, dt_init, alpha_init, nsteppos, lrelax, lconv )


       write(*,*) "after move_mode in f2"
       write(*,*) "f2 received dt: init, curr", dt_init, dt_curr
       write(*,*) "f2 received alpha: init, curr", alpha_init, alpha_curr
       write(*,*) "f2 received nsteppos:",nsteppos

       ! lrelax = lconv

       ! write(*,*) "norm2(force)",norm2(force)
       ! if( norm2(force) .lt. 0.11 ) then
       !    ! displ_vec(1,2) = 0.2
       !    ! displ_vec(2,2) = 0.1
       !    ! displ_vec(3,2) = -0.5
       ! else
       !    lrelax = .true.
       ! endif


       deallocate( ityp )
       deallocate( order )
       deallocate( atm )
    end if

    !! distribute result to all cores before returning to lua
    if( is_mpi ) then
       call mpi_barrier(MPI_COMM_WORLD, ierr)
       call mpi_bcast( displ_vec, 3*nat, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
       call mpi_bcast( vel, 3*nat, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
       call mpi_bcast( force, 3*nat, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
       call mpi_bcast( tau, 3*nat, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
       call mpi_bcast( dt_curr, 1, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr )
       call mpi_bcast( alpha_curr, 1, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr )
       call mpi_bcast( nsteppos, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr )
       call mpi_bcast( lrelax, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr )
       call mpi_bcast( lconv, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr )
    end if

    !!=========
    !! put results on 'virtual stack' of lua
    !!
    !! everybody send the same thing: i didn't find a simpler way to do this from lua

    !! first return logical, need to send int as logical value 1/0
    iconv = 0
    if( lconv ) iconv = 1
    call lua_pushboolean(lua, iconv)

    irelax = 0
    if( lrelax ) irelax = 1
    call lua_pushboolean( lua, irelax)

    !! return real
    !! send alpha_curr
    call lua_pushnumber(lua, alpha_curr)

    !! send dt_curr
    call lua_pushnumber(lua, dt_curr)

    !! return integer
    !! send nsteppos
    call lua_pushinteger(lua, int(nsteppos, lua_integer) )

    !! return 2D arrays
    !! send vel
    call send_2D_arr( lua, 3, nat, vel )

    !! send force
    call send_2D_arr( lua, 3, nat, force )

    !! send tau (these change when relaxing back from sad)
    call send_2D_arr( lua, 3, nat, tau )

    !! second output is 2D displ_vec
    ! call send_2D_arr( lua, 3, nat, displ_vec )

    ! if( rank == 0 ) call print_stack(lua)

    !! how many outputs are we returning to lua
    nret = 8

    !! deallocate on all cpu
    deallocate( force )
    deallocate( vel )
    deallocate( displ_vec )
    deallocate( tau )
  end function artn_luasiesta


  function artn_setup(lua)result(nret)bind(C,name="artn_setup")
    !< @brief
    !! call to setup_artn.
    !!
    !! call from lua as:
    !!
    !!~~~~~~~~{.lua}
    !! lerr = artn_luasetup( nat )
    !!~~~~~~~~
    use artn_api2, only: setup_artn
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer( c_int ) :: nret

    integer( c_int ) :: n
    integer :: nat, rank, ierr, comm
    logical :: lerr, is_mpi
    integer(c_int ) :: i_lerr

    rank=0
    call mpi_initialized( is_mpi, ierr )
    if( is_mpi ) then
       !! cannot know which comm is used in siesta, but assume they don't split internally.
       !! get rank, assume we use the whole MPI_COMM_WORLD ....
       !! This is not ideal, but how to get the actual comm from siesta through lua?
       comm = MPI_Comm_World
       call mpi_comm_rank( comm, rank, ierr )
    end if

    !! read last arg, and remove it from stack. should be nat
    if( rank .eq. 0) then
       n = lua_tonumber(lua, -1)
       call lua_pop(lua, 1)
       nat = int( n )
       call setup_artn( nat, lerr )
    end if
    if( is_mpi ) then
       ! distribute lerr
       call mpi_bcast( lerr, 1, MPI_LOGICAL, 0, comm, ierr )
    end if

    !! first return logical, need to send int as logical value 1/0
    i_lerr = 0_c_int
    if( lerr ) i_lerr = 1_c_int
    call lua_pushboolean(lua, i_lerr)

    nret = 1

  end function artn_setup


  function artn_step(lua) result(nret)bind(C,name="artn_step")
    !< @brief
    !! call to artn_step
    !!
    !! Call from lua as:
    !!~~~~~~~~~~~~{.lua}
    !!    lconv,
    !!    displ_vec = artn_step(
    !!                             if_pos,
    !!                             box,
    !!                             pos,
    !!                             ityp,
    !!                             eng_force,
    !!                             etot,
    !!                             nat
    !!                            )
    !!~~~~~~~~~~~~
    !!
    use artn_api2, only: setup_artn
    use artn_api2, only: artn_sstep => artn_step
    implicit none
    type( c_ptr), value, intent(in) :: lua
    integer( c_int ) :: nret

    integer :: rank
    logical :: is_mpi
    integer :: ierr, comm
    integer(c_int) :: n
    integer :: nat
    integer(c_int) :: iconv
    logical :: lconv, lerr
    real(c_double), allocatable :: displ_vec(:,:), force(:,:), pos(:,:)
    real( c_double ), dimension(3,3) :: box
    integer(c_int), allocatable :: if_pos(:,:), ityp(:)
    real( c_double ) :: etot

    rank = 0
    !! check if we are in mpi
    call mpi_initialized( is_mpi, ierr )
    if( is_mpi ) then
       !! get rank, assume we use the whole MPI_COMM_WORLD ....
       !! This is not ideal, but how to get the actual comm from siesta through lua?
       comm = MPI_Comm_World
       call mpi_comm_rank( comm, rank, ierr )
    end if

    ! if( rank .eq. 0 ) write(*,*) "enter artn_luastep"


    !! read last arg, and remove it from stack. should be nat
    if( rank .eq. 0) then
       n = lua_tonumber(lua, -1)
       call lua_pop(lua, 1)
       nat = int( n )
       call setup_artn( nat, lerr )
    end if
    if( is_mpi ) then
       !! distribute nat
       ! call mpi_barrier(comm, ierr)
       call mpi_bcast( nat, 1, MPI_INTEGER, 0, comm, ierr)
    end if


    !! allocate displ array on all cores
    allocate( displ_vec(1:3,1:nat), source=0.0_c_double )

    if( rank .eq. 0 ) then

       !! read next arg: etot
       etot = lua_tonumber(lua, -1)
       call lua_pop(lua,1)
       ! etot = unconvert_energy( etot )

       !! read next arg: forces
       allocate( force(1:3,1:nat))
       call receive_2D_arr( lua, 3, nat, force)
       call lua_pop(lua, 1)
       ! force=unconvert_force(force)

       !! read next arg: atomic types ityp
       allocate( ityp(1:nat))
       call receive_1D_arr_int( lua, nat, ityp)
       call lua_pop(lua, 1)

       !! read next arg: positions pos
       allocate(pos(1:3,1:nat))
       call receive_2D_arr(lua, 3, nat, pos)
       call lua_pop(lua, 1)
       ! pos=unconvert_length(pos)

       !! read next arg: lattice vectors box
       call receive_2D_arr(lua, 3, 3, box )
       call lua_pop(lua, 1)
       ! box=unconvert_length(box)

       !! read next arg: the atomic coords fixed by engine if_pos
       allocate( if_pos(1:3,1:nat))
       call receive_2D_arr_int( lua, 3, nat, if_pos )
       call lua_pop(lua, 1)

       call artn_sstep(nat, etot, force, ityp, pos, box, if_pos, displ_vec, lconv)
       deallocate( force )
       deallocate( ityp )
       deallocate( pos )
       deallocate( if_pos )


       ! displ_vec=convert_length(displ_vec)
    end if

    !! bcast the displ_vec
    if( is_mpi ) then
       call mpi_bcast( lconv, 1, MPI_LOGICAL, 0, comm, ierr )
       call mpi_bcast( displ_vec, 3*nat, MPI_DOUBLE_PRECISION, 0, comm, ierr)
    end if


    !! first return logical, need to send int as logical value 1/0
    iconv = 0
    if( lconv ) iconv = 1
    call lua_pushboolean(lua, iconv)

    call send_2D_arr( lua, 3, nat, displ_vec )

    nret = 2

    deallocate(displ_vec)
    ! if( rank .eq. 0) write(*,*) "exit artn_luastep"
  end function artn_step


  function printstruc( lua )result(nret)bind(C, name="printstruc")
    !! function to print an exyz file conf.xyz
    type( c_ptr), value, intent(in) :: lua
    integer( c_int ) :: nret

    integer :: nat, i, u0
    integer(c_int ) :: n
    integer, allocatable :: typ(:)
    real( c_double ), allocatable :: coords(:,:), force(:,:)
    real( c_double ), dimension(3,3) :: lat
    real( c_double ) :: bohr2ang, unitsev

    open( newunit = u0, file = "conf.xyz", status = "unknown",  position = "append")
    n = lua_tonumber( lua, -1)
    nat = int(n)
    call lua_pop(lua, 1)

    bohr2ang = 0.529177 ! (is 1/units.Ang)
    unitsev=0.073498644351312

    !! receive force
    allocate( force(1:3,1:nat))
    call receive_2d_arr(lua, 3, nat, force)
    call lua_pop(lua,1)

    allocate( coords(1:3,1:nat))
    call receive_2d_arr( lua, 3, nat, coords )
    call lua_pop(lua,1)

    allocate( typ(1:nat))
    call receive_1d_arr_int( lua, nat, typ )
    call lua_pop(lua, 1)

    call receive_2d_arr( lua, 3, 3, lat )
    call lua_pop(lua,1)

    lat = lat*bohr2ang
    coords = coords*bohr2ang
    force = force/unitsev/bohr2ang

    write(u0,*) nat
    write(u0,*) 'Lattice="',lat,'" properties=species:I:1:pos:R:3:forces:R:3:Force_magnitude:R:1'
    do i = 1, nat
       write(u0,*) typ(i), coords(:,i), force(:,i), norm2(force(:,i))
    end do

    close( u0, status = "keep")
  end function printstruc


  function artn_err_write(lua) result(nret) bind(C, name="artn_err_write")
    use m_artn_error
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer(c_int) :: nret
    character(:), allocatable :: file
    integer( c_int ) :: line
    integer :: comm, ierr, rank
    logical :: is_mpi
    rank=0
    call mpi_initialized( is_mpi, ierr )
    if( is_mpi ) then
       !! cannot know which comm is used in siesta, but assume they don't split internally.
       !! get rank, assume we use the whole MPI_COMM_WORLD ....
       !! This is not ideal, but how to get the actual comm from siesta through lua?
       comm = MPI_Comm_World
       call mpi_comm_rank( comm, rank, ierr )
    end if
    nret = 0_c_int
    if( rank .eq. 0 ) then
       line = lua_tonumber(lua, -1 )
       call lua_pop(lua, 1)
       file = lua_tostring( lua, -1 )
       call lua_pop( lua, 1)
       call err_write(file, int(line))
    end if
  end function artn_err_write

  function artn_set_param(lua) result(nret) bind(C,name="artn_set_param")
    !! different rank variables are called differently.
    !!
    !! Call as:
    !! rank=0:
    !!    ierr = artn_set_param( "lanczos_max_size", 20 )
    !!
    !! rank=1:
    !!    ## 3x1 array
    !!    push_ids = {8, 45, 12}
    !!    ierr = artn_set_param( "push_ids", push_ids, 3 )
    !!
    !! rank=2
    !!    ## 3x4 array
    !!    array = { {1.1, 1.2, 1.3}, {2.1, 2.2, 2.3}, {3.1, 3.2, 3.3}, {4.1, 4.2, 4.3} }
    !!    ierr = artn_set_param( "push_init", array, 3, 4 )
    !!
    !! ====
    !! NOTE: this will set values to all mpi ranks
    use d_datainfo
    use m_artn_error
    use h_artn_precision, only: DP
    use artn_api2
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer( c_int ) :: nret

    integer( c_int ) :: nvalues
    character(:), allocatable :: name
    integer :: dtype, drank
    integer :: ierr
    integer :: dim1, dim2
    integer :: intgr
    logical :: bool
    integer( c_int ), allocatable :: int1d(:)
    real( c_double ) :: scalar
    real( c_double ), allocatable :: real2d(:,:)
    character(:), allocatable :: string
    character(256) :: msg

    nret = 1_c_int

    !! get number of values on lua stack
    nvalues = lua_gettop(lua)
    ! write(*,*) "there are N values on stack:", nvalues

    !! take first arg from stack: name, do not pop it
    name = lua_tostring( lua, 1)

    dtype = artn_get_dtype(name)
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       ierr = ERR_VARNAME
       call err_set(ierr, __FILE__, __LINE__, msg="unknown varname in artn_set_param(): "//name )
       call lua_pushinteger(lua, int(ierr, lua_integer) )
       return
    end if

    drank = artn_get_drank(name)

    !! check the number of values on stack, this indicates some error
    !! ine value is the name, one is the value. Other should be associated to dimensions:
    !! rank=1 needs dim1, while rank=2 needs dim1 and dim2
    if( nvalues - 2 /= drank ) then
       ierr = ERR_OTHER
       write(msg,"(a,1x,a,1x,a,1x,i0,a)") "invalid number of arguments for artn_set_param, variable name:",name, &
            "which has rank:",drank,". Need value and dimension info if applicable!"
       call err_set(ierr, __FILE__,__LINE__, msg=trim(msg))
       call err_write(__FILE__,__LINE__)
       call lua_pushinteger(lua, int(ierr, lua_integer) )
       return
    end if


    !! different rank variables expect on lua stack (which is read backward):
    !! rank=0 :: [ value ]
    !! rank=1 :: [ value(dim), dim ]
    !! rank=2 :: [ value(dim1, dim2), dim1, dim2 ]
    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          !! get last arg
          intgr = int(lua_tointeger(lua, -1))
          call lua_pop(lua, 1)
          call artn_set( name, intgr, ierr )
       case( 1 )
          dim1 = int(lua_tointeger(lua, -1))
          call lua_pop(lua, 1)
          allocate( int1d(1:dim1), source=0)
          call receive_1D_arr_int( lua, dim1, int1d )
          call artn_set( name, int1d, ierr )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          scalar = lua_tonumber( lua, -1)
          call lua_pop(lua, 1)
          call artn_set( name, scalar, ierr )
       case( 2 )
          dim2 = int(lua_tointeger( lua, -1 ))
          call lua_pop(lua, 1)
          dim1 = int(lua_tointeger(lua, -1 ))
          call lua_pop(lua, 1)
          allocate( real2d(1:dim1,1:dim2), source=0.0_c_double )
          call receive_2D_arr( lua, dim1, dim2, real2d )
          call artn_set( name, real2d, ierr )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case( ARTN_DTYPE_BOOL )
       select case( drank )
       case( 0 )
          bool = lua_toboolean(lua, -1)
          call lua_pop(lua, 1)
          call artn_set( name, bool, ierr )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case( ARTN_DTYPE_STR )
       select case( drank )
       case( 0 )
          string = lua_tostring(lua, -1 )
          call lua_pop(lua, 1)
          call artn_set(name, string, ierr )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case default
    end select

    !! the variable name should still be on stack, pop it
    call lua_pop(lua, 1)

    !! put ierr value on return stack
    call lua_pushinteger(lua, int(ierr, lua_integer) )

  end function artn_set_param


  function artn_set_runparam(lua) result(nret) bind(C,name="artn_set_runparam")
    !! different rank variables are called differently.
    !!
    !! Call as:
    !! rank=0:
    !!    ierr = artn_set_param( "lanczos_max_size", 20 )
    !!
    !! rank=1:
    !!    ## 3x1 array
    !!    push_ids = {8, 45, 12}
    !!    ierr = artn_set_param( "push_ids", push_ids, 3 )
    !!
    !! rank=2
    !!    ## 3x4 array
    !!    array = { {1.1, 1.2, 1.3}, {2.1, 2.2, 2.3}, {3.1, 3.2, 3.3}, {4.1, 4.2, 4.3} }
    !!    ierr = artn_set_param( "push_init", array, 3, 4 )
    !!
    !! ====
    !! NOTE: this will set values to all mpi ranks
    use d_datainfo
    use m_artn_error
    use h_artn_precision, only: DP
    use d_artn_params, only: set_runparam
    use artn_api2
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer( c_int ) :: nret

    integer( c_int ) :: nvalues
    character(:), allocatable :: name
    integer :: dtype, drank
    integer :: ierr
    integer :: dim1, dim2
    integer :: intgr
    logical :: bool
    integer( c_int ), allocatable :: int1d(:)
    real( c_double ) :: scalar
    real( c_double ), allocatable :: real1d(:), real2d(:,:)
    character(:), allocatable :: string
    character(256) :: msg

    nret = 1_c_int

    !! get number of values on lua stack
    nvalues = lua_gettop(lua)
    ! write(*,*) "there are N values on stack:", nvalues

    !! take first arg from stack: name, do not pop it
    name = lua_tostring( lua, 1)

    dtype = artn_get_dtype(name)
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       ierr = ERR_VARNAME
       call err_set(ierr, __FILE__, __LINE__, msg="unknown varname in artn_set_param(): "//name )
       call lua_pushinteger(lua, int(ierr, lua_integer) )
       return
    end if

    drank = artn_get_drank(name)

    !! check the number of values on stack, this indicates some error
    !! ine value is the name, one is the value. Other should be associated to dimensions:
    !! rank=1 needs dim1, while rank=2 needs dim1 and dim2
    if( nvalues - 2 /= drank ) then
       ierr = ERR_OTHER
       write(msg,"(a,1x,a,1x,a,1x,i0,a)") "invalid number of arguments for artn_set_param, variable name:",name, &
            "which has rank:",drank,". Need value and dimension info if applicable!"
       call err_set(ierr, __FILE__,__LINE__, msg=trim(msg))
       call err_write(__FILE__,__LINE__)
       call lua_pushinteger(lua, int(ierr, lua_integer) )
       return
    end if


    !! different rank variables expect on lua stack (which is read backward):
    !! rank=0 :: [ value ]
    !! rank=1 :: [ value(dim), dim ]
    !! rank=2 :: [ value(dim1, dim2), dim1, dim2 ]
    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          !! get last arg
          intgr = int(lua_tointeger(lua, -1))
          call lua_pop(lua, 1)
          ierr = set_runparam( name, intgr )
       case( 1 )
          dim1 = int(lua_tointeger(lua, -1))
          call lua_pop(lua, 1)
          allocate( int1d(1:dim1), source=0)
          call receive_1D_arr_int( lua, dim1, int1d )
          ierr = set_runparam( name, dim1, int1d )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          scalar = lua_tonumber( lua, -1)
          call lua_pop(lua, 1)
          ierr = set_runparam( name, scalar )
       case( 1 )
          dim1 = int(lua_tonumber(lua,-1))
          call lua_pop(lua, -1)
          allocate(real1d(1:dim1),source=0.0_c_double)
          call receive_1D_arr( lua, dim1, real1d )
          ierr = set_runparam( name, dim1, real1d )
       case( 2 )
          dim2 = int(lua_tointeger( lua, -1 ))
          call lua_pop(lua, 1)
          dim1 = int(lua_tointeger(lua, -1 ))
          call lua_pop(lua, 1)
          allocate( real2d(1:dim1,1:dim2), source=0.0_c_double )
          call receive_2D_arr( lua, dim1, dim2, real2d )
          ierr = set_runparam( name, dim1, dim2, real2d )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case( ARTN_DTYPE_BOOL )
       select case( drank )
       case( 0 )
          bool = lua_toboolean(lua, -1)
          call lua_pop(lua, 1)
          ierr = set_runparam( name, bool )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case( ARTN_DTYPE_STR )
       select case( drank )
       case( 0 )
          string = lua_tostring(lua, -1 )
          call lua_pop(lua, 1)
          ierr = set_runparam( name, string )
       case default
          ierr = ERR_DRANK
          call err_set(ierr, __FILE__,__LINE__,msg="rank not implemented for name: "//name )
       end select

    case default
    end select

    !! the variable name should still be on stack, pop it
    call lua_pop(lua, 1)

    !! put ierr value on return stack
    call lua_pushinteger(lua, int(ierr, lua_integer) )

  end function artn_set_runparam


  function artn_get_data(lua) result(nret) bind(C, name="artn_get_data")
    !! bb = artn_get_data( "name" )
    use d_artn_data, only: get_data
    use d_datainfo
    use m_artn_error
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer(c_int ) :: nret

    character(:), allocatable :: name
    integer :: dtype, drank

    integer :: intgr
    integer :: ierr
    integer, allocatable :: dsize(:)
    integer, allocatable :: int1d(:)
    real( c_double ) :: scalar
    real(c_double), allocatable :: real2d(:,:)
    logical :: bool
    integer :: ibool
    character(:), allocatable :: string
    type( c_ptr ) :: cc

    nret = 1_c_int

    !! take name from first element on stack
    name = lua_tostring(lua, 1)
    !! pop the name, there are no other vars on stack
    call lua_pop(lua, 1)

    dtype = artn_get_dtype(name)
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       call err_set( ERR_VARNAME, __FILE__,__LINE__,msg="unknown variable name in artn_get_runparam: "//name)
       call lua_pushinteger(lua, int(ERR_VARNAME, lua_integer))
       return
    end if

    drank = artn_get_drank(name)
    ierr = artn_get_dsize( name, dsize )
    if( ierr /= 0 ) then
       !! variable is not allocated
       call err_write(__FILE__,__LINE__)
       call lua_pushinteger( lua, int(ierr, lua_integer))
       return
    end if


    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call get_data( name, intgr, ierr )
          call lua_pushinteger(lua, int(intgr, lua_integer))
       case( 1 )
          call get_data( name, int1d, ierr )
          call send_1D_arr_int( lua, dsize(1), int1d )
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call get_data( name, scalar, ierr )
          call lua_pushnumber( lua, real(scalar, lua_number) )
       case( 2 )
          allocate( real2d(1:dsize(1), 1:dsize(2) ) )
          call get_data( name, real2d, ierr )
          call send_2D_arr( lua, dsize(1), dsize(2), real2d )
       end select

    case( ARTN_DTYPE_STR )
       call get_data( name, string, ierr )
       cc = lua_pushstring( lua, string )

    case( ARTN_DTYPE_BOOL )
       call get_data( name, bool, ierr )
       ibool = 0
       if( bool ) ibool = 1
       call lua_pushboolean(lua, ibool )
    end select

  end function artn_get_data

 

  function artn_get_runparam(lua) result(nret) bind(C, name="artn_get_runparam")
    use d_artn_params, only: get_runparam
    use d_datainfo
    use m_artn_error
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer(c_int ) :: nret

    character(:), allocatable :: name
    integer :: dtype, drank

    integer :: intgr
    integer :: ierr
    integer, allocatable :: dsize(:)
    real( c_double ) :: scalar
    real(c_double), allocatable :: real1d(:), real2d(:,:)
    logical :: bool
    integer :: ibool
    character(:), allocatable :: string
    type( c_ptr ) :: cc

    nret = 1_c_int

    !! take name from first element on stack
    name = lua_tostring(lua, 1)
    !! pop the name, there are no other vars on stack
    call lua_pop(lua, 1)

    dtype = artn_get_dtype(name)
    if( dtype == ARTN_DTYPE_UNKNOWN ) then
       call err_set( ERR_VARNAME, __FILE__,__LINE__,msg="unknown variable name in artn_get_runparam: "//name)
       call lua_pushinteger(lua, int(ERR_VARNAME, lua_integer))
       return
    end if

    drank = artn_get_drank(name)
    ierr = artn_get_dsize( name, dsize )
    if( ierr /= 0 ) then
       !! variable is not allocated
       call err_write(__FILE__,__LINE__)
       call lua_pushinteger( lua, int(ierr, lua_integer))
       return
    end if


    select case( dtype )
    case( ARTN_DTYPE_INT )
       select case( drank )
       case( 0 )
          call get_runparam( name, intgr, ierr )
          call lua_pushinteger(lua, int(intgr, lua_integer))
       end select

    case( ARTN_DTYPE_REAL )
       select case( drank )
       case( 0 )
          call get_runparam( name, scalar, ierr )
          call lua_pushnumber( lua, real(scalar, lua_number) )
       case( 1 )
          allocate(real1d(1:dsize(1)))
          call get_runparam( name, real1d, ierr )
          call send_1D_arr( lua, dsize(1), real1d )
       case( 2 )
          allocate( real2d(1:dsize(1), 1:dsize(2) ) )
          call get_runparam( name, real2d, ierr )
          call send_2D_arr( lua, dsize(1), dsize(2), real2d )
       end select

    case( ARTN_DTYPE_STR )
       call get_runparam( name, string, ierr )
       cc = lua_pushstring( lua, string )

    case( ARTN_DTYPE_BOOL )
       call get_runparam( name, bool, ierr )
       ibool = 0
       if( bool ) ibool = 1
       call lua_pushboolean(lua, ibool )
    end select

  end function artn_get_runparam


  ! function artn_get_dtype( name ) result(dtype)
  !   use m_datainfo
  !   character(*), intent(in) :: name
  !   integer :: dtype
  !   dtype = artn_get_dtype(name)
  ! end function artn_get_dtype

  function artn_destroy( lua )result(nret)bind(C,name="artn_destroy")
    use artn_api2, only: artn_ddestroy => artn_destroy
    implicit none
    type( c_ptr ), value, intent(in) :: lua
    integer( c_int ) :: nret
    nret = 0_c_int
    call artn_ddestroy()
  end function artn_destroy


  !! local functions for copying data from and to lua stack
  subroutine receive_1D_arr_int( lua, c, arr )
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: c
    integer, dimension(c), intent(inout) :: arr

    integer :: i
    real( lua_number ) :: m
    integer( c_int ) :: p

    do i = 1, c
       p = lua_rawgeti( lua, -1, int(i, lua_integer) )
       m = lua_tonumber(lua, -1)
       arr(i) = int(m)
       call lua_pop(lua, 1)
    end do

    !do i = 1, c
    !   write(*,*) i, arr(i)
    !end do

  end subroutine receive_1D_arr_int

  subroutine receive_1D_arr( lua, c, arr )
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: c
    real( c_double ), dimension(c), intent(inout) :: arr

    integer :: i
    real( lua_number ) :: m
    integer( c_int ) :: p

    do i = 1, c
       p = lua_rawgeti( lua, -1, int(i, lua_integer) )
       m = lua_tonumber(lua, -1)
       arr(i) = real(m, c_double )
       call lua_pop(lua, 1)
    end do

    !do i = 1, c
    !   write(*,*) i, arr(i)
    !end do

  end subroutine receive_1D_arr

  subroutine receive_2D_arr( lua, c, r, arr )
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: c,r
    real( c_double ), dimension(c,r), intent(inout) :: arr

    integer :: i, j
    real( lua_number ) :: m
    integer( c_int ) :: p

    do i = 1, r
       p = lua_rawgeti( lua, -1, int(i, lua_integer) )
       do j = 1, c
          p = lua_rawgeti( lua, -1, int(j, lua_integer) )
          m = lua_tonumber(lua, -1)
          arr(j,i) = real(m, c_double )
          call lua_pop(lua, 1)
       end do
       call lua_pop(lua, 1)
    end do

    ! do i = 1, r
    !   write(*,*) i, arr(:,i)
    ! end do

    ! call print_stack(lua)
    ! write(*,*) "top", lua_gettop(lua)
  end subroutine receive_2D_arr


  subroutine receive_2D_arr_int( lua, c, r, arr )
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: c,r
    integer, dimension(c,r), intent(inout) :: arr

    integer :: i, j
    real( lua_number ) :: m
    integer( c_int ) :: p

    do i = 1, r
       p = lua_rawgeti( lua, -1, int(i, lua_integer) )
       do j = 1, c
          p = lua_rawgeti( lua, -1, int(j, lua_integer) )
          m = lua_tonumber(lua, -1)
          arr(j,i) = int(m)
          call lua_pop(lua, 1)
       end do
       call lua_pop(lua, 1)
    end do

    ! do i = 1, r
    !   write(*,*) i, arr(:,i)
    ! end do

    ! call print_stack(lua)
    ! write(*,*) "top", lua_gettop(lua)
  end subroutine receive_2D_arr_int

  subroutine send_1D_arr(lua, c, arr)
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: c
    real( c_double ), dimension(c), intent(in) :: arr
    integer(c_int) :: nret

    integer :: i

    call lua_newtable(lua)

    do i = 1, c
       call lua_pushnumber(lua, real(arr(i), lua_number) )
       call lua_rawseti(lua, -2, int(i, lua_integer) )
    end do

    nret = 1
  end subroutine send_1D_arr

  subroutine send_1D_arr_int(lua, c, arr)
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: c
    integer( c_int ), dimension(c), intent(in) :: arr
    integer(c_int) :: nret

    integer :: i

    call lua_newtable(lua)

    do i = 1, c
       call lua_pushinteger(lua, int(arr(i), lua_integer) )
       call lua_rawseti(lua, -2, int(i, lua_integer) )
    end do

    nret = 1
  end subroutine send_1D_arr_int

  subroutine send_2D_arr(lua, c, r, arr)
    type( c_ptr ), intent(in), value :: lua
    integer( c_int ), intent(in) :: r, c
    real( c_double ), dimension(c,r), intent(in) :: arr
    integer(c_int) :: nret

    integer :: i, j

    call lua_newtable(lua)

    do i = 1, r
       call lua_newtable(lua)
       do j = 1, c
          call lua_pushnumber(lua, real(arr(j,i), lua_number) )
          call lua_rawseti(lua, -2, int(j, lua_integer) )
       end do
       call lua_rawseti(lua, -2, int( i, lua_integer) )
    end do

    nret = 1
  end subroutine send_2D_arr


end module libartn_lua



