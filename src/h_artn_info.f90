module h_artn_info

  implicit none

  private
  public :: artn_version
  public :: artn_git_branch
  public :: artn_git_commit
  public :: artn_version_semantic
  public :: artn_gitinfo

#include "artn_version.h"
#include "artn_gitinfo.h"

  character(*), parameter :: artn_version = ARTN_VERSION
  character(*), parameter :: artn_git_branch = ARTN_INFO_GIT_BRANCH
  character(*), parameter :: artn_git_commit = ARTN_INFO_GIT_COMMIT

contains

  !> @details
  !! return the major, minor, patch values of the
  !! version string.
  subroutine artn_version_semantic( major, minor, patch )
    implicit none
    integer, intent(out) :: major, minor, patch

    character(:), allocatable :: vv
    integer :: i, j

    vv=trim(adjustl(artn_version))
    i = index( vv, ".")
    read( vv(1:i-1), *) major

    j = index( vv(i:),".")
    read( vv(i+1:i+j), *) minor

    read( vv(i+1+j+1:), *) patch
  end subroutine artn_version_semantic
  !! C-wrapper to artn_version_semantic
  !!~~~~~~~~~~~~~{.c}
  !! void artn_version_semantic( int *, int *, int *);
  !!~~~~~~~~~~~~~
  subroutine artn_cversion_semantic( major, minor, patch ) bind(C, name="artn_version_semantic")
    use, intrinsic :: iso_c_binding, only: c_int
    integer(c_int), intent(out) :: major, minor, patch
    call artn_version_semantic( major, minor, patch )
  end subroutine artn_cversion_semantic


  !> @details
  !! return string of git branch and commit.
  subroutine artn_gitinfo( str )
    implicit none
    character(:), allocatable, intent(out) :: str
    str = artn_git_branch//":"//artn_git_commit
  end subroutine artn_gitinfo
  !! C-wrapper
  !!~~~~~~~~~~~{.c}
  !! void artn_gitinfo( char** cstr );
  !!~~~~~~~~~~~
  subroutine artn_cgitinfo( cstr )bind(C,name="artn_gitinfo" )
    use, intrinsic :: iso_c_binding, only: c_ptr, c_f_pointer, c_char, c_null_char
    implicit none
    type( c_ptr ), intent(out) :: cstr

    character(:), allocatable :: fstr
    character(len=1, kind=c_char), pointer :: pstr(:)
    integer :: i, n

    call artn_gitinfo(fstr)
    n = len_trim(fstr)
    call c_f_pointer( cstr, pstr, [n+1])
    do i = 1, n
       pstr(i) = fstr(i:i)
    end do
    pstr(n+1) = c_null_char
  end subroutine artn_cgitinfo



end module h_artn_info
