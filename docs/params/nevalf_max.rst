*nevalf_max*
======================

Syntax
""""""

.. parsed-literal::

   nevalf_max = arg

* arg = integer


Default
"""""""

Largest value that the default integer precision allows:

.. code-block:: fortran

   nevalf_max = huge( 1 )


Examples
""""""""

.. code-block:: bash

   nevalf_max = 247

Description
"""""""""""

This option permits to stop an artn search before end when the number of force evaluations by the force engine is greater to nevalf_max. 
If the force engine already have a maximum number of steps, then the search will stop when the minimum of the two criterion will be reached.
However, it is recommanded to have nevalf_max lower than the one of the engine in order to stop correctly the search. 
In fact, when stopped from the engine, the search will not switch the actual structure to the starting one, 
whereas when stopped from the plugin, the search will be correctly stopped by switching the current structure to the starting one. 

Unexpected behavior
"""""""""""""""""""

When using the lammps interface, ``nevalf_max`` is overwritten by the number of steps splecified to lammps minus one.
For example, the last argument of the minimize command in lammps (here 500):

.. code-block::

   minimize 0.0 1.0e-6 100 500

will set ``nevalf_max=499``.


Related commands
""""""""""""""""

:doc:`push_ids`, :doc:`push_mode`
