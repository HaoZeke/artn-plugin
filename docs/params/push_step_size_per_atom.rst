*push_step_size_per_atom*
======================

Syntax
""""""

.. parsed-literal::

   push_step_size_per_atom = arg

* arg = real


Default
"""""""

.. code-block:: fortran

   push_step_size = 0.2


Description
"""""""""""

Maximum length of atomic displacement in the initial displacement vector.

This step size is kept fixed as long as the push direction follows the initial push vector. When pushing with eigenvector, the step size is regulated.

This parameter cannot be defined with `push_step_size` parameter. If the both are defined then it is `push_step_size_per_atom` parameter that will be conserved.

Unexpected behavior
"""""""""""""""""""

Can be limited by the E/F engine parameters. For example, when using a large ``push_step_size`` with LAMMPS, the parameter ``dmax`` of FIRE in LAMMPS should be accordingly modified when invoking ``fix artn`` in the LAMMPS input, *e.g.*:

.. code-block:: bash

   fix 3 all artn dmax 8.0



Related commands
""""""""""""""""

:doc:`push_step_size`
