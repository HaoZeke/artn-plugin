The Siesta/pARTn interface via lua is a work in progress. It is tested for lua-5.3, but might be ok for other versions also.
For now it works as follows:

Compile the static pARTn library, `libartn.a` with:

    cd /path/to/pARTn
    make lib

compile the files from this directory as:

    cd Files_Siesta
    sh compile


This will create the shared lib `partn.so`, which you must copy or symlink into the folder where your siesta calculation is running.
