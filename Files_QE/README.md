# QE/pARTn Interface


1. First ``configure`` QE. For QE-7.2 or newer, you have to enable the plugins:

```bash
cd /path/to/QE
./configure --enable-legacy_plugins
```

2. Run the ``configure`` of pARTn, giving the flag ``--with-qe`` and the path ``QE_PATH=`` to the root directory of QE:

```bash
cd /path/to/artn-plugin
./configure --with-qe QE_PATH=/path/to/qe
```

At the end of ``configure``, you should get all further instructions printed on the screen. They should be pretty much as follows:


3. Compile the pARTn library:

```bash
make lib
```


4. If this is the first time you are compiling pARTn for QE, you will need to execute a patch command. This command will patch the QE file ``plugin_ext_forces.f90`` with a call to pARTn, and add the pARTn library to QE libraries.

```bash
make patch-qe
```


5. Then you will most likely need to re-compile ``pw`` of QE:

```bash
cd /path/to/QE
make pw -j2
```


Now you are ready to launch QE, perhaps test your compilation by running the example ``examples/Al-vacancy.QE.d``, which should run quite fast even in a serial calculation:
```bash
cd /path/to/artn-plugin/examples/Al-vacancy.QE.d
./path/to/QE/bin/pw.x -partn < relax.Al-vacancy.in
```


> **NOTE**
>   * QE versions < 7.1: the ``configure`` of QE in step 1) is done without ``--enable-legacy_plugins``;
>   * QE version 7.1 is not supported;
>   * QE version 7.2 needs a minor modification in the code to work properly.


## How to run ARTn with QE:

For example calculations please see the `examples` directory. A brief
description of the minimum requirements is provided here.

In order to run an ARTn calculation you have to add the following
lines to the QE input file `pwscf.in`:

```fortran
&CONTROL
 calculation = 'relax' 
/

&SYSTEM
  nosym = .true. 
/

&IONS
  ion_dynamics = 'fire' 
/
```

Finally Quantum ESPRESSO must be launched with the flag -partn as follow:

```bash
./pw.x -partn -inp input_pw.txt
```

