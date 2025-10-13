Format "modified xyz"
---------------------

.. code-block:: bash

   N_atoms
   <empty line>
   idx_atom_i  x_i  y_i  z_i
   idx_atom_j  x_j  y_j  z_j
   ...


where:

 - ``N_atoms`` is the total number of atoms for which the vector is specified;
 - ``idx_atom_i`` is the integer-value index of atom for which the vector is be specified;
 - ``x_i``, ``y_i``, ``z_i`` are the real-value elements of the vector for atom ``i``.

All values are space-separated.
