
dnl ## Pre-pend compiler name from argument, to the list try_*




define([ADD_TRIAL_F90],
[
    COMPILER_NAME($1)
    if test "$name" = "opal_wrapper"; then name="mpif90"; fi
    if test -n $name; then
        case $try_f90 in
            *$name* )
                AC_MSG_NOTICE([Compiler $name already on trial list, will not add.])
                ;;

            * )
                AC_MSG_NOTICE([adding $name compiler to list])
                try_f90="$name $try_f90"
        esac
    fi
])



define([ADD_TRIAL_MPIF90],
[
    COMPILER_NAME($1)
    if test "$name" = "opal_wrapper"; then name="mpif90"; fi
    if test -n "$name";  then
        case $try_mpif90 in
            *$name* )
                AC_MSG_NOTICE([Compiler $name already on trial list, will not add.])
                ;;

            * )
                AC_MSG_NOTICE([adding $name compiler to list])
                try_mpif90="$name $try_mpif90"
        esac
    fi

])






define([ADD_TRIAL_CC],
[
    COMPILER_NAME($1)
    if test "$name" = "opal_wrapper"; then name="mpicxx"; fi
    if test -n "$name"; then
        case $try_cc in
            *$name* )
                AC_MSG_NOTICE([Compiler $name already on trial list, will not add.])
                ;;

            * )
                AC_MSG_NOTICE([adding $name compiler to list])
                try_cc="$name $try_cc"
        esac
    fi

])


define([ADD_TRIAL_CXX],
       [
           COMPILER_NAME($1)
           if test "$name" = "opal_wrapper"; then name="mpicxx"; fi
           if test -n "$name"; then
               case $try_cxx in
                   *$name* )
                       AC_MSG_NOTICE([Compiler $name already on trial list, will not add.])
                       ;;

                   * )
                       AC_MSG_NOTICE([adding $name compiler to list])
                       try_cxx="$name $try_cxx"
               esac
           fi

])




dnl ## Try to extract name of compiler from given argument (which can be full path).
define([COMPILER_NAME],
[

    name=$1
    if test "$name" = "unknown"; then
        name=""
    elif test "$name" = ""; then
        :
    else
        dnl ## try basename
        name=$(basename $1)
        # # b=$(type $name > /dev/null 2>&1)

        # # dnl ## opal_wrapper is mpif90 or mpicxx or whatever ... set both.
        # if test "$name" = "opal_wrapper"; then
        #     name="mpif90 mpicxx"
        # fi
    fi

])


dnl ## try to see if two compilers are equal.
dnl ## If they are equal, they should print the same version string
define([COMPILERS_EQUAL_F90],
[

    # AC_LANG_PUSH(Fortran)
    # AC_FC_SRCEXT(f90)
    # dnl ## save current vals
    # FC_old=$FC
    # ac_cv_prog_ac_ct_FC_old=$ac_cv_prog_ac_ct_FC
    # ac_cv_fc_compiler_gnu_old=$ac_cv_fc_compiler_gnu
    # ac_cv_prog_fc_g_old=$ac_cv_prog_fc_g
    # ac_cv_fc_libs_old=$ac_cv_fc_libs
    # LDFLAGS_old=$LDFLAGS
    # CFLAGS_old=$CFLAGS
    # FLIBS_old=$FLIBS
    # FCLIBS_old=$FCLIBS
    # LIBS_old=$LIBS
    # dnl ## unset all
    # unset FC ac_cv_prog_ac_ct_FC ac_cv_fc_compiler_gnu ac_cv_prog_fc_g ac_cv_fc_libs
    # unset LDFLAGS CFLAGS FLIBS FCLIBS LIBS

    # dnl ## set FC to first argument
    # FC="$1"
    # dnl ## get version string
    F90_VERSION_2($1)
    version_a=$f90_version
    echo "$FC version_a" "$version_a"

    # unset FC ac_cv_prog_ac_ct_FC ac_cv_fc_compiler_gnu ac_cv_prog_fc_g ac_cv_fc_libs
    # unset LDFLAGS CFLAGS FLIBS FCLIBS LIBS

    # FC="$2"
    F90_VERSION_2($2)
    version_b="$f90_version"
    echo "$FC version_b" "$version_b"

    # dnl ## put back the values
    # FC=$FC_old
    # ac_cv_prog_ac_ct_FC=$ac_cv_prog_ac_ct_FC_old
    # ac_cv_fc_compiler_gnu=$ac_cv_fc_compiler_gnu_old
    # ac_cv_prog_fc_g=$ac_cv_prog_fc_g_old
    # ac_cv_fc_libs=$ac_cv_fc_libs_old
    # LDFLAGS=$LDFLAGS_old
    # CFLAGS=$CFLAGS_old
    # FLIBS=$FLIBS_old
    # FCLIBS=$FCLIBS_old
    # LIBS=$LIBS_old

    # AC_LANG_POP(Fortran)

    compilers_equal=0
    if test "$version_a" = "$version_b" ; then
        compilers_equal=1
    fi

])





define([F90_VERSION],
[
    AC_MSG_CHECKING([F90 compiler version])

    unset b v f90_version_ok f90_version
    this_prog="
      program tmp
      use, intrinsic:: iso_fortran_env, only: compiler_version
      open(77,file='tmp',status='replace')
      write(77,'(a)') compiler_version()
      end program tmp"
    pushdef(prog, [$this_prog])

    AC_RUN_IFELSE( [AC_LANG_SOURCE([prog])],
                   dnl ## [b=$(./conftest)],
                   [b=yes
                    # v=$(./conftest)
                    v=$(cat tmp)
                    rm tmp],
                   [b=no]
                 )

    popdef([prog])

    if test x"$b" = xyes; then
        f90_version_ok=yes
        f90_version="$v"
        [$1]
    else
        f90_version_ok=no
        [$2]
    fi

    AC_SUBST(f90_version)
])


define([F90_VERSION_2],
[
    unset this_prog f90_version
    this_prog="
      program tmp
      use, intrinsic:: iso_fortran_env, only: compiler_version
      open(77,file='conftest.tmp',status='replace')
      write(77,'(a)') compiler_version()
      end program tmp"

    if test -n "$1"; then
        AC_MSG_CHECKING([F90 compiler version: $1])
        echo "$this_prog" > conftest.tmp.f90
        $1 -o conftest.tmp.x conftest.tmp.f90
        ./conftest.tmp.x
        f90_version=$(cat conftest.tmp)
        rm -rf conftest.tmp*
        AC_MSG_RESULT([$f90_version])
    fi
    unset this_prog
])
