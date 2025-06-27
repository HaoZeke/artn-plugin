submodule( d_artn_params ) check_params

  use d_artn_params
  implicit none

contains

  module subroutine check_d_artn_params( nat, error )
    !! check for coherence among the current artn parameters
    use m_artn_option, only: nperp_limitation_init
    use m_artn_error
    implicit none

    integer, intent(in) :: nat
    logical, intent(out) :: error

    character(len=256) :: msg
    integer :: ierr

    error = .false.

    if( push_mode == "rad" .or. push_mode=="list") then
       !
       !! push_ids were not specified
       if( .not. allocated(push_ids) ) then
          error = .true.
          write(msg,"(a,1x,a,1x,a)") "push_mode=",trim(push_mode),"needs a list of push_ids!"
          error_message = trim(error_message)//new_line("a")//trim(msg)
          call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
          return
       end if
       !
       !! no push_ids set
       IF( sum(push_ids) == 0 ) then
          error = .true.
          write(msg,"(a,a,a)") "push_mode =",trim(push_mode), " needs a list of atoms: define push_ids keyword "
          error_message = trim(error_message)//new_line("a")//trim(msg)
          call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
          return
       end IF
       !
       !! some index in push_ids > nat
       if( any(push_ids .gt. nat) ) then
          error = .true.
          write(msg,"(a,1x,i0)") "ERROR:push_ids cannot contain indices larger than value of natoms =",nat
          error_message = trim(error_message)//new_line("a")//trim(msg)
          call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
          return
       end if
       !
    endif

    !! check if integers are positive, within bounds

    !! lanczos_max_size must be > lanczos_min_size
    if( lanczos_max_size .le. lanczos_min_size ) then
       error = .true.
       write(msg,"(a,1x,i0,',',1x,i0)") "lanczos_max_size must be > lanczos_min_size! Values min, max:", &
            lanczos_min_size, lanczos_max_size
       error_message = trim(error_message)//new_line("a")//trim(msg)
       call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
       return
    end if

    !! check if real values are reasonable

    !! check if arrays are ok

    !!-----
    !! allocatable user params user params:
    !! the user params can remain unallocated if they are not set by set_param() and
    !! are also not read from input file. Check the allocation status here,
    !! and if they are allocated, check that the size is as expected.
    !!
    !! check push_ids, expected (1:nat)
    if( .not.allocated(push_ids) ) then
       allocate( push_ids(1:nat), source = 0)
    else
       !! push_ids has always contiguous values, so if the allocated array
       !! is smaller than nat, we copy the values and resize it to size=nat
       call resize1d_int( nat, push_ids, 0 )
    end if

    !! check push_add_const, expected (1:4, 1:nat)
    call checksize2d( push_add_const, 4, nat, ierr, msg )
    if( ierr /= 0 ) then
       call err_set( ierr, __FILE__, __LINE__, msg="push_add_const "//trim(msg))
       return
    end if

    !! push
    call checksize2d( push, 3, nat, ierr, msg )
    if( ierr /= 0 ) then
       call err_set( ierr, __FILE__, __LINE__, msg="push "//trim(msg))
       return
    end if

    !! eigenvec
    call checksize2d( eigenvec, 3, nat, ierr, msg )
    if( ierr /= 0 ) then
       call err_set( ierr, __FILE__, __LINE__, msg="eigenvec "//trim(msg))
       return
    end if

    !!:NS: nperp_limitation has to be allocated becasue the namelist read... 
    !! nperp_limitation, expected (1:any)
    if( .not. allocated(nperp_limitation)) then
       allocate( nperp_limitation(1:10), source=-2)
       !! nperp_limitation initialize
       call nperp_limitation_init( lnperp_limitation )
    elseif( ANY(nperp_limitation == -2) )then
       call nperp_limitation_init( lnperp_limitation )
    end if




    !! check on characters
    !! converge_property possible: maxval, norm
    block
      character(*), dimension(*), parameter :: chr = &
           [character(len=6) :: "maxval", "norm" ]
      call check_str( "converge_property", chr, error, msg )
      if( error ) then
         call err_caller( __FILE__, __LINE__)
         error_message = trim(error_message)//new_line("a")//trim(msg)
         return
      end if
    end block

    !! struc_format_out possible: xsf, xyz, none
    block
      character(*), dimension(*), parameter :: chr = &
           [character(len=4) :: "xsf", "xyz", "vasp", "none" ]
      call check_str( "struc_format_out", chr, error, msg )
      if( error ) then
         call err_caller( __FILE__, __LINE__)
         error_message = trim(error_message)//new_line("a")//trim(msg)
         return
      end if
    end block

    !! engine_units possible values: qe, quantum_espresso, lammps/real, lammps/metal, lammps/lj, siesta
    block
      character(*), dimension(*), parameter :: chr = &
           [character(len=16) :: "qe", "quantum_espresso", "lammps/metal", "lammps/real", "lammps/lj", "siesta", "vasp" ]
      call check_str( "engine_units", chr, error, msg )
      if( error ) then
         call err_caller( __FILE__, __LINE__)
         error_message = trim(error_message)//new_line("a")//trim(msg)
         return
      end if
    end block


    !! incompatible input combinations::

    !! >> lpush_final = .false. && lmove_nextmin = .true.
    if( lmove_nextmin .and. .not.lpush_final ) then
       error = .true.
       msg = "cannot use lmove_nextmin without lpush_final!"
       error_message = trim(error_message)//new_line("a")//trim(msg)
       call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
       return
    end if

    !! >> push_add_const for index which is not in push_ids
    block
      integer :: i
      real(DP) :: rdum
      do i = 1, nat
         rdum = norm2( push_add_const(1:3,i) )
         if( rdum .gt. 1.0e-6_DP .and. .not.any(push_ids == i) ) then
            error = .true.
            write(msg,"(a,1x,i0)") "cannot specify push_add_const for index not present in push_ids:",i
            error_message = trim(error_message)//new_line("a")//trim(msg)
            call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
            return
         end if
      end do
    end block

    !! >> push_add_const with push_mode == "file"
    if( trim(push_mode) == "file" &
         .and. any(abs(push_add_const) > 1.0e-6_DP)) then
       error = .true.
       msg = "push_add_const cannot be used with push_mode='file'"
       error_message = trim(error_message)//new_line("a")//trim(msg)
       call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
       return
    end if


    !! struc_format_out=xsf needs elements to be allocated
    if( trim(struc_format_out) == "xsf" .and. .not. allocated(elements) ) then
       error = .true.
       msg = "xsf format needs the elements array specified!"
       error_message = trim(error_message)//new_line("a")//trim(msg)
       call err_set( ERR_OTHER, __FILE__, __LINE__, msg=trim(msg) )
       return
    end if


    !! check size of push and eigenvec
    if( allocated( push ) ) then
       if( size(push,1)/=3 .or. size(push,2)/= nat) then
          error = .true.
          write(msg,'(a,1x,i0,",",i0,1x,a,i0,",",i0)') &
               "Wrong size of push vector! Expected:",3,nat,"got:",size(push,1),size(push,2)
          call err_set( ERR_SIZE, __FILE__,__LINE__, msg=trim(msg))
          return
       end if
    end if
    if( allocated( eigenvec ) ) then
       if( size(eigenvec,1)/=3 .or. size(eigenvec,2)/= nat) then
          error = .true.
          write(msg,'(a,1x,i0,",",i0,1x,a,i0,",",i0)') &
               "Wrong size of eigenvec vector! Expected:",3,nat,"got:",size(eigenvec,1),size(eigenvec,2)
          call err_set( ERR_SIZE, __FILE__,__LINE__, msg=trim(msg))
          return
       end if
    end if

    ! write(*,*) allocated(push), size(push,1), size(push,2)

  end subroutine check_d_artn_params




  !! local routine
  subroutine check_str( name, val, error, errmsg )
    !! check if string variable with <name> has any of the values from the array "val"
    !! If not, then return error=.true. with a message.
    use m_artn_error, only: err_set, ERR_VARNAME
    implicit none
    character(*), intent(in) :: name
    character(*), intent(in) :: val(:)
    logical,      intent(out) :: error
    character(256), intent(out) :: errmsg

    integer :: i, n
    character(256) :: actual_val

    error = .true.
    errmsg=""
    n = size(val,1)

    !! find actual value of variable <name>
    select case( name )
    case( "converge_property" ); actual_val = trim(converge_property)
    case( "struc_format_out"); actual_val = trim(struc_format_out)
    case( "engine_units" ); actual_val = trim(engine_units)
    case default
       write(*,*) "unknown name in check_str:",trim(name)
       write(*,*) "at file, line: ",__FILE__, __LINE__
       stop
    end select

    !! loop through val array, the actual value of <name> should be equal
    !! to one of them. If not, error.
    do i = 1, n
       if( trim(actual_val) .eq. trim(val(i)) ) error=.false.
    end do

    if( error ) then
       write(errmsg, "(a,1x,a,1x,a,a,a,*(1x,a,:,','))") &
            name,"has unsupported value:", trim(actual_val), new_line("a"),&
            "Possible values are:",(trim(val(i)),i=1,n)
       call err_set( ERR_VARNAME, __FILE__, __LINE__, msg=trim(errmsg))
    end if

  end subroutine check_str


  subroutine resize1d_int( dim, array, src )
    !! resize 1d array to (dim). If array is allocated, copy the common
    !! elements into the new array after resize.
    implicit none
    integer, intent(in) :: dim
    integer, allocatable, intent(inout) :: array(:)
    integer, intent(in) :: src

    integer, allocatable :: tmp(:)
    integer :: size1, i1

    !! array is allocated, check its size
    !! keep original size
    size1 = size(array, 1)
    !! check against wanted dimensions
    if( size1 /= dim ) then
       !! make tmp copy
       call move_alloc( array, tmp )
       !! allocate array to the desired dimension
       allocate(array(1:dim), source=src)
       !! copy the common elements to new array
       i1 = min(size1, dim)
       array(1:i1) = tmp(1:i1)
       !! deallocate tmp
       deallocate( tmp )
    end if
  end subroutine resize1d_int


  subroutine checksize2d( array, dim1, dim2, ierr, msg )
    !! check if array is allocated, and has size (dim1,dim2).
    use m_artn_error, only: ERR_SIZE
    implicit none
    real(DP), allocatable, intent(inout) :: array(:,:)
    integer, intent(in) :: dim1, dim2
    integer, intent(out) :: ierr
    character(len=256), intent(out) :: msg
    integer :: size1, size2
    ierr=0; msg=""
    if( .not. allocated(array)) then
       allocate( array(1:dim1, 1:dim2), source=0.0_DP)
    else
       size1=size(array, 1); size2=size(array, 2)
       !! check size1
       if( size1 .ne. dim1 ) then
          ierr = ERR_SIZE
          msg = "array has wrong size in dim1, got:"
          write(msg,"(a,1x,i0,1x,a,1x,i0)") trim(msg),size1,"expected:",dim1
          return
       end if
       !! check size2
       if( size2 .ne. dim2 ) then
          ierr = ERR_SIZE
          msg = "array has wrong size in dim2, got:"
          write(msg,"(a,1x,i0,1x,a,1x,i0)") trim(msg),size2,"expected:",dim2
          return
       end if
    end if

  end subroutine checksize2d


end submodule check_params
