AC_INIT([main],[1.0])

AC_CONFIG_MACRO_DIR([m4/])
m4_include([m4/x_ac_partn_lammps.m4])


dnl ## this directory path
if test "$topdir" = "" ; then topdir="`pwd`" ; fi

dnl ## get AR, ARFLAGS
dnl ## get CC, CXX, and flags

dnl ## default FCFLAGS
: ${FCFLAGS="-g -O1"}

dnl ## fortran compiler, set extension of src files, and check if it works
AC_LANG(Fortran)
AC_FC_SRCEXT(f90)
AC_PROG_FC([ifx, ifort, gcc])

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
AC_SEARCH_LIBS(dgeev, lapack blas, [b=0], [b=1])
AC_SUBST(BLAS_LIB, ["$ac_cv_search_dgeev"])


dnl ## define WITH_LAMMPS variable
AC_ARG_WITH(lammps, [AS_HELP_STRING([--with-lammps], [Compile pARTn for lammps])])
if test "$with_lammps" = yes
then
   X_AC_PARTN_LAMMPS()
fi
AC_ARG_VAR(LAMMPS_PATH, [Path to the lammps root directory, needed when '--with-lammps'])




dnl ## export symbols
AC_SUBST(FCFLAGS)
AC_SUBST(topdir)
AC_SUBST(INTEL)
AC_SUBST(FC_MODINC)
AC_SUBST(FC_MODOUT)
AC_SUBST(LAMMPS_PATH)

dnl ## output files
AC_CONFIG_FILES(make.inc)
#AC_CONFIG_FILES(environment_vars)
#AC_CONFIG_FILES([Makefile])
AC_OUTPUT
