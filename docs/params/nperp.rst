*nperp*
======================

Syntax
""""""

.. parsed-literal::

   nperp = arg

* arg = integer


Default
"""""""

.. code-block:: bash

   nperp = def_nperp_limitation(1) = 4


Description
"""""""""""

Define the maximum perpendicular relaxation after a push (init/eigen).

The value ``-1`` means no limitation of perp-relax and ``-2`` means NULL, not defined.

For a better convergence it is common to increase this value progressively as
the algorithm gets closer to the saddle point. That is done by the option
:doc:`nperp_limitation`.

If ``nperp`` and ``nperp_limitation`` are defined at the same time, then the
value ``nperp`` will be pre-prended to the array of ``nperp_limitation``.



Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`nperp_limitation`
