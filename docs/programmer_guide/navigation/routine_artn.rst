.. _group_routine_artn:

Routine ARTn
============

Plugin ARTn is organizaed in sections by task.
All the subroutine/function are encapsulated in module presented here by task.
 
.. #doxygengroup:: ARTn
   :project: plugin-ARTn


Header Module:
---------------

:ref:`f90_h_artn_precision`
^^^^^^^^^^^^^^^^^^^^^^^^^
  Define the real precision.

:ref:`f90_h_artn_units`
^^^^^^^^^^^^^^^^^^^^^
  Contains the variable and routine relative the units of the engine.
  When a new engine interface is added, the keywords of the new engine has to be added in the routine *make_units()*

:ref:`f90_h_artn_info`
^^^^^^^^^^^^^^^^^^^^^^
  Information on plugin-ARTn version.   


DATA Module:
------------

:ref:`f90_d_artn_data`
^^^^^^^^^^^^^^^^^^^^^^
  Contains the array related to the configuration.

:ref:`f90_d_artn_params`
^^^^^^^^^^^^^^^^^^^^^^^^
  Contains all the variable used in the ARTn algorithm

:ref:`f90_d_datainfo`
^^^^^^^^^^^^^^^^^^^^^
  Contains information about params and data (type, rank, size)


Routines Module:
----------------

:ref:`f90_m_artn_error`
^^^^^^^^^^^^^^^^^^^^^^^
  Contains routines to handle the error.

:ref:`f90_m_artn_tools`
^^^^^^^^^^^^^^^^^^^^^^^
  Contains routines used to manipulate/compute quantities from configuration

:ref:`f90_m_setup_artn`
^^^^^^^^^^^^^^^^^^^^^^^
  Contains routines used at the first call to ARTn.
  
:ref:`f90_m_artn_option`
^^^^^^^^^^^^^^^^^^^^^^^^
  Contains routines related to optional behavior like loading the next minimum for the next research, the direction interpolation between the initial push and the eigenvector at the moment of passing the inflection point, etc...

:ref:`f90_m_artn_report`
^^^^^^^^^^^^^^^^^^^^^^^^
  Contains I/O routines, one part for the report output at different step of ARTn and other part to write/read the configuration on file.

:ref:`f90_m_artn_fire`
^^^^^^^^^^^^^^^^^^^^^^
  Contains routines related to the Fire algorithm.


ARTn algorithm:
---------------

Two different ways to use plugin-ARTn: the first way is to hijack the fire algorithm of you engine and in this case it use the routines `artn()`, `move_mode()` and `clean_artn()`, 
and a second way is to given the E/F to `artn_step()` and return the next configuration. 

:ref:`f90_artn`
^^^^^^^^^^^^^^^
  Routine containing the ARTn algorithm 

:ref:`f90_move_mode`
^^^^^^^^^^^^^^^^^^^^
  Routine change the `disp_vec` gave by *artn()* to velocity/force array for FIRE algorithm

:ref:`f90_clean_artn`
^^^^^^^^^^^^^^^^^^^^^
  Routine set all the flag and variable to be ready for a new research

:ref:`f90_artn_step`
^^^^^^^^^^^^^^^^^^^^
  Routine to perform single step of artn research


Interface Module:
-----------------

:ref:`f90_artn_api`
^^^^^^^^^^^^^^^^^^^
  Contains routines to create/destroy artn instance, set/get parameters from this instance and launch artn algorithm routines

:ref:`f90_artn_c_wrappers`
^^^^^^^^^^^^^^^^^^^^^^^^^^
  Contains all the C-wrappers to artn routines.








