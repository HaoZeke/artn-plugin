.. _installation:

Installation
============

.. warning::
   If you are using ``gfortran``, the version should be at least 9.4.0


Using ``configure`` and ``make``
--------------------------------

#. Before compiling, run the ``./configure`` script:

   .. code-block:: bash

      cd /path/to/artn-plugin
      ./configure

   To configure pARTn for a specific engine, you have to give two arguments to ``configure``, the flag ``--with-<engine>``, and a valid path to the engine code ``<ENGINE>_PATH=``:

   .. code-block:: bash

      ./configure    --with-<engine>    <ENGINE>_PATH=....

   For example with ``qe`` and/or ``lammps``:

   .. code-block:: bash

      ## configuring for Quantum Espresso as the engine:
      ./configure --with-qe QE_PATH=/path/to/Q-E

      ## for lammps:
      ./configure --with-lammps LAMMPS_PATH=/path/to/lammps

      ## for QE and lammps together:
      ./configure --with-qe QE_PATH=/path/to/Q-E --with-lammps LAMMPS_PATH=/path/to/lammps


   The ``configure`` script will check if the given engine is properly configured, and ready to link with pARTn.

#. Upon successful configuration, the file ``make.inc`` is written. The instructions about what to do next will be printed on screen under the line:

   .. code-block:: bash

      #>> execute the following commands to complete pARTn compilation:


More complete details on compilation for a specific engine are given below.

.. toctree::
    :maxdepth: 1

    install_qe
    install_lammps
    install_siesta
    install_VASP



Build and configure with CMake (only lammps and QE)
---------------------------------------------------

Clone artn-plugin project.

.. code::

    git clone https://gitlab.com/mammasmias/artn-plugin.git
    cd artn-plugin && mkdir build && cd build

**To build artn-plugin along with lammps:**

Configure and compile the project with (fetching lammps from git automaticaly):

.. code::

  cmake .. -DWITH_LAMMPS=yes
  cmake --build . --target lmp -j16

If you areally have clone lammps you can use the following commands:

If you are compiling lammps with cmake, configure lammps with ``cmake ../cmake -DPKG_MANYBODY=yes -DPKG_PLUGIN=yes -DBUILD_SHARED_LIBS=yes`` or with make with ``make yes-manybody && make yes-plugin && make mode=shared mpi``. 
For artn-plugin configure and compile the project with (this won't fetch lammps from git):

.. code::

  cmake .. -DWITH_LAMMPS=yes -DLAMMPS_ROOT=/path/to/lammps
  cmake --build . --target artn -j16

**To build artn-plugin along with qe:**

For artn-plugin configure and compile the project with (fetching qe from git automaticaly):

.. code::

  cmake .. -DWITH_QE=yes
  cmake --build . --target pw -j16


If you areally have clone qe you can use the following commands:

With cmake, configure qe with ``cmake .. -DQE_ENABLE_PLUGINS="legacy"`` or with make with ``./configure --enable-legacy_plugins && make pw``. 

For artn-plugin configure and compile the project with eider (1.) or (2.) (this won't fetch qe from git):

1. CMake: If you builded qe with cmake use (``-DQE_CMAKE`` set the path to the cmake build directory inside ``QE_ROOT``):

.. code::

  cmake .. -DWITH_QE=yes -DQE_ROOT=/path/to/qe -DQE_CMAKE=build
  cmake --build . --target artn

2. Make: If you builded qe with make use:

.. code::

  cmake .. -DWITH_QE=yes -DQE_ROOT=/path/to/qe -DQE_MAKE=yes
  cmake --build . --target artn

If neider ``-DQE_MAKE`` or ``-DQE_CMAKE`` are set, just rebuild qe after building artn-plugin.


To build artn-plugin only.

.. code::

  cmake ../
  cmake --build .

In all case, at the build step, it is possible to increase the number of core(N) used for compilation by adding -jN at the end of the command (e.g. ``cmake --build . --target artn -j16``).

