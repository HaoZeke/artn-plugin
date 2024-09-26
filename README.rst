############
Introduction
############

This is a working repository of the current version of the plugin-ARTn; currently it can be used with Quantum ESPRESSO and LAMMPS.
This code has been developed in collaboration by Matic Poberznik, Miha Gunde, Nicolas Salles and Antoine Jay.

.. image:: ./.extra/ARTn_workflow-2.png
   :scale: 8 %
   :alt: ARTn workflow schema

The algorithm `ARTn`_ allows the exploration of the energetic landscape of an atomic configuration, to find the saddle point (transition state), and the associated energy minima.

.. _ARTn: https://normandmousseau.com/ART-nouveau.html

Documentation:
==============

The full documentation is available at: `LINK`_.
Please post any issue(s) on `GitLab`_.

.. _GitLab: https://gitlab.com/mammasmias/artn-plugin
.. _LINK: https://mammasmias.gitlab.io/artn-plugin/


Contains:
=========

- ``examples/``: Contains many examples, from molecules to surfaces;
- ``Files_LAMMPS/``: Contains the lammps fix, for the LAMMPS/ARTn interface;
- ``Files_QE/``: Contains the file `plugin_ext_forces.f90`, for the QE/ARTn interface;
- ``README.md``: This file;
- ``src/``: ARTn plugin subroutines;
- ``Makefile``: Compilation commands, uses the environment variables defined in `environment_variables`;
- ``environment_variables``: custom file defining:
	- compilers ``F90``, ``CXX``/``CC``;
	- the paths to ARTn (current directory), BLAS and FORTRAN libraries, and chosen engine(s) QE/LAMMPS;
	- ``PARA_PREFIX`` prefix for launching examples via provided run scripts.



Interface with engine
=====================

Two interfaces are developed for the moment:

- **Quantum ESPRESSO**: To use it read the :ref:`installation`.
- **LAMMPS**. Two versions exist depending on the version of LAMMPS.
    #. One using the class `Plugin`_ of LAMMPS, for this version please read :ref:`install_lammps_new`
    #. The second one does not use the class plugin of LAMMPS because this class exist only since 2022. If you use a version older than 2022 please read the :ref:`install_lammps_old`

.. _Plugin: https://docs.lammps.org/plugin.html


Examples
========

The list of :ref:`examples` using both interfaces.


Using ARTn
==========

The installation depends on the Energy/Forces engine you want to use.
For the impatient, typing:

.. code-block:: bash

   make help

should give you some idea what to do.

For complete information please read documentation on the `installation`_.
To customise the input of ARTn read the section `input`_.
The different output files are explained in section `output`_.

.. _installation: https://mammasmias.gitlab.io/artn-plugin/sections/Installation.html
.. _input: https://mammasmias.gitlab.io/artn-plugin/sections/artn_input.html
.. _output: https://mammasmias.gitlab.io/artn-plugin/sections/Output.html


Build and configure with CMake
------------------------------

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


Issues, bugs, requests
======================

Use the `issue`_ tracker to report the bugs.

.. _issue: https://gitlab.com/mammasmias/artn-plugin/-/issues


License
========

`Terms of use`_. 

.. _Terms of use: ../../TERMS_OF_USE


Citation
========

Please cite the article of this project:

`pARTn: a plugin implementation of the Activation Relaxation Technique nouveau hijacking a minimisation algorithm`, **Computer Physics Comunication** 295, 108961 (2024), M. Poberznik, M. Gunde, N. Salles, A. Jay, A. Hemeryck, N. Richard, N. Mousseau and L. Martin-Samos




