m4_define(m4_artn_version,m4_esyscmd(grep "ARTN_VERSION" ../src/artn_version.h|cut -d '"' -f 2) )
AC_INIT([pARTn],m4_artn_version)
AC_PREREQ(2.71)
AC_CONFIG_MACRO_DIR([m4/])
m4_include([m4/add_trial_compiler.m4])
m4_include([m4/find_compiler_realpath.m4])


dnl Small macro to print out a nice, pretty section title.
define(SECTION_TITLE,
       [
           echo >& AS_MESSAGE_FD
           echo '   $1   ' | sed -e's/./-/g' >&AS_MESSAGE_FD
           echo '   $1' >& AS_MESSAGE_FD
           echo '   $1   ' | sed -e's/./-/g' >&AS_MESSAGE_FD
       ])

dnl ## this directory path
if test "$topdir" = "" ; then topdir="`pwd`" ; fi


dnl ##
dnl ## define configure variables for different engines:
dnl ## the "--with-<engine>", and "<engine>_PATH" which are passed as
dnl ## arguments when configure is launched
dnl ##
dnl ## --with-qe
AC_ARG_WITH(qe, [AS_HELP_STRING([--with-qe], [Compile pARTn for QE])])
AC_ARG_VAR(QE_PATH, [Path to QE root directory, needed when '--with-qe'])
dnl ##
dnl ## --with-siesta
AC_ARG_WITH(siesta, [AS_HELP_STRING([--with-siesta], [Compile pARTn for Siesta])])
AC_ARG_VAR(SIESTA_PATH, [Path to Siesta build directory, needed when '--with-siesta'])
dnl ##
dnl ## --with-lammps
AC_ARG_WITH(lammps, [AS_HELP_STRING([--with-lammps], [Compile pARTn for lammps])])
dnl ## define LAMMPS_PATH as variable
AC_ARG_VAR(LAMMPS_PATH, [Path to the lammps root directory, needed when '--with-lammps'])


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

dnl AC_MSG_NOTICE([Current variables:])
dnl (set | sort)


try_f90=""
try_mpif90=""
try_cc="mpicxx gcc"
try_cxx="mpicxx gcc"

SECTION_TITLE([Searching system architecture])
dnl ## get arch
X_AC_PARTN_ARCH()
echo ">> arch" "$arch" >& AS_MESSAGE_FD
dnl ## set try_f90 and try_mpif90 based on arch
ARCH_COMPILERS()

echo "try_f90" "$try_f90" >& AS_MESSAGE_FD
echo "try_mpif90" "$try_mpif90" >& AS_MESSAGE_FD
echo "try_cc" "$try_cc" >& AS_MESSAGE_FD
echo "try_cxx" "$try_cxx" >& AS_MESSAGE_FD

dnl ##==========================
dnl ## search for F90 and MPIF90 compilers of specified engines
dnl ## add them to "try_f90" and "try_mpif90"
dnl ##==========================

dnl ## --with-qe
if test -z "$with_qe"; then AC_SUBST(with_qe,["no"]) :; else

    dnl ## search QE configuration
    FIND_F90_QE()

    dnl ## add found compilers to try_f90 and try_mpif90
    ADD_TRIAL_F90( $qe_f90 )
    ADD_TRIAL_MPIF90( $qe_mpif90 )

fi dnl ## with_qe


dnl ## --with-siesta
if test -z "$with_siesta"; then AC_SUBST(with_siesta,["no"]) :; else

    dnl ## search siesta configuration
    FIND_F90_SIESTA()

    dnl ## add found compilers to try_f90 and try_mpif90
    ADD_TRIAL_F90( $siesta_f90 )
    ADD_TRIAL_MPIF90( $siesta_mpif90 )

fi dnl ## with_siesta




dnl ##==========================
dnl ## search for CC and CXX compilers of lammps
dnl ## add them to "try_cc" and "try_cxx"
dnl ##==========================
if test -z "$with_lammps"; then AC_SUBST(with_lammps,["no"]) :; else
    dnl ## search LAMMPS config
    FIND_CXX_LAMMPS()

    dnl ## add found lammps compiler to CC and CXX
    ADD_TRIAL_CC( $lmp_cc )
    ADD_TRIAL_CXX( $lmp_cc )

fi



dnl ## set the compilers from try_ lists
SECTION_TITLE([Setting compilers])




echo "try_f90" "$try_f90" >& AS_MESSAGE_FD
echo "try_mpif90" "$try_mpif90" >& AS_MESSAGE_FD
echo "try_cc" "$try_cc" >& AS_MESSAGE_FD
echo "try_cxx" "$try_cxx" >& AS_MESSAGE_FD




dnl ## set the actual FC
AC_LANG_PUSH(Fortran)
AC_FC_SRCEXT(f90)



dnl ## test the try_mpif90 list
# clear cached values
unset FC ac_cv_prog_ac_ct_FC ac_cv_fc_compiler_gnu ac_cv_prog_fc_g
mpif90="$try_mpif90"
AC_PROG_FC($mpif90)
dnl echo "FC" "$FC"
mpif90="$FC"
F90_VERSION_2($mpif90)
AC_MSG_NOTICE([Setting MPIF90=$mpif90, version: $f90_version])
dnl echo "$f90_version"
AC_SUBST(mpif90)


dnl ## test the try_f90 list
unset FC ac_cv_prog_ac_ct_FC ac_cv_fc_compiler_gnu ac_cv_prog_fc_g
f90="$try_f90"
AC_PROG_FC($f90)
dnl echo "FC" "$FC"
f90="$FC"
F90_VERSION_2($f90)
AC_MSG_NOTICE([Setting F90=$f90, version: $f90_version])
dnl echo "$f90_version"
AC_SUBST(f90)


COMPILERS_EQUAL_F90([$mpif90], [$f90])
echo "compilers equal:" "$mpif90" "f90" "$compilers_equal"


F90_VERSION_2( $f90 )
dnl ## check if intel
INTEL="NO"
if test x"$(echo ${f90_version} | grep 'Intel')" != x""; then
    INTEL="YES"
fi
AC_SUBST(INTEL)
AC_SUBST(f90_version)


# repeat for CC
unset CC
cc="$try_cc"
AC_PROG_CC($cc)
dnl echo "cc" "$CC"
AC_SUBST(CC)
AC_SUBST(CXX, "$CC")


SECTION_TITLE([Searching for libraries])

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

dnl ## search lapack/blas
BLAS_LIB=""
AC_SEARCH_LIBS([dgeev],[blas lapack openblas],
               [BLAS_LIB="$ac_cv_search_dgeev $BLAS_LIB"],
               [AC_MSG_NOTICE([dgeev not found])])
AC_SEARCH_LIBS([dgemm],[blas lapack openblas],
               [BLAS_LIB="$ac_cv_search_dgemm $BLAS_LIB"],
               [AC_MSG_NOTICE([dgemm not found])])
AC_SUBST(BLAS_LIB)

dnl ## search for lua if with_siesta
if test "$with_siesta" = "yes"; then
    AC_LANG_PUSH(C)
    AC_SEARCH_LIBS([lua_version],[lua lua5.3 lua5.2],
                   [lualib=$ac_cv_search_lua_version],
                   [lualib=""
                    AC_MSG_NOTICE([lua not found])]
                  )
    AC_SUBST(lualib)
    AC_LANG_POP(C)
fi


MPIFORT_LIB=""
if test -n "$mpif90"; then
    dnl ## find mpi ldflags
    unset FC ac_cv_fc_libs FLIBS FCLIBS ac_cv_prog_fc_v
    unset FC ac_cv_prog_ac_ct_FC ac_cv_fc_compiler_gnu ac_cv_prog_fc_g
    FC=$mpif90
    AC_FC_LIBRARY_LDFLAGS
    MPIFORT_LIB=$ac_cv_fc_libs
fi
AC_SUBST(MPIFORT_LIB)





dnl ## export symbols
AC_SUBST(topdir)

dnl ## output files
AC_CONFIG_FILES(make.inc)
AC_OUTPUT


dnl ## fancy section
SECTION_TITLE(Final messages)

dnl ## check if we are already compiled (happens if --save is passed)
AC_CHECK_FILE([$topdir/lib/libartn.so],[makelib=0],[makelib=1])

dnl ## check if mpif90 was not found
if test -z "$mpif90"; then
    echo " NOTE: MPIF90 compiler was not found. If you need it, make according adjustments by hand."
fi

dnl ## QE: see if compilers equal
if test "$with_qe" = "yes"; then
    COMPILERS_EQUAL_F90("$f90", "$qe_f90")
    qe_compilers_equal=$compilers_equal
fi

dnl ## see if libartn-lmp is already compiled
if test "$with_lammps" = "yes"; then
  AC_CHECK_FILE([${topdir}/lib/libartn-lmp.so],[makelmplib=0],[makelmplib=1])
fi

echo '' >& AS_MESSAGE_FD
echo ' The results are written in file: make.inc'                      >& AS_MESSAGE_FD
echo ' Check if they are as expected, and correct manually if needed.' >& AS_MESSAGE_FD
echo ' '                                                               >& AS_MESSAGE_FD


dnl #####
dnl ## output for QE
dnl #####

makepatchqe=0
makepw=0

echo " with_qe     :" "$with_qe"   >& AS_MESSAGE_FD
if test x"$with_qe" = xyes; then

    echo " QE_PATH     :" "${QE_PATH}"    >& AS_MESSAGE_FD
    echo " QE version  :" "${QE_VERSION}" >& AS_MESSAGE_FD

    if test -n "$qe_comment"; then
        makepw=1
        echo -e " !! NOTE:" $qe_comment
    fi

    if test "$qe_compilers_equal" != 1; then
        echo " !! NOTE: QE and pARTn compilers differ. Take care to load appropriate modules before launching."
    fi

    if test -n "$pw_patch_str"; then
        makepatchqe=1
        echo " !! NOTE: $pw_patch_str"                    >& AS_MESSAGE_FD
    fi

    if test -n "$pw_compile_str"; then
        makepw=1
        echo " !! NOTE: $pw_compile_str"   >& AS_MESSAGE_FD
    fi

fi dnl ## with_qe

echo " -------------" >& AS_MESSAGE_FD



dnl #####
dnl ## output for LAMMPS
dnl #####
makelmpplugin=0

echo " with_lammps :" "$with_lammps"   >& AS_MESSAGE_FD
if test x"$with_lammps" = xyes; then

    echo " LAMMPS_PATH    :" "${LAMMPS_PATH}" >& AS_MESSAGE_FD
    echo " LAMMPS version :" "${LMP_VERSION}" >& AS_MESSAGE_FD
    echo " lmp_<machine>  :" lmp_"${LMP_MACHINE}" >& AS_MESSAGE_FD

    if test "$lmp_has_plugin" = 0; then
        makelmpplugin=1
        echo " !! NOTE: LAMMPS does not seem to have the PLUGIN package configured." >& AS_MESSAGE_FD
    fi

fi dnl ## with_lammps

echo " -------------" >& AS_MESSAGE_FD

dnl #####
dnl ## output for Siesta
dnl #####

echo " with_siesta :" "$with_siesta"   >& AS_MESSAGE_FD
if test x"$with_siesta" = xyes; then

    echo " SIESTA_PATH :" "${SIESTA_PATH}" >& AS_MESSAGE_FD

fi dnl ## with_lammps

echo " -------------" >& AS_MESSAGE_FD


dnl #####
dnl ## what to execute after configure
dnl #####
echo " >> execute the following commands to complete pARTn compilation:" >& AS_MESSAGE_FD
if test "$makelib" = 1; then
echo " make lib" >& AS_MESSAGE_FD
fi
if test "$makepatchqe" = 1; then
echo " make patch-qe" >& AS_MESSAGE_FD
fi
if test "$makepw" = 1; then
echo " cd ${QE_PATH} && make pw -j2 && cd -" >& AS_MESSAGE_FD
fi

if test "$makelmplib" = 1; then
echo " make lmplib" >& AS_MESSAGE_FD
fi
if test "$makelmpplugin" = 1; then
echo " cd ${LAMMPS_PATH} && make yes-plugin && make mode=shared ${LMP_MACHINE} -j4 && cd -" >& AS_MESSAGE_FD
fi
