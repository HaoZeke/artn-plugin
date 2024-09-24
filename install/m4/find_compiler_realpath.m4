AC_DEFUN([FIND_COMPILER_REALPATH], [

dnl ## remove any whitespace from input argument
dnl #compiler=$(echo $1 | awk '{$1=$1;print}')
compiler=$(echo $1 | sed 's/ //g')

AC_MSG_CHECKING([realpath of compiler: $compiler])
path_ok=1


dnl ## test if which() returns anything or not
my_comp=$(which "$compiler")

if test -z "$my_comp"; then
path_ok=0
fi

if test "$path_ok" = 1; then
  dnl ## get the realpath
  compiler_path=$(realpath $my_comp)
  AC_MSG_RESULT($compiler_path)
  unset compiler my_comp
  [$2]
  :
else
  AC_MSG_RESULT( not found. Check loaded modules.)
  AC_MSG_WARN([The command "which $compiler" returns null. Check if the module with compiler is loaded.])
  unset compiler my_comp
  [$3]
  :
  fi

])
