*push_over*
======================

Syntax
""""""

.. parsed-literal::

   push_over = arg

* arg = real


Default
"""""""

.. code-block:: bash

   push_over = 1.0


Description
"""""""""""

Scale the size of the final push from saddle toward minima.

Is a multiplication factor, such that the size of the final push is ``push_over * eigen_step_size``.

Useful if there is metastable minimum appearing close to the saddle point, increasing this factor helps to jump over it to converge to the true minimum.

Used in the routine :doc:`../src/push_over_procedure` that perform the push of the system over the saddle point.


Unexpected behavior
"""""""""""""""""""

Related commands
""""""""""""""""

:doc:`eigen_step_size`
