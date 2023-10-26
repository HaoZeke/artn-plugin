*lanczos_at_min*
======================

Syntax
""""""

.. parsed-literal::

   lanczos_at_min = arg

* arg = logical


Default
"""""""

.. code-block:: fortran

   lanczos_at_min = .false.


Examples
""""""""

.. code-block:: bash

   lanczos_at_min = .true.

Description
"""""""""""

When ``.true.``, perform a Lanczos procedure at the relaxed configuration.
This checks if the configuration is a minimum, which has only positive Hessian eigenvalue.
If the lowest eigenvalue is negative, the minimization has failed to reach a true minimum.
Suggestion: Decrease the convergeance criterion for finding the minimum.  

This parameter must be used in combination with `lpush_final` = ``.true.`` 

Related commands
""""""""""""""""

:doc:`lpush_final`
