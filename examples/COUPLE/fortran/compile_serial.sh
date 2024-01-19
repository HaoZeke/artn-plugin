gfortran -c lammps.f90
gfortran -c f_partn.f90
gfortran -o single.x single.f90 f_partn.o lammps.o ../../../lib/libartn-lmp.so ~/lammps/lammps/src/liblammps.so
