
## Interface LAMMPS version after June 2022

#### Installation/Compilation


In versions after June 2022, LAMMPS includes the ``Plugin`` Class, which allows to link LAMMPS with a dynamical library without having to recompile LAMMPS.

1. Enable the ``PLUGIN`` package, and compile LAMMPS in *shared library* mode for machine (i.e. ``mpi``, or ``serial``, etc.).
```bash
cd /path/to/LAMMPS
make yes-plugin
make mode=shared mpi
```

2. Run the ``configure`` of pARTn, giving the ``--with-lammps`` flag, and the path ``LAMMPS_PATH=`` to the lammps directory:
```bash
cd /path/to/artn-plugin
./configure --with-lammps LAMMPS_PATH=/path/to/lammps
```

At the end of ``configure``, you should get all further instructions printed on the screen. They should be pretty much as follows:

3. Compile the library ``libartn-lmp.so``:
```bash
make lmplib
```

The directory ``Files_LAMMPS`` should contain the shared library ``libartn-lmp.so``, and a link to it should be created in the ``lib`` directory.
You should now be ready to launch.

> **NOTE**
> For LAMMPS versions older than June 2022, please contact us.



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
