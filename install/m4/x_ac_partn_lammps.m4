AC_DEFUN([X_AC_PARTN_LAMMPS], [


dnl ## define --with-lammps var
AC_ARG_WITH(lammps, [AS_HELP_STRING([--with-lammps], [Compile pARTn for lammps])])
dnl ## define LAMMPS_PATH as variable
AC_ARG_VAR(LAMMPS_PATH, [Path to the lammps root directory, needed when '--with-lammps'])

AC_SUBST(with_lammps)

if test "$with_lammps" = ""; then
 :
else


dnl ## fancy section
SECTION_TITLE(Attempting to set configuration from LAMMPS)


dnl ##
dnl ## backup CFLAGS, LDFLAGS
dnl ##
CFLAGS_backup="${CFLAGS}"
LDFLAGS_backup="${LDFLAGS}"

if test "$LAMMPS_PATH" = ""
then
  AC_MSG_ERROR(
["LAMMPS_PATH variable is needed when using '--with-lammps', specify it as: './configure --with-lammps LAMMPS_PATH=/path/to/lammps'"], -1)
fi

dnl ## try in LAMMPS_PATH/src
LMP_DUM="$(realpath ${LAMMPS_PATH}/src)"

unset CFLAGS LDFLAGS
CFLAGS="-I${LMP_DUM}"
LDFLAGS="-L${LMP_DUM}"
AC_LANG_PUSH(C)
AC_SEARCH_LIBS(lammps_version,lammps,
  [lmp=1],
  [lmp=0])

dnl # if library is not found, try looking directly in LAMMPS_PATH
if test $lmp = 0; then
  unset CFLAGS LDFLAGS LMP_DUM ac_cv_search_lammps_version
  LMP_DUM="$(realpath ${LAMMPS_PATH})"
  CFLAGS="-I${LMP_DUM}"
  LDFLAGS="-L${LMP_DUM}"
  AC_SEARCH_LIBS(lammps_version,lammps,
    [lmp=1],
    AC_MSG_ERROR(["Linking the LAMMPS library failed. Check LAMMPS_PATH. If on hpc load needed blas/lapack modules."], -1))
fi
dnl # liblammps was found
AC_MSG_RESULT([Found liblammps.so in ${LMP_DUM}])
AC_MSG_NOTICE([setting LAMMPS_PATH to ... ${LMP_DUM}])
AC_SUBST(LAMMPS_PATH,["$LMP_DUM"])



dnl ## specify full string for linking liblammps
LIBLAMMPS="-L${LMP_DUM} $ac_cv_search_lammps_version -Wl,-rpath,${LMP_DUM}"
AC_SUBST(LIBLAMMPS)


dnl ## get lmp <machine> from postfix of liblammps.so
LMP_SYMLINK=${LMP_DUM}/liblammps.so
AC_CHECK_FILE([${LMP_SYMLINK}],
   [
   dnl ## convert symlink to real path, remove .so suffix, and cut by "_"
   TARGET=$(readlink "${LMP_SYMLINK}")
   dnl # echo ">>TARGET" "$TARGET"
   LMP_MACHINE=$(basename "${TARGET}" .so|cut -d "_" -f 2)
   ],
   [
   dnl ## error
   AC_MSG_ERROR(["Problem searching for lammsp library: ${LMP_SYMLINK}"], -2 )
   ])
echo ">> LMP_MACHINE:" "${LMP_MACHINE}"
dnl ## try to find makefile used for lammps, and extract CC
L_MKFILE=${LMP_DUM}/Obj_shared_${LMP_MACHINE}/Makefile
AC_MSG_NOTICE([Attempting to extract CXX/CC compiler from: ${L_MKFILE}])

AC_CHECK_FILE([${L_MKFILE}],
   [
   dnl ## try to grep for CC
   LMP_CC=$(grep "CC =" ${L_MKFILE}|cut -d "=" -f 2|tr -d '[[:space:]]')
   echo "LMP_CC:" "${LMP_CC}"
   ],
   [
   dnl ## error in extracting CC from lammsp Makefile
   AC_MSG_WARN([The LAMMPS CC compiler could not be extracted, set it manually in make.inc])
   ])


AC_MSG_NOTICE([setting CXX to ... ${LMP_CC}])
AC_MSG_NOTICE([setting CC to ... ${LMP_CC}])
AC_SUBST(CXX, ["$LMP_CC"])
AC_SUBST(CC, ["$LMP_CC"])


dnl ##
dnl ## reset CFLAGS and LDFLAGS
dnl ##
CFLAGS="${CFLAGS_backup}"
LDFLAGS="${LDFLAGS_backup}"
AC_LANG_POP(C)
AC_LANG(Fortran)


AC_SUBST(LMP_MACHINE)

fi
])
