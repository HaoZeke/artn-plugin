

#ifdef DEBUG

module artn_debug

  !! use the -DDEBUG flag in makefile to activate this module

  use units
  implicit none

  private
  public check_arg

  !!
  !! internal definitions, avoid huge(1.0_DP) and tiny(1.0_DP) because would like to catch
  !! also cases where it is not on border of precision!
  real, parameter :: huge_real = 1e20
  real, parameter :: tiny_real = 1e-20
  integer, parameter :: huge_int = huge(1)


  !! public routine to check values of an argument, if they are outside of expected range, or NaN
  !!
  !!   subroutine check_arg( "var_name", var_value, ierr, err_msg )
  !!
  !! example call to check the forces array:
  !!
  !! #ifdef DEBUG
  !!   block
  !!     use artn_debug
  !!     integer :: ierr
  !!     character(len=256) :: err
  !!     call check_arg( "force", force, ierr, err )
  !!     if( ierr .ne. 0 ) then
  !!        write(*,*) trim(err)
  !!        write(*,*) "STOPPING"
  !!        flush(5)
  !!        stop
  !!   end block
  !! #endif

  interface check_arg
     module procedure ::&
          check_arg_int, &
          check_arg_real, &
          check_arg_int1d, &
          check_arg_int2d, &
          check_arg_real2d
  end interface check_arg

contains

  !! The checks done: depending on ehich variable ...
  !!  1) value is lower than expected:
  !!         if( abs(val) < min_expected ) ierr = -1
  !!  2) value is larger than expected: NOTE this also tests for Infinity
  !!         if( abs(val) > max_expected ) ierr = -2
  !!  3) value is NaN:
  !!         if( val /= val ) ierr = -3

  !! obtain error message from error code
  function get_err_msg( ierr, name )result(err_msg)
    integer, intent(in) :: ierr
    character(*), intent(in) :: name
    character(:), allocatable :: err_msg
    character(len=256) :: str

    write(str,*) ">>>>> WARNING::",trim(name)
    select case( ierr )
    case( -1 )
       write(str, *) trim(str), ":value lower than expected:"
    case( -2 )
       write(str, *) trim(str), ":value larger than expected:"
    case( -3 )
       write(str, *) trim(str), ":value NaN:"
    end select
    allocate( err_msg, source=trim(str) )
  end function get_err_msg

  !! integer variables
  subroutine check_arg_int( name, val, ierr, err_str )
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer, intent(out) :: ierr
    character(len=256), intent(out) :: err_str

    ierr = 0
    err_str = ''

    select case( name )
    case( "nat", "nsteppos", "istep", "ninit" )
       !! between 0 and huge
       if( val .lt. 0 ) ierr = -1
       if( val .gt. huge_int ) ierr = -2
       if( val .ne. val ) ierr = -3

    case( "disp", "DISP" )
       !! between 0 and 8
       if( val .lt. 0 ) ierr = -1
       if( val .gt. 8) ierr = -2
       if( val .ne. val ) ierr = -3

    case default
       ierr = -9
       write(err_str,*) "error in check_arg routine :: unknown name ::",name
    end select

    write( err_str, *) trim(err_str), get_err_msg(ierr, name)

  end subroutine check_arg_int

  subroutine check_arg_real( name, val, ierr, err_str )
    character(*), intent(in) :: name
    real(DP), intent(in) :: val
    integer, intent(out) :: ierr
    character(len=256), intent(out) :: err_str

    ierr = 0
    err_str = ''

    select case( name )
    case( "etot", "etot_eng", "alpha_init", "alpha", "lowest_eigval" )
       !! can be zero
       ! if( val .lt. 0 ) ierr = -1
       if( abs(val) .gt. huge_real ) ierr = -2
       if( val .ne. val ) ierr = -3

    case( "dt_curr", "dt_init" )
       !! cannot be zero
       if( abs(val) .lt. tiny_real ) ierr = -1
       if( abs(val) .gt. huge_real ) ierr = -2
       if( val .ne. val ) ierr = -3

    case default
       ierr = -9
       write(err_str,*) "error in check_arg routine :: unknown name ::",name
    end select
    write( err_str, *) trim(err_str), get_err_msg(ierr, name)

  end subroutine check_arg_real

  subroutine check_arg_int1d( name, val, ierr, err_str )
    !! can be several errors at the same time, concatenate errors
    character(*), intent(in) :: name
    integer, intent(in) :: val(:)
    integer, intent(out) :: ierr
    character(len=256), intent(out) :: err_str

    ierr = 0
    err_str = ""

    select case( name )
    case( "order", "ityp" )
       if( any(val .lt. 0)) then
          ierr = -1
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       endif

       if( any(val .gt. huge_int) ) then
          ierr = -2
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

       if( any(val .ne. val )) then
          ierr = -3
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

    case default
       ierr = -9
       write(err_str,*) "error in check_arg routine :: unknown name ::",name
    end select

  end subroutine check_arg_int1d

  subroutine check_arg_int2d( name, val, ierr, err_str )
    !! can be several errors at the same time, concatenate errors
    character(*), intent(in) :: name
    integer, intent(in) :: val(:,:)
    integer, intent(out) :: ierr
    character(len=256), intent(out) :: err_str

    ierr = 0
    err_str = ""

    select case( name )
    case( "if_pos" )
       !! can be strictly 0 or 1
       if( any(val .lt. 0)) then
          ierr = -1
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

       if( any(val .gt. 1) ) then
          ierr = -2
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

       if( any(val .ne. val )) then
          ierr = -3
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

    case default
       ierr = -9
       write(err_str,*) "error in check_arg routine :: unknown name ::",name
    end select

  end subroutine check_arg_int2d

  subroutine check_arg_real2d( name, val, ierr, err_str )
    !! can be several errors at the same time, concatenate errors
    character(*), intent(in) :: name
    real(DP), intent(in) :: val(:,:)
    integer, intent(out) :: ierr
    character(len=256), intent(out) :: err_str

    ierr = 0
    err_str = ''

    select case( name )
    case( "force", "vel", "tau", "at", "displ_vec", "push", "eigenvec" )
       !! can have values close to zero

       ! if( any(abs(val) .lt. tiny_real) ) then
       !   ierr = -1
       !   write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       ! endif

       if( any(abs(val) .gt. huge_real) ) then
          ierr = -2
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

       if( any(val .ne. val) ) then
          ierr = -3
          write( err_str, *) trim(err_str), get_err_msg(ierr, name)
       end if

    case default
       ierr = -9
       write(err_str,*) "error in check_arg routine :: unknown name ::",name
    end select

  end subroutine check_arg_real2d

end module artn_debug

#endif
