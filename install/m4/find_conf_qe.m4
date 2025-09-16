AC_DEFUN([FIND_CONF_QE],
[


    SECTION_TITLE([Attempting to extract info from QE])

    dnl ## check if QE_PATH is specified
    if test -z "$QE_PATH" ; then
        AC_MSG_ERROR([Specify the QE_PATH as: "./configure --with-qe QE_PATH=</path/to/qe/rootdir>"],-1)
    fi

    dnl ## try to find the configure file in QE_PATH, to confirm the path is good
    fname="${QE_PATH}/configure"
    loc=0
    AC_CHECK_FILE(["${QE_PATH}/configure"], [loc=1], [])
    if test "$loc" == 0; then
        dnl ## maybe the path to PW is passed? try one directory up
        AC_CHECK_FILE(["${QE_PATH}/../configure"],[loc=2], [])
    fi

    if test "$loc" == 0; then
        dnl ## we did not find a valid qe path
        AC_MSG_ERROR(["The QE_PATH does not seem to be correct."],-1)
    fi


    if test "$loc" == 1; then
        QE_PATH=$(realpath "${QE_PATH}")
    elif test "$loc" == 2; then
        QE_PATH=$(realpath "${QE_PATH}/../")
    fi

    AC_MSG_NOTICE([setting QE_PATH to ... ${QE_PATH}])
    AC_SUBST(QE_PATH)



    dnl ## check if make.inc exists
    AC_CHECK_FILE([${QE_PATH}/make.inc],
                  [],
                  [AC_MSG_ERROR([QE is not configured. Go to ${QE_PATH} and launch './configure --enable-legacy_plugins', then come back])],2)



    dnl ## get qe version
    m4_include([m4/find_qe_version.m4])
    FIND_QE_VERSION()
    AC_SUBST(QE_VERSION,["$ac_cv_qe_version"])
    AC_MSG_NOTICE([found QE version $ac_cv_qe_version])

    qe_major=$(echo $QE_VERSION | cut -sd "." -f 1)
    qe_minor=$(echo $QE_VERSION | cut -sd "." -f 2)
    qe_patch=$(echo $QE_VERSION | cut -sd "." -f 3)
    qe_comment=""
    dnl ## checks specific to QE version:
    if test $((qe_major)) -lt 7; then
        AC_MSG_ERROR([QE versions < 7.0 not supported directly. Contact pARTn developers if you wish to continue with this specific version of QE.],-3)
    fi
    if test $((qe_major)) -ge 7; then
        case $qe_minor in
            "0" )
                dnl ## up to 7.0 dont need anything
                ;;
            "1" )
                dnl ## 7.1 is not supported
                AC_MSG_NOTICE([The QE version 7.1 is not supported.])
                ;;
            "2" )
                dnl ## 7.2 need to comment a line in PW/src/forces.f90
                a=$(grep -n -i "use plugin_.* plugin_ext_forces" ${QE_PATH}/PW/src/forces.f90 | grep -v "!")
                if test -n "$a" ; then
                    AC_MSG_WARN([Need to comment the line: $a in ${QE_PATH}/PW/src/forces.f90])
                    qe_comment='In order to make pARTn work with QE7.2, you need to comment/delete the line: \n'$a'\n in file: '${QE_PATH}'/PW/src/forces.f90'
                fi

                dnl ## check if configured with legacy_plugins
                b=$(grep -c "D__LEGACY_PLUGINS" ${QE_PATH}/make.inc)
                if test "$b" = 0; then
                    AC_MSG_ERROR([QE not configured with --enable-legacy_plugins. Go to ${QE_PATH} and launch './configure --enable-legacy_plugins', then come back.],-3)
                fi
                ;;
            * )
                dnl ## other need --enable-legacy_plugins
                dnl ## check if configured with legacy_plugins
                b=$(grep -c "D__LEGACY_PLUGINS" ${QE_PATH}/make.inc)
                if test "$b" = 0; then
                    AC_MSG_ERROR([QE not configured with --enable-legacy_plugins. Go to ${QE_PATH} and launch './configure --enable-legacy_plugins', then come back.],-3)
                fi
                ;;
        esac
    fi


    dnl ## grep for f90 or mpif90
    qe_mpif90=$(grep "MPIF90 * =" ${QE_PATH}/make.inc|cut -d "=" -f 2 | tr -d '[[:space:]]')
    qe_f90=$(grep "F90 " ${QE_PATH}/make.inc |grep -v "\#"|grep -v "MPI"|cut -d "=" -f 2 |tr -d '[[:space:]]')


    dnl ## check if this compiler exists (is loaded)
    FIND_COMPILER_REALPATH( [$qe_f90],    [f90_ok=1], [f90_ok=-1] )
    if test "$f90_ok" = -1; then
        AC_MSG_WARN([QE F90 compiler "$qe_f90" not found.])
    else
        qe_f90=$compiler_path
    fi

    FIND_COMPILER_REALPATH( [$qe_mpif90], [mpif90_ok=1], [mpif90_ok=-1] )
    if test "$mpif90_ok" = -1; then
        AC_MSG_WARN([QE MPIF90 Compiler "$qe_mpif90" not found.])
    else
        qe_mpif90=$compiler_path
    fi


    dnl ## grep for LAPACK_LIBS and BLAS_LIBS in qe
    dnl qe_lapack=$(grep "LAPACK_LIBS *=" ${QE_PATH}/make.inc |grep -v "SCALAP"|grep -v "\#"|cut -d "=" -f 2|tr -s " "|sed s/-l//g)
    dnl qe_blas=$(grep "BLAS_LIBS *=" ${QE_PATH}/make.inc |grep -v "SCALAP"|grep -v "\#"|cut -d "=" -f 2|tr -s " "|sed s/-l//g)

    echo "in qe find f90"
    echo "qe_mpif90" "${qe_mpif90}"
    echo "qe_f90" "${qe_f90}"
    AC_SUBST(qe_f90)
    dnl echo "qe_blas" "$qe_blas"
    dnl echo "qe_lapack" "$qe_lapack"
    dnl echo "LDFLAGS" "$LDFLAGS"

dnl ## what is the name in QE/make.inc: LIBOBJS or QELIBS?
qelibs=$(grep "LIBOBJS" ${QE_PATH}/make.inc)
if test -z "${qelibs}"; then qelibs="QELIBS"; fi
dnl ## check if libartn.so is already added
dnl ## NOTE: add check if the line is equal to present topdir, it could be another dir..
b=$(grep "libartn" ${QE_PATH}/make.inc)
full=$(grep "${topdir}/lib/libartn" ${QE_PATH}/make.inc)
if test -z "$b"; then b="x"; fi
if test "$b" != "$full"; then
  dnl ## append line to end of make.inc
  echo "" >> ${QE_PATH}/make.inc
  echo "## ======= lines added by pARTn " >> ${QE_PATH}/make.inc
  echo "${qelibs} +=${topdir}/lib/libartn.so" >> ${QE_PATH}/make.inc
  echo "## ============================" >> ${QE_PATH}/make.inc
fi



dnl ## check if bin/pw.x exists, print notice if not.
pw=0
AC_CHECK_FILE([${QE_PATH}/bin/pw.x],[pw=1],[pw=0])
if test "$pw" == 1; then
  dnl ## try to see if pw is compiled with libartn or not
  lstr=$(ldd ${QE_PATH}/bin/pw.x | grep "libartn")
  if test "${lstr}" == ""; then
    dnl ## did not find libartn in ldd (can be static)
    pw=2
  fi
fi

dnl pw_compile_str="The pw.x of QE in ${QE_PATH} needs to be (re-)compiled after compiling pARTn."
pw_compile_str="pw needs to be recompiled"
if test "$pw" == 1; then
  unset pw_compile_str
  pw_compile_str=""
fi
AC_SUBST(pw_compile_str)


dnl ## check if QE_PATH/PW/src/plugin_ext_forces.f90 is already patched or not
fname_qe="${QE_PATH}/PW/src/plugin_ext_forces.f90"
fname_partn="${topdir}/ENGINES/QE/PW-src-modified/plugin_ext_forces.f90"
AC_CHECK_FILE([$fname_qe],[b=0],[AC_MSG_ERROR([File ${fname_qe} not found?!],-1)])
dnl ## does qe plugin_ext_forces contain call to artn?
if test "$b" = 0; then
  b="$(grep -c -i 'call artn' ${fname_qe})"
fi
dnl ## $b now contains number of 'call artn' counts
dnl ## test if there is diff between qe file and ours
if test "$b" -gt 0; then
  AC_CHECK_FILE([${fname_partn}],
    dnl ## s_diff=1 when there is diff, and 0 otherwise
    [s_diff=$(diff -q ${fname_qe} ${fname_partn} | wc -l)],
    [AC_MSG_ERROR([File ${fname_partn} not found!?],-1)]
  )
fi
dnl ## if $b=0 or $s_diff is non-zero, the file should be patched again
dnl ## s_diff can be empty also ... treat it as string
pw_patch_str=""
if test "$b" = 0 -o "$s_diff" != "0"; then
  unset pw_patch_str
  pw_patch_str="pw needs to be patched"
fi
if test "$b" -ne 0 -a "$s_diff" != "0"; then
  unset pw_patch_str
  pw_patch_str="pw should be re-patched (there is diff)"
fi
AC_SUBST(pw_patch_str)



])
