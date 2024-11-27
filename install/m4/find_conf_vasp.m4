AC_DEFUN([FIND_CONF_VASP],
[

    SECTION_TITLE([Attempting to extract info from VASP])


    dnl ## check if VASP_PATH is specified
    if test -z "$VASP_PATH" ; then
         AC_MSG_ERROR([Specify the VASP_PATH as: "./configure --with-vasp VASP_PATH=</path/to/vasp/rootdir>"],-1)
    fi

    dnl ## try to find the diff.patch file in VASP_PATH, to confirm the path is good
    fname="${VASP_PATH}/diff.patch"
    loc=0
    AC_CHECK_FILE(["${VASP_PATH}/diff.patch"], [loc=1], [])
    if test "$loc" == 0; then
        dnl ## maybe the path to VASP/src/ is passed? try one directory up
        AC_CHECK_FILE(["${VASP_PATH}/../diff.patch"],[loc=2], [])
    fi

    if test "$loc" == 0; then
        dnl ## we did not find a valid qe path
        AC_MSG_ERROR(["The VASP_PATH does not seem to be correct."],-1)
    fi

    if test "$loc" == 1; then
        VASP_PATH=$(realpath "${VASP_PATH}")
    elif test "$loc" == 2; then
        VASP_PATH=$(realpath "${VASP_PATH}/../")
    fi

    AC_MSG_NOTICE([setting VASP_PATH to ... ${VASP_PATH}])
    AC_SUBST(VASP_PATH)



    dnl ## check if makefile.include exists
    AC_CHECK_FILE([${VASP_PATH}/makefile.include],
                  [],
                  [AC_MSG_ERROR([VASP is not configured. Go to ${VASP_PATH} and chose your correct makefile.include from the arch directory, then come back])],2)


    dnl ## grep for f90 or mpif90
    vasp_mpif90=$(grep "MPIF90 * =" ${VASP_PATH}/makefile.include|cut -d "=" -f 2 | tr -d '[[:space:]]')
    vasp_f90=$(grep "F90 " ${VASP_PATH}/makefile.include |grep -v "\#"|grep -v "MPI"|cut -d "=" -f 2 |tr -d '[[:space:]]')

    dnl ## check if this compiler exists (is loaded)
    FIND_COMPILER_REALPATH( [$vasp_f90],    [f90_ok=1], [f90_ok=-1] )
    if test "$f90_ok" = -1; then
        AC_MSG_WARN([VASP F90 compiler "$vasp_f90" not found.])
    else
        vasp_f90=$compiler_path
    fi

    FIND_COMPILER_REALPATH( [$vasp_mpif90], [mpif90_ok=1], [mpif90_ok=-1] )
    if test "$mpif90_ok" = -1; then
        AC_MSG_WARN([VASP MPIF90 Compiler "$vasp_mpif90" not found.])
    else
        vasp_mpif90=$compiler_path
    fi

    echo "in VASP find f90"
    echo "vasp_mpif90" "${vasp_mpif90}"
    echo "vasp_f90" "${vasp_f90}"
    AC_SUBST(qe_f90)

    dnl ## check if libartn.so is already added into VASP makefile.inclue
    dnl ## NOTE: add check if the line is equal to present topdir, it could be another dir..
    b=$(grep "libartn" ${VASP_PATH}/makefile.include)
    full=$(grep "${topdir}/src/libartn.so" ${QE_PATH}/make.inc)
    if test -z "$b"; then b="x"; fi
    if test "$b" != "$full"; then
      echo "LLIBS += ${topdir}/src/libartn.a" >> ${VASP_PATH}/make.inc
      echo "INCS  += ${topdir}/src/Obj" >> ${VASP_PATH}/make.inc
    fi

    dnl ## check if bin/vasp_std exists, print notice if not.
    vaspstd=0
    AC_CHECK_FILE([${VASP_PATH}/build/std/vasp],[std=1],[pw=0])
    if test "$vaspstd" == 1; then
      dnl ## try to see if pw is compiled with libartn or not
      lstr=$(ldd ${VASP_PATH}/build/std/vasp | grep "libartn")
      if test "${lstr}" == ""; then
        dnl ## did not find libartn in ldd
        vaspstd=2
      fi
    fi
    vaspstd_compile_str="VASP std needs to be recompiled"
    if test "$vaspstd" == 1; then
      unset vaspstd_compile_str
      vaspstd_compile_str=""
    fi
    AC_SUBST(pw_compile_str)

    dnl ## does VASP/src/main.F contains call to artn?
    fname_vasp_main="${VASP_PATH}/src/main.F"
    AC_CHECK_FILE([$fname_vasp_main],[b=0],[AC_MSG_ERROR([File ${fname_vasp_main} not found?!],-1)])
    if test "$b" = 0; then
      b="$(grep -c -i 'CALL ARTN_VASP' ${fname_vasp_main})"
      if test "$b" -gt 0; then
         vasp_patch_str="CALL ARTN_VASP already into the main.F"
      else
         vasp_patch_str="CALL ARTN_VASP have been added into the main.F"
         sed -i '/PARALLEL_TEMPERING*/i \ \ \ \ \ \ CALL ARTN_VASP( TIFOR, TOTEN, T_INFO, INFO, DYN, LATT_CUR, NSTEP, IO)' $VASP_PATH/src/main.F 
      fi
    fi
    AC_SUBST(vasp_patch_str)
    
    dnl ## Check if VASP_PATH/src/ARTn_VASP.F is already patched or not
    fname_vasp="${VASP_PATH}/src/ARTn_VASP.F"
    fname_partn="${topdir}/Files_VASP/ARTn_VASP.F"
    AC_CHECK_FILE([$fname_vasp],[b=0],[AC_MSG_ERROR([File ${fname_vasp} not found in ${VASP_PATH}/src/. Adding it],-1)])
    if test "$b" = 0; then
      cp fname_partn fname_vasp
    fi
    
    dnl ## Check if VASP_PATH/src/.objects contains ARTn_VASP.F
    fname_vasp_objects="${VASP_PATH}/src/.objects"
    AC_CHECK_FILE([$fname_vasp_objects],[b=0],[AC_MSG_ERROR([File ${fname_vasp_objects} not found?!],-1)])
    if test "$b" = 0; then
      b="$(grep -c -i ' ARTn_VASP.o' ${fname_vasp_objects})"
      if test "$b" -gt 0; then
         vasp_patch_str="ARTn_VASP.o already into the .objects"
      else
         vasp_patch_str="ARTn_VASP.o have been added into the .objects"
         n1="$(grep -n  -m 1 dmatrix.o $VASP_PATH/src/.objects | cut -d : -f 1)"
         n2="$(grep -n  -m 2 dmatrix.o $VASP_PATH/src/.objects | cut -d : -f 1 |tail -1)"
         sed -i "${n1}i\\\tARTn_VASP.o \\\\" $VASP_PATH/src/.objects 
         sed -i "${n2}i\\\tARTn_VASP.o \\\\" $VASP_PATH/src/.objects 
      fi
    fi
    AC_SUBST(vasp_patch_str)
]
)
