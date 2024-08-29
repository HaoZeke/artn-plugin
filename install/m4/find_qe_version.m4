define([FIND_QE_VERSION], [
AC_MSG_CHECKING([QE version])

dnl ## read file from QE_PATH/include/qe_version.h
fname="${QE_PATH}/include/qe_version.h"
AC_CHECK_FILE( [$fname], [b=1], [b=0] )

unset ac_cv_qe_version
ac_cv_qe_version="unknown"

if test "$b" = 1; then
  unset ac_cv_qe_version
  ac_cv_qe_version=$(grep "version_number" $fname|cut -d "=" -f 3 | tr -d "'")
fi
unset fname b
])
