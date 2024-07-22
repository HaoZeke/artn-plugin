*nnewchance*
======================

Syntax
""""""

.. parsed-literal::

   nnewchance = arg

* arg = integer


Default
"""""""

.. code-block:: bash

   nnewchance = 0


Description
"""""""""""

Number of times a research is allowed to cross a convex region (without counting the starting convex region).

When the system has reached an area on the PES where there are positive curvatures but no minimum, as an :math:`x^3` curve, the pushing vector can be modified to escape the region.

Unexpected behavior
"""""""""""""""""""

Can lead to unconnected paths.


Related commands
""""""""""""""""

:doc:`alpha_mix_cr`
