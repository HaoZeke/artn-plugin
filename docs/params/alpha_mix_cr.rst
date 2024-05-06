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

This is the mixing coefficient used to create the push vector when the system enters into a convex region, i.e. when the negative curvature is lost.
The push vector V_CR in the convex region is defined as
V_CR=(1-alpha_mix_cr)*V_init+alpha_mix_cr*V_new,
where Vinit is the starting vector used to escape the starting convex region ad V_new a new random vector.
See Ref. XXX Jay-2024 for more information.


Unexpected behavior
"""""""""""""""""""

Using alpha_mix_cr = 0.0 can sometimes lead to cycling trajectories.

Related commands
""""""""""""""""

see nnewchance to control the maximum number convex region allowed to be crossed. 
