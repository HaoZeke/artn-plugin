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

Multiplicator Factor allows to scale the push length over the saddle point.

Usefull if there is metastable minimum appearing close to the saddle point, increasing this foactor help to jump over it to converge throug the true minimum.
 
Use in the routine :doc:`../src/push_over_procedure` that perform the push of the system over the saddle point.


Unexpected behavior
"""""""""""""""""""

Related commands
""""""""""""""""

