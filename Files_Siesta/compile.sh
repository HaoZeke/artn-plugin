gfortran -fdefault-real-8 -c lua.f90
#mpif90 -fdefault-real-8 -shared -fPIC -o partn_lua.so this.f90 lua.o printstack.o -llua5.3 /home/mgunde/qe/artn-plugin-qe/src/libartn.a
mpif90 -fdefault-real-8 -shared -fPIC -o partn_lua.so partn_lua.f90 lua.o -llua5.3 ../src/libartn.a
