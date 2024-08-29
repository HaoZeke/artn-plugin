AC_INIT([pARTn],[1.0])

AC_PREREQ(2.71)
AC_CONFIG_MACRO_DIR([m4/])
m4_include([m4/f90_version.m4])

dnl Force the compiler to run once and do all the basic checks
dnl if you don't, it will do the test on the first invocation
dnl below and so your pretty section titles won't work as well
AC_CHECK_HEADERS(iostream)

dnl Small macro to print out a nice, pretty section title.
define(SECTION_TITLE,
[
   echo >& AS_MESSAGE_FD
   echo '   $1   ' | sed -e's/./-/g' >&AS_MESSAGE_FD
   echo '   $1' >& AS_MESSAGE_FD
   echo '   $1   ' | sed -e's/./-/g' >&AS_MESSAGE_FD
])


AC_CANONICAL_HOST
AC_CANONICAL_BUILD
echo ">> host" "$host"                 >& AS_MESSAGE_FD
echo ">> host_cpu" "$host_cpu"         >& AS_MESSAGE_FD
echo ">> host_vendor" "$host_vendor"   >& AS_MESSAGE_FD
echo ">> host_os" "$host_os"           >& AS_MESSAGE_FD
echo ">> build" "$build"               >& AS_MESSAGE_FD
echo ">> build_cpu" "$build_cpu"       >& AS_MESSAGE_FD
echo ">> build_vendor" "$build_vendor" >& AS_MESSAGE_FD
echo ">> build_os" "$build_os"         >& AS_MESSAGE_FD


dnl ## get architecture $arch
X_AC_PARTN_ARCH()
echo ">> arch" "$arch" >& AS_MESSAGE_FD

dnl ## this directory path
if test "$topdir" = "" ; then topdir="`pwd`" ; fi

dnl ## default FCFLAGS
: ${FCFLAGS="-g -O1"}


dnl ## fancy section
SECTION_TITLE(Now configuring pARTn)


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


dnl ## fancy section
SECTION_TITLE(Setting compiler flags)


dnl ## get the f90_version string
F90_VERSION()

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


echo ">> F90 compiler is:" >& AS_MESSAGE_FD
echo " ${f90_version}"     >& AS_MESSAGE_FD


dnl ## check if intel
INTEL="NO"
if test x"$(echo ${f90_version} | grep 'Intel')" != x""; then
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
AC_OUTPUT

dnl ## fancy section
SECTION_TITLE(Final messages)


echo ' The results are written in file: make.inc'                      >& AS_MESSAGE_FD
echo ' Check if they are as expected, and correct manually if needed.' >& AS_MESSAGE_FD
echo ' '                                                               >& AS_MESSAGE_FD


dnl #####
dnl ## output for QE
dnl #####
a=0

echo " with_qe     :" "$with_qe"   >& AS_MESSAGE_FD
if test x"$with_qe" = xyes; then
a=1

echo " QE_PATH     :" "${QE_PATH}"    >& AS_MESSAGE_FD
echo " QE version  :" "${QE_VERSION}" >& AS_MESSAGE_FD

if test -n "$pw_patch_str"; then
a=2
echo " !! NOTE: $pw_patch_str"                    >& AS_MESSAGE_FD
fi

if test -n "$pw_compile_str"; then
a=3
echo " !! NOTE: $pw_compile_str"   >& AS_MESSAGE_FD
fi

fi dnl ## with_qe

echo " -------------"



dnl #####
dnl ## output for LAMMPS
dnl #####
b=0

echo " with_lammps :" "$with_lammps"   >& AS_MESSAGE_FD
if test x"$with_lammps" = xyes; then
b=1

echo " LAMMPS_PATH    :" "${LAMMPS_PATH}" >& AS_MESSAGE_FD
echo " LAMMPS version :" "${LMP_VERSION}" >& AS_MESSAGE_FD
echo " lmp_<machine>  :" lmp_"${LMP_MACHINE}" >& AS_MESSAGE_FD

fi dnl ## with_lammps

echo " -------------"


dnl #####
dnl ## what to execute after configure
dnl #####
echo                          " !! execute the commands to complete pARTn compilation:" >& AS_MESSAGE_FD
if test "$a" -ge 1; then echo " !!   make lib" >& AS_MESSAGE_FD; fi
if test "$a" -ge 2; then echo " !!   make patch-qe" >& AS_MESSAGE_FD; fi
if test "$a" -eq 3; then echo " !!   cd ${QE_PATH} && make pw -j4 && cd -" >& AS_MESSAGE_FD; fi

if test "$b" -ge 1; then echo " !!   make lmplib" >& AS_MESSAGE_FD; fi
