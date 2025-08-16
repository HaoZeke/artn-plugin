##################################
Install pARTn for Quantum ESPRESSO
##################################

.. contents:: Contents
   :local:
   :depth: 1


Using ``make``
==============


#. First ``configure`` QE. For QE-7.2 or newer, you have to enable the plugins:

   .. code-block:: bash

      cd /path/to/QE
      ./configure --enable-legacy_plugins


#. Run the ``configure`` of pARTn, giving the flag ``--with-qe`` and the path ``QE_PATH=`` to the root directory of QE:

   .. code-block:: bash

      cd /path/to/artn-plugin
      ./configure --with-qe QE_PATH=/path/to/qe

   At the end of ``configure``, you should get all further instructions printed on the screen. They should be pretty much as follows:


#. Compile the pARTn library:

   .. code-block:: bash

      make lib


#. If this is the first time you are compiling pARTn for QE, you will need to execute a patch command. This command will patch the QE file ``plugin_ext_forces.f90`` with a call to pARTn, and add the pARTn library to QE libraries.

   .. code-block:: bash

      make patch-qe


#. Then you will most likely need to re-compile ``pw`` of QE:

   .. code-block:: bash

      cd /path/to/QE
      make pw -j2


Now you are ready to launch QE, perhaps test your compilation by running the example ``examples/Al-vacancy.QE.d``, which should run quite fast even in a serial calculation:

.. code-block:: bash

   cd /path/to/artn-plugin/examples/Al-vacancy.QE.d
   ./path/to/QE/bin/pw.x -partn < relax.Al-vacancy.in


.. note::

   * QE versions < 7.1: the ``configure`` of QE in step 1) is done without ``--enable-legacy_plugins``;
   * QE version 7.1 is not supported;
   * QE version 7.2 needs a minor modification in the code to work properly.


Using ``cmake``
===============

* If you already have a version of QE on the computer, then execute the following.
  Replace ``<my_builddir>`` with the name of desired build directory of pARTn,
  and insert a valid absolute path  ``</path/to/qe>``.

  .. code-block:: bash

     # configure; replace <my_builddir> and </path/to/qe>
     cmake -B <my_builddir> -DWITH_QE=yes -DQE_PATH=</path/to/qe>

     # build, optionally with <N> processes
     cmake --build <my_builddir>  -j <N>

  .. note::

     | If QE was built with ``cmake``, then ``QE_PATH`` should point to the build directory.
     | If QE was built with ``make``, then ``QE_PATH`` should point to the root directory.


* If you do not have a QE version on the computer, and wish to fetch it from git,
  then you can skip the argument ``-D QE_PATH=...``, as:

  .. code::

     # this will clone QE/master from git; replace <my_builddir>
     cmake -B <my_builddir> -DWITH_QE=yes

     # compile pw with pARTn; insert <N> for number of processes
     cmake --build <my_builddir> --target pw -j <N>

  The pw binary should be then located in ``<my_builddir>`` path.

