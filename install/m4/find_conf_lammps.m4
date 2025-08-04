AC_DEFUN([FIND_CONF_LAMMPS],[



m4_include([m4/find_lmp_version.m4])
m4_include([m4/find_lmp_package.m4])

dnl ## fancy section
SECTION_TITLE(Attempting to set configuration from LAMMPS)

dnl ## LAMMPS_PATH is not set
if test -z "$LAMMPS_PATH"; then
  AC_MSG_ERROR(
["LAMMPS_PATH variable is needed when using '--with-lammps', specify it as: './configure --with-lammps LAMMPS_PATH=/path/to/lammps'"], -1)
fi

dnl ## first check if the pointer directory is lammps_root, or lammps_src, or lammps_build:
dnl ## check for file `LAMMPSConfig.cmake.in` which lives in lammps_root/cmake
LAMMPS_ROOT=0
AC_CHECK_FILE(["${LAMMPS_PATH}/cmake/LAMMPSConfig.cmake.in"],
              [LAMMPS_ROOT=$(realpath "${LAMMPS_PATH}")], [])
AC_CHECK_FILE(["${LAMMPS_PATH}/../cmake/LAMMPSConfig.cmake.in"],
              [LAMMPS_ROOT=$(realpath "${LAMMPS_PATH}/../")], [])

AC_MSG_NOTICE([lammps root is: ${LAMMPS_ROOT}])

if test "$LAMMPS_ROOT" = 0; then
    AC_MSG_ERROR(["LAMMPS path does not seem to be correct."],-1)
fi


dnl ## set dirs for root and src
AC_SUBST(LAMMPS_ROOT)
AC_SUBST(LAMMPS_SRC, $(realpath "${LAMMPS_ROOT}/src") )

dnl ## see if cmake was used to compile lammps:
dnl ## if yes, lammps_path should be to builddir, check for CMakeCache.txt
AC_CHECK_FILE(["${LAMMPS_PATH}/CMakeCache.txt"], [lammps_is_cmake=1], [lammps_is_cmake=0])
echo lmp is cmake: $lammps_is_cmake
if test "$lammps_is_cmake" = 1; then
    AC_SUBST(LAMMPS_PATH, [$(realpath "${LAMMPS_PATH}")])
    :
else
    AC_SUBST(LAMMPS_PATH, ["${LAMMPS_SRC}"] )
    :
fi
AC_SUBST(LAMMPS_INCLUDE, [$(realpath "${LAMMPS_SRC}")])

dnl ## AC_MSG_NOTICE([lmp: root ${LAMMPS_ROOT}, src ${LAMMPS_SRC}, path ${LAMMPS_PATH}])


dnl ## get lammps version string
FIND_LMP_VERSION()
AC_SUBST(LMP_VERSION, "$ac_cv_lmp_version")


dnl ## check if lammps has plugin package
FIND_LMP_PACKAGE(["plugin"], [lmp_has_plugin=1], [lmp_has_plugin=0] )
if test "$lmp_has_plugin" = 0; then
    if test "$lammps_is_cmake" = 1; then
        AC_MSG_ERROR([Configure LAMMPS with the PLUGIN package: "-D PKG_PLUGIN=yes".],-2)
        :
    else
        AC_MSG_ERROR([Configure LAMMPS with the PLUGIN package: "make yes-plugin".],-2)
        :
    fi
fi



dnl ## find lammps <machine> and check if compiled in shared mode
if test "$lammps_is_cmake" = 1; then
    dnl ## search the CMakeCache
    LMP_MACHINE=$(grep "LAMMPS_MACHINE:STRING" "${LAMMPS_PATH}/CMakeCache.txt" | cut -d '=' -f 2)
    if test "$LMP_MACHINE" = ""; then
        MACHINE=${LMP_MACHINE}
        :
    else
        dnl ## pre-pend underscore
        MACHINE="_"${LMP_MACHINE}
        :
    fi
    pp=$(grep "BUILD_SHARED_LIBS:BOOL" "${LAMMPS_PATH}/CMakeCache.txt" | cut -d '=' -f 2)
    if test "$pp" != "yes"; then
        AC_MSG_ERROR([LAMMPS has to be configured in shared mode: "-D BUILD_SHARED_LIBS=yes" ],-2)
    fi
    LMP_SYMLINK=${LAMMPS_PATH}"/liblammps"${MACHINE}".so"
    AC_CHECK_FILE([${LMP_SYMLINK}],
                  [lmp_compiled=1
                   AC_SUBST(LIBLAMMPS, "${LMP_SYMLINK}")],
                  [AC_MSG_ERROR([LAMMPS has to be compiled in shared mode: "-D BUILD_SHARED_LIBS=yes"],-2)])
else
    dnl ## check if lammps is actually compiled in shared mode (search liblammps.so file)
    LMP_SYMLINK=${LAMMPS_PATH}/liblammps.so
    AC_CHECK_FILE([${LMP_SYMLINK}],
                  [lmp_compiled=1
                   AC_SUBST(LIBLAMMPS, "${LMP_SYMLINK}")],
                  [AC_MSG_ERROR([LAMMPS has to be compiled in shared mode: "make mode=shared <machine>"],-2)])
    TARGET=$(readlink "${LMP_SYMLINK}")
    LMP_MACHINE=$(basename "${TARGET}" .so|cut -d "_" -f 2)
fi
echo "found lmp machine ... ${LMP_MACHINE}" >& AS_MESSAGE_FD
echo "liblammps is: ${LMP_SYMLINK}" >& AS_MESSAGE_FD
AC_SUBST(LMP_MACHINE)


])
