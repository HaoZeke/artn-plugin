AC_DEFUN([FIND_CONF_VASP],
[

     SECTION_TITLE([Attempting to extract info from VASP])


     dnl ## check if VASP_PATH is specified
     if test -z "$VASP_PATH" ; then
          AC_MSG_ERROR([Specify the VASP_PATH as: "./configure --with-vasp VASP_PATH=</path/to/vasp/rootdir>"],-1)
     fi

     dnl ## do other stuff ...

]
)
