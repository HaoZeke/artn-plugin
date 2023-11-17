
## Interface LAMMPS version after June 2022

#### Installation/Compilation

For the version after June 2022, LAMMPS include the a `Plugin` Class which allows to link LAMMPS with a dynamical library without to recompile at each time.

- **In LAMMPS folder**:
  So first step is to compile LAMMPS in *"shared library"* mode in mpi or serial.

```bash
$ make mode=shared mpi
```

- **In the plugin-ARTn repository**:
  Write the path to LAMMPS root directoy into variable `LAMMPS_PATH` in file `environment_variables` as well as the compilers. The `CC` and `CXX` should be the same as used to compile LAMMPS.
  Then compile ARTn with the command:

```bash
$ make lmplib
```

At the end of the compilation the directory `Files_LAMMPS` should contain the shared library `libaartn-lmp.so`, and a link to it should be created in the `lib` directory.


#### Use fix/artn

To be able to use the `Fix/ARTn` the plugin ARTn has to be loaded.
To load the library `libartn-lmp.so` use the command:

```bash
plugin  load  /Path-to-artn-plugin/lib/libartn-lmp.so
```

Then you can activate the `Fix/ARTn` like all other fix in lammps:

```bash
fix ID group-ID style args value
```

with `style = artn`. For the moment we only test `group-ID = all`. It is possible to custom the FIRE parameters you want to use with the fix ARTn. For each parameter  you give the `name` following by the `value`. The parameters can be:

-  `alpha `
-  `alphashrink` 
-  `dtshrink`  
-  `dmax `
-  `tmax `
-  `tmin` 

To see the meaning of these parameters refere to the min_fire web page of LAMMPS.
