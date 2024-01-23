gfortran -c lammps.f90
gfortran -c f_partn.f90
mpifort -o multiple_single.x multiple_single.f90 lammps.o f_partn.o ../../../lib/libartn-lmp.so ~/lammps/lammps/src/liblammps.so 

