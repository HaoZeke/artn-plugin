AC_DEFUN([FIND_CXX_LAMMPS],[



m4_include([m4/find_lmp_version.m4])
m4_include([m4/find_lmp_package.m4])

dnl ## fancy section
SECTION_TITLE(Attempting to set configuration from LAMMPS)

dnl ## LAMMPS_PATH is not set
if test -z "$LAMMPS_PATH"; then
  AC_MSG_ERROR(
["LAMMPS_PATH variable is needed when using '--with-lammps', specify it as: './configure --with-lammps LAMMPS_PATH=/path/to/lammps'"], -1)
fi


dnl ## where are we? Search for src/version.h file...
loc=0
AC_CHECK_FILE(["${LAMMPS_PATH}/version.h"], [loc=1], [])
if test "$loc" = 0; then
  AC_CHECK_FILE(["${LAMMPS_PATH}/src/version.h"], [loc=2], [])
fi


if test "$loc" = 1; then
  LAMMPS_PATH=$(realpath "${LAMMPS_PATH}")
elif test "$loc" = 2; then
  LAMMPS_PATH=$(realpath "${LAMMPS_PATH}/src")
else
  AC_MSG_ERROR(["LAMMPS path does not seem to be correct."],-1)
fi

AC_MSG_NOTICE([setting LAMMPS_PATH to ... ${LAMMPS_PATH}])
AC_SUBST(LAMMPS_PATH)

dnl ## get lammps version string
FIND_LMP_VERSION()
AC_SUBST(LMP_VERSION, "$ac_cv_lmp_version")


dnl ## check if lammps is actually compiled in shared mode (search liblammps.so file)
LMP_SYMLINK=${LAMMPS_PATH}/liblammps.so
AC_CHECK_FILE([${LMP_SYMLINK}],
 [lmp_compiled=1
 AC_SUBST(LIBLAMMPS, "${LMP_SYMLINK}")],
 [AC_MSG_ERROR([LAMMPS has to be compiled in shared mode: "make mode=shared <machine>"],-2)]
 )

dnl ## find lammps <machine>
TARGET=$(readlink "${LMP_SYMLINK}")
LMP_MACHINE=$(basename "${TARGET}" .so|cut -d "_" -f 2)
echo "found lmp machine ... ${LMP_MACHINE}" >& AS_MESSAGE_FD
AC_SUBST(LMP_MACHINE)

dnl ## check if lammps has plugin package
FIND_LMP_PACKAGE(["plugin"], [lmp_has_plugin=1], [lmp_has_plugin=0] )
if test "$lmp_has_plugin" = 0; then
  AC_MSG_WARN([Configure LAMMPS with the PLUGIN package: "make yes-plugin".],-1)
fi

dnl ## try to find makefile used for lammps, and extract CC
L_MKFILE=${LAMMPS_PATH}/Obj_shared_${LMP_MACHINE}/Makefile
AC_MSG_NOTICE([Attempting to extract CXX/CC compiler from: ${L_MKFILE}])

AC_CHECK_FILE([${L_MKFILE}],
[
dnl ## try to grep for CC
lmp_cc=$(grep "CC =" ${L_MKFILE}|cut -d "=" -f 2|tr -d '[[:space:]]')
],
[
dnl ## error in extracting CC from lammsp Makefile
AC_MSG_ERROR([The LAMMPS CC compiler could not be extracted, make sure LAMMPS is compiled in mode=shared.])
])


dnl ## get full path to trial compiler
FIND_COMPILER_REALPATH( [$lmp_cc], [lmp_cc_ok=1], [lmp_cc_ok=-1] )
if test "$lmp_cc_ok" = -1; then AC_MSG_ERROR([Compiler "$lmp_cc" not found. Stopping.]); fi
lmp_cc=$compiler_path




])
