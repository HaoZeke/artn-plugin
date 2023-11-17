.. _install_lammps_new:

Interface LAMMPS version after June 2022
========================================

Installation/Compilation
------------------------

In versions after June 2022, LAMMPS includes the ``Plugin`` Class, which allows to link LAMMPS with a dynamical library without having to recompile LAMMPS.

The first step is to enable the ``PLUGIN`` package, and compile LAMMPS in *shared library* mode for machine (i.e. ``mpi``, or ``serial``, etc.).

.. code-block:: bash

   cd /path/to/LAMMPS
   make yes-plugin
   make mode=shared mpi

Then, write the path to LAMMPS root directory into variable ``LAMMPS_PATH`` in file ``environment_variables``, aswell as the compilers ``CC`` or ``CXX`` in corresponding variables, which should be the same as used for compilation of LAMMPS.

Then compile ARTn with the command:

.. code-block:: bash

   cd /path/to/artn-plugin
   make lmplib

At the end of the compilation the directory `Files_LAMMPS` should contain the shared library `libartn-lmp.so`, and a link to it should be created in the `lib` directory.

.. note::
  For LAMMPS versions older than June 2022, please contact us.

