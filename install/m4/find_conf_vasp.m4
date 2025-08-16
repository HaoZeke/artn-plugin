AC_DEFUN([FIND_CONF_VASP],
[

    SECTION_TITLE([Attempting to extract info from VASP])


    dnl ## check if VASP_PATH is specified
    if test -z "$VASP_PATH" ; then
         AC_MSG_ERROR([Specify the VASP_PATH as: "./configure --with-vasp VASP_PATH=</path/to/vasp/rootdir>"],-1)
    fi

    dnl ## try to find the src/main.F file in VASP_PATH, to confirm the path is good
    loc=0
    AC_CHECK_FILE(["${VASP_PATH}/src/main.F"], [loc=1], [])
    if test "$loc" == 0; then
        dnl ## maybe the path to VASP/src/ or VASP/build is passed?
        AC_CHECK_FILE(["${VASP_PATH}/main.F"],[loc=2], [])
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


    dnl ## try to extract vasp version from src/main.F
    dnl ## vers=$(sed -En '{N; s/.*CHARACTER.*VASP.*(vasp[^\b]+)\b.*/\1/p}' ${VASP_PATH}/src/main.F)
    VASP_VERSION=""
    vers=$(grep -a1 -E '.*CHARACTER.*VASP.*' ${VASP_PATH}/src/main.F|tail -n 1|cut -d "'" -f 2)
    if test -n "$vers"; then
        echo "found vasp version:" $vers
    else
        echo "Could not determine VASP version."
    fi
    AC_SUBST(VASP_VERSION,["$vers"])

    vasp_major=$(echo $VASP_VERSION | cut -sd "." -f 2)
    vasp_minor=$(echo $VASP_VERSION | cut -sd "." -f 3)
    vasp_patch=$(echo $VASP_VERSION | cut -sd "." -f 4)
    vasp_descr=$(echo $VASP_VERSION | cut -sd "." -f 5)

    dnl ## ===============
    dnl ## space for doing things specific to vasp version.
    dnl ## ...
    dnl ## ===============



    dnl ## check if makefile.include exists
    AC_CHECK_FILE([${VASP_PATH}/makefile.include],
                  [],
                  [AC_MSG_ERROR([VASP is not configured. Go to ${VASP_PATH} and chose your correct makefile.include from the arch directory, then come back])],2)


    dnl ## grep for FCL in the makefile.include... there is also FC but seems we need FCL
    dnl ## This compiler needs to be forced on pArt as F90
    dnl # vasp_f90=$(grep "FCL" ${VASP_PATH}/makefile.include |grep -v "\#"|cut -d "=" -f 2 |tr -d '[[:space:]]')
    vasp_f90=$(grep "FCL" ${VASP_PATH}/makefile.include |grep -v "\#"|cut -d "=" -f 2)
    vasp_f90=$(echo $vasp_f90 | sed 's/ +//g')

    dnl ## strip flags, we do not need them for pART
    COMPILER_NAME($vasp_f90)
    vasp_f90=$name

    dnl ## check if this compiler exists (is loaded)
    FIND_COMPILER_REALPATH( [$vasp_f90],    [f90_ok=1], [f90_ok=-1] )
    if test "$f90_ok" = -1; then
        AC_MSG_WARN([VASP F90 compiler "$vasp_f90" not found.])
    else
        # vasp_f90=$compiler_path
        :
    fi

    echo "vasp_f90:" "${vasp_f90}"
    AC_SUBST(vasp_f90)


    dnl ## check if libartn.so is already added into VASP makefile.inclue
    dnl ## NOTE: add check if the line is equal to present topdir, it could be another dir..
    b=$(grep "lartn" ${VASP_PATH}/makefile.include)
    full=$(grep "\-L${topdir}/src/ -lartn -Wl,-rpath,${topdir}/src" ${VASP_PATH}/makefile.include)
    if test -z "$b"; then b="x"; fi
    if test "$b" != "$full"; then
      echo "LLIBS += -L${topdir}/src/ -lartn -Wl,-rpath,${topdir}/src" >> ${VASP_PATH}/makefile.include
      echo "INCS  += -I${topdir}/src/Obj" >> ${VASP_PATH}/makefile.include
    fi


    dnl ## does VASP/src/main.F contains call to artn?
    fname_vasp_main="${VASP_PATH}/src/main.F"
    AC_CHECK_FILE([$fname_vasp_main],[b=0],[AC_MSG_ERROR([File ${fname_vasp_main} not found?!],-1)])
    if test "$b" = 0; then
      b="$(grep -c -i 'CALL ARTN\_VASP' ${fname_vasp_main})"
      if test "$b" -gt 0; then
          dnl ## call artn is already there
          AC_MSG_NOTICE([Found 'CALL ARTN_VASP()' in ${fname_vasp_main}.])
      else
          AC_MSG_NOTICE([Adding 'CALL ARTN_VASP()' into ${fname_vasp_main}.])
          sed -i '/PARALLEL_TEMPERING*/i \ \ \ \ \ \ CALL ARTN_VASP( TIFOR, TOTEN, T_INFO, INFO, DYN, LATT_CUR, NSTEP, IO)' $VASP_PATH/src/main.F
      fi
    fi

    dnl ## Check if VASP_PATH/src/ARTn_VASP.F is already there or not, if not copy it
    vasp_diff_str=""
    fname_partn="${topdir}/ENGINES/VASP/ARTn_VASP.F"
    fname_vasp="${VASP_PATH}/src/ARTn_VASP.F"
    AC_CHECK_FILE([$fname_vasp], [b=1], [b=0])
    if test "$b" = 0; then
        AC_MSG_NOTICE([Copying ${fname_partn} into ${fname_vasp}.])
        cp ${fname_partn} ${fname_vasp}
    else
        diff=$(diff -q ${fname_partn} ${fname_vasp} | wc -l)
        dnl ## there is diff in files, need re-patching
        if test "${diff}" != "0"; then
            vasp_diff_str="There is diff in ARTn_VASP.F file, backup your changes and overwrite manually."
        fi
    fi
    AC_SUBST(vasp_diff_str)

    dnl ## Check if VASP_PATH/src/.objects contains ARTn_VASP.F
    fname_vasp_objects="${VASP_PATH}/src/.objects"
    AC_CHECK_FILE([$fname_vasp_objects],[b=0],[AC_MSG_ERROR([File ${fname_vasp_objects} not found?!],-1)])
    if test "$b" = 0; then
      b="$(grep -c -i 'ARTn\_VASP.o' ${fname_vasp_objects})"
      if test "$b" -gt 0; then
         AC_MSG_NOTICE([ARTn_VASP.o already in ${fname_vasp_objects}.])
      else
         AC_MSG_NOTICE([Adding ARTn_VASP.o to ${fname_vasp_objects}.])
         n1="$(grep -n  -m 1 dmatrix.o $VASP_PATH/src/.objects | cut -d : -f 1)"
         n2="$(grep -n  -m 2 dmatrix.o $VASP_PATH/src/.objects | cut -d : -f 1 |tail -1)"
         sed -i "${n1}i\\\tARTn_VASP.o \\\\" ${VASP_PATH}/src/.objects
         sed -i "${n2}i\\\tARTn_VASP.o \\\\" ${VASP_PATH}/src/.objects
      fi
    fi



    dnl ## check if bin/vasp_std exists, and if ldd shows libartn
    vaspstd=0
    AC_CHECK_FILE([${VASP_PATH}/build/std/vasp],[vaspstd=1],[vaspstd=0])
    if test "$vaspstd" == 1; then
        dnl ## try to see if vasp is compiled with libartn or not
        lstr=$(ldd ${VASP_PATH}/build/std/vasp | grep "libartn")
        if test "${lstr}" == ""; then
            dnl ## did not find libartn in ldd
            vaspstd=2
        fi
    fi
    vaspstd_compile_str="VASP std needs to be recompiled"
    if test "$vaspstd" == 1; then
        vaspstd_compile_str=""
    fi
    AC_SUBST(vaspstd_compile_str)

]
)
