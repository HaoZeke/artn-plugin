########################
Install pARTn for LAMMPS
########################

Interface LAMMPS version after June 2022
========================================

Installation/Compilation
------------------------

In versions after June 2022, LAMMPS includes the ``Plugin`` Class, which allows to link LAMMPS with a dynamical library without having to recompile LAMMPS.

The first step is to enable the ``PLUGIN`` package, and compile LAMMPS in *shared library* mode in ``mpi`` or ``serial``.

.. code-block:: bash

   cd /path/to/LAMMPS
   make yes-plugin
   make mode=shared mpi

Then, put the correct path in variable ``LAMMPS_PATH`` in file ``environment_variables``, aswell as the compilers ``CC`` or ``CXX`` in corresponding variables, which should be the same as used for compilation of LAMMPS.

Then compile ARTn with the command:

.. code-block:: bash

   cd /path/to/artn-plugin
   make sharelib

At the end of the compilation the file `libartn.so` must appear in the folder `artn-plugin/`.

.. note::
  For LAMMPS versions older than June 2022, please contact us.


Installation on Mac Os X
------------------------

Installing on  Mac Os X requires a few different operations:

1. In file ``environment_variables`` set ``BLAS_LIB= -framework Accelerate``
2. Dynamical library pathways must be set in ``DYLD_LIBRARY_PATH``

