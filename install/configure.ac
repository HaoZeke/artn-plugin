AC_INIT([pARTn],[1.0])

AC_PREREQ(2.71)
AC_CONFIG_MACRO_DIR([m4/])

AC_CANONICAL_HOST
AC_CANONICAL_BUILD
echo ">> host" "$host"
echo ">> host_cpu" "$host_cpu"
echo ">> host_vendor" "$host_vendor"
echo ">> host_os" "$host_os"
echo ">> build" "$build"
echo ">> build_cpu" "$build_cpu"
echo ">> build_vendor" "$build_vendor"
echo ">> build_os" "$build_os"

dnl ## get architecture $arch
X_AC_PARTN_ARCH()
echo ">> arch" "$arch"

dnl ## this directory path
if test "$topdir" = "" ; then topdir="`pwd`" ; fi

dnl ## default FCFLAGS
: ${FCFLAGS="-g -O1"}

dnl ## fortran compiler, set extension of src files, and check if it works
AC_LANG(Fortran)
AC_FC_SRCEXT(f90)

dnl ## get f90 and mpif90 from the system
X_AC_PARTN_MPIF90()
echo ">> F90" "$f90"
echo ">> MPIF90" "$mpif90"
FC="$f90"

dnl ## cpp compiler
AC_PROG_CXX


dnl ## search for dgemm symbol (lapack or blas), result is added to LIBS
AC_SEARCH_LIBS(dgemm, lapack blas openblas, [b=1], [b=0])
if test "$b" == 1; then
  AC_SUBST(BLAS_LIB, ["$ac_cv_search_dgemm"])
fi


dnl ## execute only if argument '--with-qe' is present
dnl ## It needs also the argument QE_PATH.
dnl ## It will attempt to read variables from QE_PATH/make.inc,
dnl ## and can overwrite the f90 and mpif90 found earlier with X_AC_PARTN_MPIF90()!
dnl ## It tries to extract which LAPACK_LIBS were used in QE, and append them to BLAS_LIB here.
X_AC_PARTN_QE()


dnl ## search for -lgfortran (or equivalent, result in $ac_cv_fc_libs)
AC_FC_LIBRARY_LDFLAGS
AC_SUBST(FORT_LIB, ["$ac_cv_fc_libs"])

dnl ## attempt impose freeform
AC_FC_FREEFORM

dnl ## get bounds check flag
AC_FC_CHECK_BOUNDS

dnl ## get the include (-I) flag (FC_MODINC)
AC_FC_MODULE_FLAG

dnl ## get the modoutput (-J) flag (FC_MODOUT)
AC_FC_MODULE_OUTPUT_FLAG

dnl ## check if intel
INTEL="NO"
if test "${FC_MODOUT}" == "-module "; then
  INTEL="YES"
fi



dnl ## execute only if argument '--with-lammps' is present.
dnl ## It needs also argument LAMMPS_PATH.
dnl ## It will attempt to find which <machine> was used in lammps compilation command:
dnl ##    make mode=shared <machine>
dnl ## and try to extract which CC compiler was used in the corresponding makefile.
dnl ## This will overwrite both CC and CXX of this script.
X_AC_PARTN_LAMMPS()


dnl ## export symbols
AC_SUBST(topdir)
AC_SUBST(INTEL)

dnl ## output files
AC_CONFIG_FILES(make.inc)
AC_CONFIG_FILES(config.msg)
#AC_CONFIG_FILES([Makefile])
AC_OUTPUT

cat config.msg
