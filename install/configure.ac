AC_INIT([main],[1.0])

AC_PREREQ(2.71)
AC_CONFIG_MACRO_DIR([m4/])
m4_include([m4/x_ac_partn_arch.m4])
m4_include([m4/x_ac_partn_mpif90.m4])
m4_include([m4/x_ac_partn_lammps.m4])

AC_CANONICAL_BUILD
echo ">> host" "$host"
echo ">> build" "$build"
echo ">> build_cpu" "$build_cpu"
echo ">> build_vendor" "$build_vendor"
echo ">> build_os" "$build_os"

X_AC_PARTN_ARCH()
echo ">> arch" "$arch"

dnl ## this directory path
if test "$topdir" = "" ; then topdir="`pwd`" ; fi

dnl ## default FCFLAGS
: ${FCFLAGS="-g -O1"}

dnl ## fortran compiler, set extension of src files, and check if it works
AC_LANG(Fortran)
AC_FC_SRCEXT(f90)
#AC_PROG_FC([ifx ifort gfortran f90])
X_AC_PARTN_MPIF90()
echo ">> F90" "$f90"
echo ">> MPIF90" "$mpif90"
FC="$f90"

dnl ## cpp compiler
AC_PROG_CXX

dnl ## attempt impose freeform
AC_FC_FREEFORM

dnl ## get bounds check flag
AC_FC_CHECK_BOUNDS

dnl ## get the include (-I) flag (FC_MODINC)
AC_FC_MODULE_FLAG

dnl ## get the modoutput (-J) flag (FC_MODOUT)
AC_FC_MODULE_OUTPUT_FLAG

dnl ## for intel the flag is "-module " with empty space at the end
INTEL="NO"
if test "$FC_MODOUT" == "-module "
then
	INTEL="YES"
fi


dnl ## search for -lgfortran (or equivalent, result in $ac_cv_fc_libs)
AC_FC_LIBRARY_LDFLAGS
AC_SUBST(FORT_LIB, ["$ac_cv_fc_libs"])

dnl ## search for dgeev symbol (lapack or blas), result is added to LIBS
AC_SEARCH_LIBS(dgeev, lapack blas, [b=1], [b=0])
if test "$b" == 1; then
  AC_SUBST(BLAS_LIB, ["$ac_cv_search_dgeev"])
fi


dnl ## define WITH_LAMMPS variable
dnl AC_ARG_WITH(lammps, [AS_HELP_STRING([--with-lammps], [Compile pARTn for lammps])])
dnl if test "$with_lammps" = yes
dnl then
dnl    X_AC_PARTN_LAMMPS()
dnl fi
dnl AC_ARG_VAR(LAMMPS_PATH, [Path to the lammps root directory, needed when '--with-lammps'])

X_AC_PARTN_LAMMPS()



dnl ## export symbols
AC_SUBST(F90, ["$f90"])
AC_SUBST(MPIF90, ["$mpif90"])
AC_SUBST(FCFLAGS)
AC_SUBST(topdir)
AC_SUBST(INTEL)
AC_SUBST(FC_MODINC)
AC_SUBST(FC_MODOUT)
AC_SUBST(LAMMPS_PATH)
AC_SUBST(MPICXX)
AC_SUBST(CC)

dnl ## output files
AC_CONFIG_FILES(make.inc)
#AC_CONFIG_FILES(environment_vars)
#AC_CONFIG_FILES([Makefile])
AC_OUTPUT
