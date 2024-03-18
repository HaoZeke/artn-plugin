module precision
  implicit none

  private
  public :: DP

  INTEGER, PARAMETER ::  DP = selected_real_kind(14,200)   !< @brief double precision

contains

end module precision
