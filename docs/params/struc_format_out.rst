*struc_format_out*
======================

Syntax
""""""

.. parsed-literal::

   struc_format_out = arg

* arg = character, possible values: ``'xsf'``, ``'xyz'``, ``'none'``


Default
"""""""

When ``engine_units='qe'``, the default is:

.. code-block:: bash

   struc_format_out = 'xsf'


When ``'engine_units='lammps/mode'``, the default is:

.. code-block:: bash

   struc_format_out = 'xyz'



Description
"""""""""""

File format of the output structures (saddle, and minima).
When ``struc_format_out = 'none'``, structures are not written to any output.

This command also controls the output of ``latest_eigenvector``.


Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`engine_units`
