dnl ## Search for package in first argument of the call, in the file
dnl ##   $LAMMPS_PATH/lmpinstalledpkgs.h
dnl ## If the package is found, perform ACTION-IF-FOUND, else perform
dnl ## the ACTION-IF-NOT-FOUND. The macro does not produce any cached values.

define([FIND_LMP_PACKAGE], [


fname="${LAMMPS_PATH}/lmpinstalledpkgs.h"
c=0
AC_CHECK_FILE([$fname],[b=1],[b=0])

if test "$b" = 0; then
   dnl ## try in styles/
   fname="${LAMMPS_PATH}/styles/lmpinstalledpkgs.h"
   AC_CHECK_FILE([$fname],[b=1],[b=0])
fi

AC_MSG_CHECKING([LAMMPS package: $1])

if test "$b" = 1; then
  unset c
  c=$(grep -c -i "$1" $fname)
fi


dnl ## action [$2] or [$3]
if test "$c" = 1; then
  AC_MSG_RESULT([package found])
  dnl ## if argument 2 is equal to nothing, do nothing, else do argument 2
  ifelse([$2], , ,[$2])
else
  AC_MSG_RESULT([package not found])
  ifelse([$3], , ,[$3])
fi

unset b c
] )
