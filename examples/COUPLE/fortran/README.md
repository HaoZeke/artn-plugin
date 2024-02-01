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

Multiple group
========

The program `multiple_group.f90` uses openmpi `use mpi_f08`, splits the COMM into groups of many-processes, and launches a separate instance in each group.
You can specify the number of groups you want, and the number of events you want.
During the do loop over the events, the variable `ievent` is propagated to each group so that it can be used to have a different input or output caracteristic for each event.
Compile as:
```
sh compile_multiple_group.sh
```

Launch as:
```
mpiexec -np N ./multiple_group.x

The N mpi processes are splited in each group such that the size of each group is the same if N=i*ngroup or differ by 1 otherwith.
```


