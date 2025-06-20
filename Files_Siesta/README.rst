########################
Install pARTn for Siesta
########################


The Siesta/pARTn interface via lua is a work in progress. It is tested for Siesta-5.0.1, and lua-5.3, but might be ok for other versions also.

It is required that Siesta is built with ``-DSIESTA_WITH_FLOOK=ON``.

#. Configure pARTn with ``--with-siesta`` and the path ``SIESTA_PATH=`` to the build directory of Siesta:

   .. code:: bash

      cd /path/to/artn-plugin
      ./configure --with-siesta SIESTA_PATH=/path/to/siesta/build

#. Compile the files from the pARTn root directory as:

   .. code:: bash

       make siestalib

   Or from the Files_Siesta directory:

   .. code:: bash

       cd Files_Siesta
       make

This will create the shared lib ``partn_lua.so``. Make sure that before using Siesta with pARTn, lua knows where to look for this library. Simplest way to do that is to add the following line (edit the correct pARTn path) into your .bashrc:

.. code:: bash

    export LUA_CPATH=$LUA_CPATH:";$HOME/artn-plugin/Files_Siesta/?.so;"

Alternatively, declare the path at the beginning of the ``artn.lua`` script.

For an example how to run, see directory ``examples/Si-vac.Siesta.d/`` and the README therein.
