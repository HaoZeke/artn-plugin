.. _group_routine_artn:

Routine ARTn
============

here the list of the mains routine of ARTn algorithm

.. #doxygengroup:: ARTn
   :project: plugin-ARTn

Fortran Module:
---------------

:ref:`f90_units`
^^^^^^^^^^^^^^^^
  Contains the variable and routine relative the units of the engine.
  When a new engine interface is added, the keywords of the new engine has to be added in the routine *make_units()*

:ref:`f90_d_artn_params`
^^^^^^^^^^^^^^^^^^^^^^^^^^ 
  Contains all the variable used in the ARTn algorithm


Fortran Subroutine:
-------------------

:ref:`f90_artn`
^^^^^^^^^^^^^^^
  Routine containing the ARTn algorithm 

:ref:`f90_move_mode`
^^^^^^^^^^^^^^^^^^^^
Routine change the `disp_vec` gave by *artn()* to velocity/force array for FIRE algorithm

:ref:`f90_clean_artn`
^^^^^^^^^^^^^^^^^^^^^
Routine set all the flag and variable to be ready for a new research
