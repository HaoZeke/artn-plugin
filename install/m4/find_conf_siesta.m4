AC_DEFUN([FIND_CONF_SIESTA], [



SECTION_TITLE(Checking the siesta configuration)

echo "in find f90 siesta"


dnl ## check if path is build.. there should be Src/siesta
fname="${SIESTA_PATH}/Src/siesta"
AC_CHECK_FILE(
[$fname],
[AC_SUBST(SIESTA_PATH)],
[AC_MSG_ERROR([Siesta is not compiled, or SIESTA_PATH is not a valid siesta build directory.],-1)]
)


dnl ## check for compilers
unset fname
fname="${SIESTA_PATH}/CMakeCache.txt"
dnl ## check for f90
siesta_f90=$(realpath $(grep "CMAKE_Fortran_COMPILER:FILEPATH" $fname | cut -d "=" -f 2))
echo "siesta_f90" "${siesta_f90}"

dnl ## check for mpif90
siesta_mpif90=$(realpath $(grep "MPI_Fortran_COMPILER:FILEPATH" $fname | cut -d "=" -f 2))
echo "siesta_mpif90" "${siesta_mpif90}"

dnl ## check realpath of compilers .. and if its exists
FIND_COMPILER_REALPATH( [$siesta_f90], [siesta_f90_ok=1], [siesta_f90_ok=-1] )
if test "$siesta_f90_ok" = -1; then AC_MSG_ERROR([Compiler "$siesta_f90" not found. Stopping.]); fi
siesta_f90=$compiler_path

FIND_COMPILER_REALPATH( [$siesta_mpif90], [siesta_mpif90_ok=1], [siesta_mpif90_ok=-1] )
if test "$siesta_mpif90_ok" = -1; then AC_MSG_ERROR([Compiler "$siesta_mpif90" not found. Stopping.]); fi
siesta_mpif90=$compiler_path


dnl ## check if FLOOK is turned on
has_flook=$(grep -c "SIESTA_WITH_FLOOK:BOOL=ON" $fname)
if test "$has_flook" = 0 ; then
AC_MSG_ERROR([Siesta has to be configured with flook: -DSIESTA_WITH_FLOOK=ON.])
fi
echo "has_flook" "$has_flook"


])
