define([F90_SRC_DIFF], [
dnl ## Function which compares two f90 source files.
dnl ## If there is no diff ${ac_ndiff}=0, and positive otherwise.
dnl ## all diff due to case switch is ignored, all commented lines are ignored,
dnl ## all empty (whitespace) lines are ignored.

dnl ## first file to compare
file_a=$1
dnl ## second file to compare
file_b=$2

dnl ## diff -i : ignore case
dnl ## diff -w : ignore whitespace changes
dnl ## grep -v -e RE1 -e RE2 : ignore patterns ("^ *!" are commented lines; "^ *$" are empty lines)
f_diff=$(diff -i -w <(grep -v -e "^ *!" -e "^ *$" $1) <(grep -v -e "^ *!" -e "^ *$" $2) )

echo f90_src_diff=${f_diff}

dnl ## return number of words in diff
ac_ndiff=$(echo ${f_diff}|wc -w)

unset f_diff
])
