define([F90_VERSION],[
  AC_MSG_CHECKING([compiler version])

  this_prog="use, intrinsic:: iso_fortran_env, only: compiler_version; write(*,'(a)') compiler_version(); end"
  pushdef(prog, [$this_prog])

  AC_RUN_IFELSE( [AC_LANG_SOURCE([prog])],
    dnl [b=$(./conftest)],
    [b=yes
    v=$(./conftest)],
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
