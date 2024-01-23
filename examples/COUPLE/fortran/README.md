To run this test you need these files:
 - the lammps interface file `lammps.f90` from `/your-path-to-lammps/fortran/lammps.f90`
 - the pARTn interface file `f_partn.f90` from `/your-path-to/artn-plugin/interface/f_partn.f90`

Check the compilation files `compile_*.sh` to edit compilers and paths, etc.

single
======

The program `single.f90` is just basic interaction with lammps in serial. Compile as:
```
sh compile_serial.sh
```

Launch as:
```
./single.x
```

Multiple
========

The program `multiple_single.f90` uses openmpi `use mpi_f08`, splits the COMM into groups of single-cpus, and launches a separate instance in each group. Compile as:
```
sh compile_multiple_single.sh
```

Launch as:
```
mpiexec -np N ./multiple_single.x
```
