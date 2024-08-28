AC_DEFUN([X_AC_PARTN_QE], [


dnl ## define --with-qe var
AC_ARG_WITH(qe, [AS_HELP_STRING([--with-qe], [Compile pARTn for QE])])
dnl ## define QE_PATH as variable
AC_ARG_VAR(QE_PATH, [Path to the QE root directory, needed when '--with-qe'])

AC_SUBST(with_qe)

if test "$with_qe" = ""; then
  :
else

dnl ## fancy section
SECTION_TITLE(Attempting to set configuration from QE)


dnl ## find rootdir of qe (search file configure, hopefully QE_PATH != q-e/install)
loc=0
AC_CHECK_FILE([${QE_PATH}/configure],[loc=1],[])
AC_CHECK_FILE([${QE_PATH}/../configure],[loc=2],[])

if test "$loc" == 0
then
  dnl ## does not seem to be a valid qe path
  AC_MSG_ERROR(["The QE_PATH does not seem to be correct."],-1)
fi


if test "$loc" == 1
then
  QE_PATH=$(realpath "${QE_PATH}")
fi
if test "$loc" == 2
then
  QE_PATH=$(realpath "${QE_PATH}/../")
fi

AC_MSG_NOTICE([setting QE_PATH to ... ${QE_PATH}])
AC_SUBST(QE_PATH)


dnl ## see if QE_PATH/make.inc file exists. If not, launch qe configure
AC_CHECK_FILE([${QE_PATH}/make.inc],[loc=1],[loc=0])

dnl ## make.inc does not exist
if test "$loc" == 0; then
  dnl ## launch qe configure
  AC_MSG_ERROR([QE is not configured. Go to ${QE_PATH} and launch './configure --enable-legacy_plugins', then come back.],-2)
fi

if test "$loc" == 1; then
  dnl ## make.inc exists, check if it has -D__LEGACY_PLUGINS
  b=$(grep "D__LEGACY_PLUGINS" ${QE_PATH}/make.inc)
  if test "$b" == ""; then
    AC_MSG_ERROR([QE not configured with --enable-legacy_plugins. Go to ${QE_PATH} and launch './configure --enable-legacy_plugins', then come back.],-3)
  fi
fi

dnl ## attempt extracting F90
QE_F90=$(grep "F90 " ${QE_PATH}/make.inc|grep -v "\#"|grep -v "MPI"|cut -d "=" -f 2|tr -d '[[:space:]]')
echo "QE_F90" "${QE_F90}"
if test x"${QE_F90}" != x"${f90}"; then
  FC_OLD=${f90}
  unset FC f90 ac_cv_prog_ac_ct_FC ac_cv_fc_compiler_gnu ac_cv_prog_fc_g ac_cv_fc_libs
  AC_PROG_FC( ${QE_F90})
  AC_MSG_WARN([Overloading F90 due to QE, old=${FC_OLD} new=${FC}])
  AC_SUBST( f90, ["$FC"] )
fi


dnl ## attempt extracting MPIF90
QE_MPIF90=$(grep "MPIF90 * =" ${QE_PATH}/make.inc|cut -d "=" -f 2 | tr -d '[[:space:]]')
echo "QE_MPIF90" "${QE_MPIF90}"
if test x"${QE_MPIF90}" != x"${mpif90}"; then
  FC_OLD=${mpif90}
  unset mpif90
  AC_MSG_WARN([Overloading MPIF90 due to QE, old=${FC_OLD} new=${QE_MPIF90}])
  AC_SUBST( mpif90, ["$QE_MPIF90"] )
fi


dnl ## attempt extracting LAPACK_LIBS
QE_LAPACK_LIBS=$(grep "LAPACK_LIBS *=" ${QE_PATH}/make.inc | grep -v "SCALAPACK" |grep -v "\#"|cut -d "=" -f 2)
if test x"${QE_LAPACK_LIBS}" != x""; then
  AC_MSG_WARN([Adding QE LAPACK_LIBS=${QE_LAPACK_LIBS} to BLAS_LIBS])
  BLAS_LIB+=${QE_LAPACK_LIBS}
  AC_SUBST(BLAS_LIB)
fi


dnl ## attempt extracting BLAS_LIBS
QE_BLAS_LIBS=$(grep "BLAS_LIBS *=" ${QE_PATH}/make.inc |grep -v "\#"|cut -d "=" -f 2)
if test x"${QE_BLAS_LIBS}" != x""; then
  AC_MSG_WARN([Adding QE BLAS_LIBS=${QE_BLAS_LIBS} to BLAS_LIBS])
  BLAS_LIB+=${QE_BLAS_LIBS}
  AC_SUBST(BLAS_LIB)
fi


dnl ## check if libartn.so is already added
dnl ## NOTE: add check if the line is equal to present topdir, it could be another dir..
b=$(grep "libartn" ${QE_PATH}/make.inc)
if test "$b" == ""; then
  dnl ## append line to end of make.inc
  echo "QELIBS+=${topdir}/src/libartn.so" >> ${QE_PATH}/make.inc
  echo "LIBOBJS+=${topdir}/src/libartn.so" >> ${QE_PATH}/make.inc
fi

dnl ## check if bin/pw.x exists, print notice if not.
pw=0
AC_CHECK_FILE([${QE_PATH}/bin/pw.x],[pw=1],[pw=0])
if test "$pw" == 1; then
  dnl ## try to see if pw is compiled with libartn or not
  lstr=$(ldd ${QE_PATH}/bin/pw.x | grep "libartn")
  if test "${lstr}" == ""; then
    dnl ## did not find libartn in ldd
    pw=2
  fi
fi

pw_compile_str="The pw.x of QE in ${QE_PATH} needs to be (re-)compiled after compiling pARTn."
if test "$pw" == 1; then
  unset pw_compile_str
  pw_compile_str=""
fi
echo "pw" "$pw"
AC_SUBST(pw_compile_str)
fi
])
