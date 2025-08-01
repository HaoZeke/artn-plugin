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

Define the maximum perpendicular relaxation after a push (init/eigen)
For a better convergence it is common to increase this value as the algorithm goes closer to the saddle point.
For that it use the option :doc:`nperp_limitation` that is an array of nperp value.

If nperp and nperp_limitation are defined at the same time then the value nperp will be used as a first value of nperp (usually at initial push, in the basin),
then the value of the array nperp_limitation.

the value ``-1`` means no limitation of perp-relax and ``-2`` means NULL, not defined.


Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`nperp_limitation`
