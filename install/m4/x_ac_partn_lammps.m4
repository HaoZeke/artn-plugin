AC_DEFUN( [X_AC_PARTN_LAMMPS], [

LIBLAMMPS=""

##
## backup CFLAGS, LDFLAGS
##

CFLAGS_backup="${CFLAGS}"
LDFLAGS_backup="${LDFLAGS}"

LMP_DUM="$(realpath ${LAMMPS_PATH}/src)"
echo $LMP_DUM

if test "$LAMMPS_PATH" = ""
then
  AC_MSG_ERROR(
[LAMMPS_PATH variable is needed when using '--with-lammps', specify it as: './configure --with-lammps LAMMPS_PATH=/path/to/lammps'], -1)
fi

## try in LAMMPS_PATH/src
unset CFLAGS LDFLAGS
CFLAGS="-I${LMP_DUM}"
LDFLAGS="-L${LMP_DUM}"
AC_LANG_PUSH(C)
AC_SEARCH_LIBS(lammps_version,lammps, 
  [lmp=1],
#  AC_MSG_ERROR(["The LAMMPS library was not found in LAMMPS_PATH=${LMP_DUM}. Check path."], -1))
  [lmp=0])

if test $lmp = 0
then
  unset CFLAGS LDFLAGS LMP_DUM ac_cv_search_lammps_version
  LMP_DUM="$(realpath ${LAMMPS_PATH})"
  CFLAGS="-I${LMP_DUM}"
  LDFLAGS="-L${LMP_DUM}"
  AC_SEARCH_LIBS(lammps_version,lammps, 
    [lmp=1],
    AC_MSG_ERROR(["The LAMMPS library was not found in LAMMPS_PATH=${LMP_DUM}. Check path."], -1))
fi
AC_MSG_RESULT([Found liblammps.so in ${LMP_DUM}])


##
## test compile a program with including artn fix, for checking if same compiler
##


##
## reset CFLAGS and LDFLAGS
##

CFLAGS="${CFLAGS_backup}"
LDFLAGS="${LDFLAGS_backup}"
AC_LANG_POP(C)
AC_LANG(Fortran)

## specify full string for linking liblammps
LIBLAMMPS="-L${LMP_DUM} $ac_cv_search_lammps_version -Wl,-rpath,${LMP_DUM}"

AC_SUBST(LIBLAMMPS)
AC_SUBST(LAMMPS_PATH,["$LMP_DUM"])
])
