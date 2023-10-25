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

When ``.true.``, perform a Lanczos do loop at the new minima.
This permits to check if the minima that have been found do not have an Hessian negative eigenvalue,
in which case the minimization has failed to reach a true minimum.
Suggestion: decrease the convergeance criterion for finding the minimum.  

This parameter must be used in combination with `lpush_final` = ``.true.`` 

Related commands
""""""""""""""""

:doc:`lpush_final`
