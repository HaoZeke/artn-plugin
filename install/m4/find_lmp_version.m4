dnl ## Attempt to read LAMMPS_VERSION from the header file:
dnl ##   LAMMPS_PATH/version.h
dnl ## If the file contains LAMMPS_UPDATE string, append it to result.
dnl ## Output is stored in ${ac_cv_lmp_version}
dnl ## The LAMMPS_PATH should point to lammps/src prior to entering.

define([FIND_LMP_VERSION],[
AC_MSG_CHECKING([LAMMPS version])

dnl ## read directly from LAMMPS_PATH/version.h
fname="${LAMMPS_PATH}/version.h"
AC_CHECK_FILE(
[$fname],
[b=1],
[b=0])

unset ac_cv_lmp_version
ac_cv_lmp_version="unknown"

if test "$b" = 1; then
  unset ac_cv_lmp_version
  ac_cv_lmp_version=$(grep "LAMMPS_VERSION" $fname |cut -d ' ' -f 3- | tr -d '"')
  update=$(grep "LAMMPS_UPDATE" $fname |cut -d ' ' -f 3- | tr -d '"' )
  if test "$update" != ""; then
    ac_cv_lmp_version="${ac_cv_lmp_version} - ${update}"
  fi
fi

dnl ## try to read git info from lammps/src/lmpgitversion.h
unset fname b
fname="${LAMMPS_PATH}/lmpgitversion.h"
AC_CHECK_FILE([$fname], [b=1], [b=0])
if test "$b" = 1; then
  git_descriptor=$(grep "git_descriptor" $fname | cut -d '"' -f 2)
  ac_cv_lmp_version="${ac_cv_lmp_version}; got_descriptor: ${git_descriptor}"
fi

unset fname update b patch
])
