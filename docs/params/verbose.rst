*verbose*
======================

Syntax
""""""

.. parsed-literal::

   verbose = arg

* arg = integer, possible values: 0, 1, 2, 3


Default
"""""""

.. code-block:: bash

   verbose = 0


Description
"""""""""""

level of verbosity:
 - value 0: silent mode, no ARTn output is generated. Structures can still be output to file, see :doc:`struc_format_out`.
 - value 1: minimal ARTn output, only filenames of generated structures are reported.
 - value 2: only each ARTn step is recorded in the output.
 - value 3: each step of the simulation is reported in the output.


Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`struc_format_out`
