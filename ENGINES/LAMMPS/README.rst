.. _install_lammps_new:

Interface LAMMPS version after June 2022
========================================

Installation/Compilation
------------------------

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
  For LAMMPS versions older than June 2022, please contact us.


.. note::
   The ``configure`` script will search for your ``/path/to/LAMMPS/liblammps.so`` file,
   which normally points to the currently used LAMMPS executable. It will deduce all
   the information from there. So if you want to change to a different version of LAMMPS which
   is located in the same LAMMPS path, you need to change the location where ``liblammps.so`` links to,
   and re-configure and compile.

