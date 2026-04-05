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

Scale the size of the final push from saddle toward minima, when relaxing from saddle (``lpush_final = .True.``).
Is a multiplication factor, such that the size of the final push is ``push_over * eigen_step_size``.

The system is pushed from saddle once with a final push, then let to relax with regular alogirithm (i.e. FIRE).
When a minimum is reached, the system is brought back to saddle, and pushed once more in the opposite direction, and again let to relax.

Setting ``push_over`` can be useful if there is any metastable minimum appearing close to the saddle point, increasing ``push_over`` value helps to jump over it before to converge to the true minimum.

Used in the routine :doc:`../src/push_over_procedure` that perform the push of the system over the saddle point.


Unexpected behavior
"""""""""""""""""""

Related commands
""""""""""""""""

:doc:`eigen_step_size`, :doc:`lpush_final`
