module precision
  implicit none

  private
  public :: DP, &
       ARTN_DTYPE_UNKNOWN, &
       ARTN_DTYPE_INT, &
       ARTN_DTYPE_REAL, &
       ARTN_DTYPE_BOOL, &
       ARTN_DTYPE_STR

  INTEGER, PARAMETER ::  DP = selected_real_kind(14,200)   !< @brief double precision


  !! artn data type encoders
  integer, parameter :: &
       ARTN_DTYPE_UNKNOWN = -1, &
       ARTN_DTYPE_INT     = 1, &
       ARTN_DTYPE_REAL    = 2, &
       ARTN_DTYPE_BOOL    = 3, &
       ARTN_DTYPE_STR     = 4

contains

end module precision
