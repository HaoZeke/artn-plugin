.. _installation:

Installation
============

.. warning::
   If you are using ``gfortran``, the version should be at least 9.4.0

Before compiling, run the ``./configure`` script:

.. code-block:: bash

   cd /path/to/artn-plugin
   ./configure

To configure pARTn for a specific engine, you have to give two arguments to ``configure``, the flag ``--with-<engine>``, and a valid path to the engine code ``<ENGINE>_PATH=``. For example:

.. code-block:: bash

   ## configuring for Quantum Espresso as the engine:
   ./configure --with-qe QE_PATH=/path/to/Q-E

   ## for lammps:
   ./configure --with-lammps LAMMPS_PATH=/path/to/lammps

   ## for QE and lammps together:
   ./configure --with-qe QE_PATH=/path/to/Q-E --with-lammps LAMMPS_PATH=/path/to/lammps


The ``configure`` script will check if the given engine is properly configured, and ready to link with pARTn.
Upon termination, the file ``make.inc`` should be written, and you should get instructions about what to do next.

Further details on compilation for a specific engine are given below.

.. toctree::
    :maxdepth: 1
    
    qe
    lammps
    install_siesta
    install_vasp

..    install_QE
..    install_LAMMPS
