########################
Install pARTn for Siesta
########################

.. contents:: Contents
   :local:
   :depth: 1


The Siesta interface to pARTn works via the Fortran-Lua hook (FLOOK) in Siesta.

.. note::

   It is required that Siesta is built with ``-DSIESTA_WITH_FLOOK=ON``.


The compilation will create the shared lib ``libartn_lua.so``. Make sure that before using Siesta with pARTn, lua knows where to look for this library. Simplest way to do that is to add the following line (edit the correct pARTn path) into your .bashrc:

.. code:: bash

    export LUA_CPATH=$LUA_CPATH:";$HOME/artn-plugin/lib/?.so;"

Alternatively, declare the path at the beginning of the ``artn.lua`` script.

For an example how to run, see directory ``examples/Siesta.Si-vac.d/`` and the README therein.


Using ``make``
==============


#. Configure pARTn with ``--with-siesta`` and the path ``SIESTA_PATH=`` to the build directory of Siesta:

   .. code:: bash

      cd /path/to/artn-plugin
      ./configure --with-siesta SIESTA_PATH=/path/to/siesta/build

#. Compile the files from the pARTn root directory as:

   .. code:: bash

       make siestalib

   Or from the ENGINES/Siesta directory:

   .. code:: bash

       cd ENGINES/Siesta
       make



Using ``cmake``
===============

Replace ``<my_builddir>`` with the name of desired build directory of pARTn,
and insert a valid absolute path to the Siesta build directory ``</path/to/siesta/build>``.

.. code-block:: bash

   cd /path/to/artn-plugin

   # configure; replace <my_builddir> and </path/to/siesta/build>
   cmake -B <my_builddir> -DWITH_SIESTA=yes -DSIESTA_PATH=</path/to/siesta/build>

   # build, optionally with <N> processes
   cmake --build <my_builddir>  -j <N>

