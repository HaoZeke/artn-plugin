*nperp_limitation*
======================

Syntax
""""""

.. parsed-literal::

   nperp_limitation = arg

* arg = `INT(:)` integer array


Default
"""""""

.. code-block:: fortran

   nperp_limitation = [ 4, 8, 12, 16, -1 ]


Example
"""""""

.. code-block:: fortran

   nperp_limitation = [ 3, 3, 5, 10, 15, 20, -1 ]


Description
"""""""""""

Limit of perpendicular relaxation steps for each ARTn step.
More ARTn goes far from the basin more perpendicular relaxation are needed.
This option allows the user to customize the number of perp relax.
The value ``-1`` means ``no limitation`` and ``-2`` represent ``NULL``.

The size of array is automatically detected.


Unexpected behavior
"""""""""""""""""""

The sequence does not reset if eigenvalue goes positive.


Related commands
""""""""""""""""

:doc:`nperp`
