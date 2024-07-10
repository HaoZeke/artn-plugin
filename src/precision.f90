module precision
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none

  private
  public :: DP

  INTEGER, PARAMETER ::  DP = real64   !< @brief equivalent to c_double precision

end module precision
