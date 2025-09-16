.. _install_lammps_new:

########################
Install pARTn for LAMMPS
########################

.. contents:: Contents
   :local:
   :depth: 1


Interface to LAMMPS versions after June 2022.

.. note::
  For LAMMPS versions older than June 2022, please contact us.


Using ``make``
==============

In versions after June 2022, LAMMPS includes the ``Plugin`` Class, which allows to link LAMMPS with a dynamical library without having to recompile LAMMPS.

#. Enable the ``PLUGIN`` package, and compile LAMMPS in *shared library* mode for machine (i.e. ``mpi``, or ``serial``, etc.).

   .. code-block:: bash

      cd /path/to/LAMMPS
      make yes-plugin
      make mode=shared mpi

#. Run the ``configure`` of pARTn, giving the ``--with-lammps`` flag, and the path ``LAMMPS_PATH=`` to the lammps directory:

   .. code-block:: bash

      cd /path/to/artn-plugin
      ./configure --with-lammps LAMMPS_PATH=/path/to/lammps

   .. note::

      If you compiled lammps using ``cmake``, then point the ``LAMMPS_PATH`` to the build dir.


   At the end of ``configure``, you should get all further instructions printed on the screen. They should be pretty much as follows:

#. Compile the library ``libartn-lmp.so``:

   .. code-block:: bash

      make lmplib

The directory ``Files_LAMMPS`` should contain the shared library ``libartn-lmp.so``, and a link to it should be created in the ``lib`` directory.
You should now be ready to launch. Load the ``fix artn`` into lammps by loading the ``libartn-lmp.so`` through the ``plugin load`` command:

.. code-block:: bash

   plugin load /path/to/artn-plugin/lib/libartn-lmp.so
   fix ID all artn args value


.. note::
   The ``configure`` script will search for your ``/path/to/LAMMPS/liblammps.so`` file,
   which normally points to the currently used LAMMPS executable. It will deduce all
   the information from there. So if you want to change to a different version of LAMMPS which
   is located in the same LAMMPS path, you need to change the location where ``liblammps.so`` links to,
   and re-configure and compile.


Using ``cmake``
===============

.. note::

   The CMake compilation project for lammps requires an MPI installation on the system.


* If you already have LAMMPS on your computer, then execute the following.
  Replace ``<my_builddir>`` with the name of desired build directory of pARTn,
  and insert a valid absolute path ``</path/to/lammps>``.

  .. code-block:: bash

     cd /path/to/artn-plugin

     # configure; replace <my_builddir> and </path/to/lammps>
     cmake -B <my_builddir> -DWITH_LAMMPS=yes -DLAMMPS_PATH=</path/to/lammps>

     # build, optionally with <N> processes
     cmake --build <my_builddir>  -j <N>

  .. note::

     | If LAMMPS was built with ``cmake`` then ``LAMMPS_PATH`` should point to the uild directory.
     | If LAMMPS was built with ``make`` then ``LAMMPS_PATH`` should point to the root directory.


* If you do not have LAMMPS on your computer, and wish to clone it from git,
  then you can skip the argument ``-D LAMMPS_PATH=...``, as:

  .. code-block:: bash

     cd /path/to/artn-plugin

     # this will clone lammps/release branch from git; replace <my_builddir>
     cmake -B <my_builddir> -DWITH_LAMMPS=yes

     # OPTIONAL: in order to specify custom packages/options to lammps,
     # add them to the above command, (i.e. <PACKAGE> is the lammps package name):
     cmake -B <my_builddir> -DWITH_LAMMPS=yes -DPKG_<PACKAGE>=yes

     # compile lammps with pARTn; insert <N> for number of processes
     cmake --build <my_builddir>  -j <N>

  The ``lmp`` binary should be then located in ``<my_builddir>``.
