.. _installation:

Installation
============

.. warning::
   If you are using ``gfortran``, the version should be at least 9.4.0



Depending on your build-system of choice (``make`` or ``cmake``), the steps to compile pARTn are as follows:

0. Clone the artn-plugin project:

   .. code::

      git clone https://gitlab.com/mammasmias/artn-plugin.git


.. tab-set::

   .. tab-item:: Using ``make``

      #. Before compiling, run the ``./configure`` script:

         .. code-block:: bash

            cd /path/to/artn-plugin
            ./configure

         To configure pARTn for a specific engine, give two arguments to ``configure``; the flag ``--with-<engine>``, and a valid path to the engine code ``<ENGINE>_PATH=``:

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


   .. tab-item:: Using ``cmake``

      #. Create and configure your build directory (insert ``<my_builddir>``):

         .. code-block:: bash

            cd /path/to/artn-plugin
            cmake -B <my_builddir>

         To configure pARTn for a specific engine, define two arguments for ``cmake``;
         the flag ``-D WITH_<ENGINE>=yes``, and ``-D <ENGINE>_PATH=`` the absolute path to the engine code/build directory:

         .. code-block:: bash

            cmake -B <my_builddir>    -D WITH_<ENGINE>=yes   -D <ENGINE>_PATH=....

         For example with ``qe`` and/or ``lammps``:

         .. code-block:: bash

            ## configuring for Quantum Espresso as the engine:
            cmake -B mybuild -DWITH_QE=yes -DQE_PATH=/path/to/qe

            ## for lammps:
            cmake -B mybuild -DWITH_LAMMPS=yes -DLAMMPS_PATH=/path/to/lammps

            ## for QE and lammps together:
            cmake -B mybuild \
                         -DWITH_QE=yes     -DQE_PATH=/path/to/qe \
                         -DWITH_LAMMPS=yes -DLAMMPS_PATH=/path/to/lammps


         This step will check if the given engine is properly configured, and ready to link with pARTn.

         .. warning::

            Compilation with ``cmake`` and VASP engine is currently not supported.


      #. Upon successful configuration, compile with:

         .. code-block:: bash

            cmake --build <my_builddir>



      .. note::

         The base dependency requirement are lapack/blas and cmake. If building for lammps this also require MPI.

         On linux (e.g. ubuntu), you might install:

         .. code-block:: bash

           sudo apt install libopenblas-dev liblapack-dev cmake libopenmpi-dev openmpi-bin

         On MacOS (with brew), (additionaly require GCC for gfortran (or an other fortran compiler (not tested)))

         .. code-block:: bash

           brew install gcc
           brew install openblas cmake open-mpi

      .. note::
         CMake auto-select compilers from available ones, to set the compilers manualy set at the configure step:

         .. code-block:: bash

            # Generic example
            cmake -B <my_builddir> -DCMAKE_C_COMPILER=/path/to/CCompiler \
                                   -DCMAKE_CXX_COMPILER=/path/to/CXXCompiler \
                                   -DCMAKE_Fortran_COMPILER=/path/to/FCompiler

            # for GNU compilers
            cmake -B <my_builddir> -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_Fortran_COMPILER=gfortran
            # for IntelLLVM compilers
            cmake -B <my_builddir> -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx -DCMAKE_Fortran_COMPILER=ifx

      .. note:: For MacOS

         On MacOS, by default, CMake tends to pick the AppleClang compilers mixed with the Fortran compiler of an other family (there is no Fortran AppleClang compiler on MacOS).
         This can create linking problems.
         If you enconter problems, set the compilers so they are all of the same family.
         Although right now, it works with mixed family compilers (AppleClang C/CXX with GNU Fortran).

         .. code-block:: bash

            export GCC=$(brew --prefix gcc)/bin
            # example for GCC 15
            cmake -B <my_builddir> -DCMAKE_Fortran_COMPILER=$GCC/gfortran-15 -DCMAKE_C_COMPILER=$GCC/gcc-15 -DCMAKE_CXX_COMPILER=$GCC/g++-15


More details:
-------------

.. toctree::
    :maxdepth: 1

    install_qe
    install_lammps
    install_siesta
    install_VASP


