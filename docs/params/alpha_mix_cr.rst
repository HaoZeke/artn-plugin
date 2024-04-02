*alpha_mix_cr*
======================

Syntax
""""""

.. parsed-literal::

   alpha_mix_cr = arg

* arg = real


Default
"""""""

.. code-block:: bash

   alpha_mix_cr = 0.2


Description
"""""""""""

This is the mixing coefficient :math:`\alpha_{cr}` used to create the push vector when the system enters into a convex region, i.e. when the negative curvature is lost.
The push vector :math:`V_{CR}` in the convex region is defined as
:math:`V_{CR}=(1-\alpha_{cr})*V_{init} + \alpha_{cr}*V_{new}`,
where :math:`V_{init}` is the initial vector used to escape the starting convex region and :math:`V_{new}` is a new random vector.
See Ref. XXX Jay-2024 for more information.

The value should be between 0.0 and 1.0.

Unexpected behavior
"""""""""""""""""""

Using alpha_mix_cr = 0.0 can sometimes lead to cycling trajectories.

Related commands
""""""""""""""""

See :doc:`nnewchance` to control the maximum number convex regions allowed to be crossed.
