dnl ## Attempt to read LAMMPS_VERSION from the header file:
dnl ##   LAMMPS_SRC/version.h
dnl ## If the file contains LAMMPS_UPDATE string, append it to result.
dnl ## Output is stored in ${ac_cv_lmp_version}
dnl ## The LAMMPS_SRC should point to lammps/src prior to entering.

define([FIND_LMP_VERSION],[

echo "Checking for LAMMPS version ..." >& AS_MESSAGE_FD

dnl ## read directly from LAMMPS_SRC/version.h
fname="${LAMMPS_SRC}/version.h"
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
fname="${LAMMPS_SRC}/lmpgitversion.h"
AC_CHECK_FILE([$fname], [b=1], [b=0])
if test "$b" = 1; then
  git_descriptor=$(grep "git_descriptor" $fname | cut -d '"' -f 2)
  ac_cv_lmp_version="${ac_cv_lmp_version}; git_descriptor: ${git_descriptor}"
else
  dnl ## not found, try LAMMPS_PATH might be a cmake builddir
  fname="${LAMMPS_PATH}/styles/lmpgitversion.h"
  AC_CHECK_FILE([$fname], [c=1], [c=0] )
  if test "$c" = 1; then
    git_descriptor=$(grep "git_descriptor" $fname | cut -d '"' -f 2)
    ac_cv_lmp_version="${ac_cv_lmp_version}; git_descriptor: ${git_descriptor}"
  fi
  unset c
fi
echo "Found LAMMPS version: $ac_cv_lmp_version" >& AS_MESSAGE_FD

unset fname update b patch
])
