Description
===========

Perform a single calculation of lammps+pARTn on:

* single CPU: ``single.f90``
* multiple CPUs: ``multiple.f90``
* split the world COMM into groups: ``multiple_group.f90``

  By default will attempt to create ``ngroup=4`` groups of CPUs.
  Modify the variable according to your CPU specs in ``multiple_group.f90``.


Compile and run
---------------

For single CPU:
```
make single
./single.x
```

For multiple CPU:
```
make multiple
mpirun ./multiple.x
```

For multiple groups of CPUs:
```
make multiple_group
mpirun ./multiple_group.x
```
