module partn_lua

  !! this module contains functions that are called from lua.
  !! It compiles into the shared library `partn_lua.so`, which is then
  !! imported into the lua script by: `require("partn_lua")`

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

  !! this subroutine constructs the interface object to lua,
  !! it needs to exist, and needs to register all functions
  !! from this module that could be called from lua.
  subroutine luaopen_partn_lua(lua)bind(c)
    type( c_ptr ), intent(in), value :: lua

    ! call lua_register( lua, "set1d", c_funloc(set1d) )
    ! call lua_register( lua, "set2d", c_funloc(set2d) )
    call lua_register( lua, "artn_luasiesta", c_funloc(artn_luasiesta) )
    call lua_register( lua, "printstruc", c_funloc(printstruc) )
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
    allocate( displ_vec(1:3,1:nat),source=0.0)
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

       write(*,*) "geenrated atm"
       do i = 1, ntyp
          write(*,*) i, atm(i)
       end do


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
       call artn_siesta2( force, etot, nat, ityp, atm, tau, order, at, if_pos, vel, &
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


  function printstruc( lua )result(nret)bind(C, name="printstruc")
    !! function to print an exyz file conf.xyz
    type( c_ptr), value, intent(in) :: lua
    integer( c_int ) :: nret

    integer :: nat, i, u0
    integer(c_int ) :: n
    integer, allocatable :: typ(:)
    real( c_double ), allocatable :: coords(:,:), force(:,:)
    real( c_double ), dimension(3,3) :: lat
    real( c_double ) :: bohr2ang

    open( newunit = u0, file = "conf.xyz", status = "unknown",  position = "append")
    n = lua_tonumber( lua, -1)
    nat = int(n)
    call lua_pop(lua, 1)

    bohr2ang = 0.529177

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

    write(u0,*) nat
    write(u0,*) 'Lattice="',lat,'" properties=species:I:1:pos:R:3:forces:R:3:Force_magnitude:R:1'
    do i = 1, nat
       write(u0,*) typ(i), coords(:,i), force(:,i), norm2(force(:,i))
    end do

    close( u0, status = "keep")
  end function printstruc




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


end module partn_lua



