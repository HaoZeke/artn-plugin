The Siesta/pARTn interface via lua is a work in progress. It is tested for lua-5.3, but might be ok for other versions also.
For now it works by linking the static pARTn library ``libartn.a``.


Compile the files from this directory as:

.. code:: bash

    cd Files_Siesta
    make

Or from the pARTn root directory as:

.. code:: bash

   make siestalib

This will create the shared lib ``partn_lua.so``. Make sure that before using Siesta with pARTn, lua knows where to look for this library. Simples way to do that is to add the following line (edit the correct pARTn path) into your .bashrc:

.. code:: bash

    export LUA_CPATH=$LUA_CPATH:";$HOME/artn-plugin/Files_Siesta/?.so;"

Alternatively, declare the path at the beginning of the ``artn.lua`` script.

For an example how to run, see directory ``examples/Si-vac.Siesta.d/`` and the README therein.
