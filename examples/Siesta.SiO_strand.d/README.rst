Siesta.SiO_strand.d
-------------------

**Description**

Insertion of O atom into Si surface, from the adsorbed "strand" position.

The DFT parameters are not optimized.

The main siesta input file is ``in.fdf``, it specifies the Lua type of run, and the lua script filename:

.. code-block:: bash

   MD.TypeOfRun   Lua
   Lua.script     artn.lua

The file ``artn.lua`` is the lua script which calls pARTn at the ``siesta.MOVE`` hook point.

Run the calculation with:

.. code-block:: bash

   mpirun siesta < in.fdf

This was tested with siesta-v5.4.0
