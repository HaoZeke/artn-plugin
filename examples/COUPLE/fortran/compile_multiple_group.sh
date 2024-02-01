gfortran -c lammps.f90
gfortran -c f_partn.f90
mpifort -o multiple_group.x  -g -fcheck=all -Wall multiple_group.f90 lammps.o f_partn.o ../../../lib/libartn-lmp.so $LAMMPS_PATH/liblammps.so 

