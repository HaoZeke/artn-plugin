submodule( d_artn_params )set_runparam_routines
  use h_artn_precision
  use m_artn_error
  implicit none

contains


  !! integer
  module function set_runparam_int( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "iartn"        ); iartn        = val
    case( "istep"        ); istep        = val
    case( "iinit"        ); iinit        = val
    case( "iperp"        ); iperp        = val
    case( "ieigen"       ); ieigen       = val
    case( "irelax"       ); irelax       = val
    case( "iover"        ); iover        = val
    case( "nnewchance"   ); nnewchance   = val
    case( "ismooth"      ); ismooth      = val
    case( "nlanc"        ); nlanc        = val
    case( "ifound"       ); ifound       = val
    case( "isearch"      ); isearch      = val
    case( "ifails"       ); ifails       = val
    case( "nperp_step"   ); nperp_step   = val
    case( "nmin"         ); nmin         = val
    case( "nsaddle"      ); nsaddle      = val
    case( "fpush_factor" ); fpush_factor = val
    case( "called_from"  ); called_from  = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_int(): "//name )
    end select
  end function set_runparam_int

  !! real -- has no variables of type real, but should return error
  module function set_runparam_real( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    real(DP), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_real(): "//name )
       associate( x => val ); end associate
    end select
  end function set_runparam_real

  !! bool
  module function set_runparam_bool( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    logical, intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "linit"                 ); linit             = val
    case( "lperp"                 ); lperp             = val
    case( "leigen"                ); leigen            = val
    case( "llanczos"              ); llanczos          = val
    case( "lbasin"                ); lbasin            = val
    case( "lpush_over"            ); lpush_over        = val
    case( "lrelax"                ); lrelax            = val
    case( "in_lanczos_at_min"     ); in_lanczos_at_min = val
    case( "lbackward"             ); lbackward         = val
    case( "lend"                  ); lend              = val
    case( "luser_choose_per_atom" ); luser_choose_per_atom = val
    case( "lserialize_input"      ); lserialize_input  = val
    case( "lserialize_output"     ); lserialize_output = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_bool(): "//name )
    end select
  end function set_runparam_bool

  !! string
  module function set_runparam_str( name, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    character(*), intent(in) :: val
    integer :: ierr
    ierr = 0
    select case( name )
    case( "artn_resume" ); artn_resume = val
    case( "error_message" ); error_message = val
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_str(): "//name )
    end select
  end function set_runparam_str

  !! integer 1D
  module function set_runparam_int1d( name, dim, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    integer, intent(in) :: val(dim)
    integer :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_int1d(): "//name )
       associate( x => val ); end associate
    end select
  end function set_runparam_int1d

  !! real 1D
  module function set_runparam_real1d( name, dim, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: dim
    real(DP), intent(in) :: val(dim)
    integer :: ierr
    ierr = 0
    select case( name )
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_int1d(): "//name )
       associate( x => val ); end associate
    end select
  end function set_runparam_real1d

  !! real 2D
  module function set_runparam_real2d( name, dim1, dim2, val )result(ierr)
    implicit none
    character(*), intent(in) :: name
    integer, intent(in) :: dim1, dim2
    real(DP), intent(in) :: val(dim1, dim2)
    integer :: ierr
    ierr = 0
    select case( name )
    case( "push" )
       if( .not. allocated(push) ) allocate(push, source=val)
       if( dim1 .ne. size(push,1) .or. dim2 .ne. size(push,2) ) then
          !! error wrong size of array val
          ierr = ERR_SIZE
          call err_set( ierr, __FILE__, __LINE__, msg="wrong size for array: "//name)
          return
       end if
       push(:,:) = val(:,:)
    case( "eigenvec" )
       if( .not. allocated(eigenvec) )allocate( eigenvec, source=val)
       if( dim1 .ne. size(eigenvec,1) .or. dim2 .ne. size(eigenvec,2) ) then
          !! error wrong size of array val
          ierr = ERR_SIZE
          call err_set( ierr, __FILE__, __LINE__, msg="wrong size for array: "//name)
          return
       end if
       eigenvec(:,:) = val(:,:)
    case( "push_initial_vector" )
       if( .not. allocated(push_initial_vector) )allocate( push_initial_vector, source=val)
       if( dim1 .ne. size(push_initial_vector,1) .or. dim2 .ne. size(push_initial_vector,2) ) then
          !! error wrong size of array val
          ierr = ERR_SIZE
          call err_set( ierr, __FILE__, __LINE__, msg="wrong size for array: "//name)
          return
       end if
       push_initial_vector(:,:) = val(:,:)
    case default
       ierr = ERR_VARNAME
       call err_set( ierr, __FILE__, __LINE__, msg="unknown name in set_runparam_real2d(): "//name )
    end select
  end function set_runparam_real2d



end submodule set_runparam_routines
