.. _group_routine_artn:

ARTn: Files/Modules/Routines
============================

Plugin ARTn routines are encapsulated in Fortran modules and submodules.
Each module has its own file with the same name and are diveded in 3 main part as presented below.
A fourth part are related to the routines that can be called as explained in section :ref:`calling_order`.

Major part of routines are distributed in own individual files of the same name and encapsulated in submodule.
In the following section we describes how the module and routines are spread trough the source files. 
 

Header Module:
---------------

h_artn_precision.f90
^^^^^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_h_artn_precision`: 
  Define the real precision through the variable **dp**.

h_artn_units.f90
^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_h_artn_units`:
  It Contains the variable and routine relative the units of the engine.
  When a new engine interface is added, the keywords of the new engine has to be added in the routine *make_units()*
  Files associated:

  * convert_units.f90: Contains the routine to manage the units parameters :ref:`f90_convert_units`

h_artn_info.f90
^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_h_artn_info`:
  Information on plugin-ARTn version.   


DATA Module:
------------

d_artn_data.f90
^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_d_artn_data`:
  Contains the array related to the configuration.
  Assoicated files:

  * save_step_data.f90: Routine :ref:`f90_save_step_data`
  * set_data.f90: Routines :ref:`f90_set_data`
  * get_data.f90: Routines :ref:`f90_get_data`


d_artn_params.f90
^^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_d_artn_params`:
  Contains all the variable used in the ARTn algorithm
  Assocated files:

  * check_d_artn_params.f90:	Routines :ref:`f90_check_artn_params`
  * fill_param_step.f90:	Rountine :ref:`f90_fill_param_step`
  * set_param.f90:		Routines :ref:`f90_set_param`
  * get_param.f90:		Routines :ref:`f90_get_param`
  * dump_routines.f90:		Routines :ref:`f90_dump_routines`
  * set_runparam.f90:		Routines :ref:`f90_set_runparam`
  * get_runparam.f90:		Routines :ref:`f90_get_runparam`


d_datainfo.f90
^^^^^^^^^^^^^^
  Contains the module :ref:`f90_d_datainfo`
  Contains information about params and data (type, rank, size)




Routines Module:
----------------


m_artn_error.f90
^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_artn_error`:
  Contains routines to handle the error.


m_artn_tools.f90
^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_artn_tools`:
  Contains routines used to manipulate/compute quantities from configuration
  Assoicated files:

  * pbc.f90:	Routines :ref:`f90_pbc` and :ref:`f90_invmat3x3`
  * diag.d90:	Routine :ref:`f90_diag`
  * compute_delr.f90:	Routine :ref:`f90_compute_delr`
  * center.f90:		Routine :ref:`f90_center`  
  * string_tools.f90:	Routines :ref:`f90_string_tools`
  * make_filename.f90:	Routine :ref:`f90_make_filename`
  * sum_force.f90:	Routine :ref:`f90_sum_force`
  * split_field.f90     Routine :ref:`f90_split_field`
  * random.f90:		Routine :ref:`f90_random`
  * permute.f90:	Routine :ref:`f90_permute`
  


m_setup_artn.f90
^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_setup_artn`:
  Contains routines used at the first call to ARTn.
  Associated files:

  * start_guess.f90: Routines :ref:`f90_start_guess`
  * push_init.f90: Routine :ref:`f90_push_init`
  * clean_artn.f90: Routine :ref:`f90_clean_artn`


m_artn_option.f90
^^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_artn_option`:
  Contains routines related to optional behavior like loading the next minimum for the next research, the direction interpolation between the initial push and the eigenvector at the moment of passing the inflection point, etc...
  Associated files:

  * move_nextmin.f90: Routine :ref:`f90_move_nextmin`
  * smooth_interpol.f90: Routine :ref:`f90_smooth_interpol`
  * restart.f90: Routine :ref:`f90_restart`
  * nperp_limitation.f90: Routines :ref:`f90_nperp_limitation`
  * constrained_draw.f90: Routines :ref:`f90_constrained_draw`


m_artn_report.f90
^^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_artn_report`:
  Contains I/O routines, one part for the report output at different step of ARTn and other part to write/read the configuration on file.
  Associated files:

  * write_struct.f90: Routines :ref:`f90_write_struct`
  * write_report.f90: Routines :ref:`f90_write_report`


m_artn_fire.f90
^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_artn_fire`:
  Contains routines related to the Fire algorithm.



ARTn algorithm:
---------------

Two different ways to use plugin-ARTn: the first way is to hijack the fire algorithm of you engine and in this case it use the routines `artn()`, `move_mode()` and `clean_artn()`, 
and a second way is to given the E/F to `artn_step()` and return the next configuration. 


artn.f90
^^^^^^^^
  Contains the module :ref:`f90_m_artn`:
  Encapsulate the main routine ARTn algorithm (:ref:`f90_artn`) and other important routines.

  * block_pushinit.f90: Rotuine :ref:`f90_block_pushinit` 
  * block_perprelax.f90: Rotuine :ref:`f90_block_perprelax` 
  * block_pusheigen.f90: Rotuine :ref:`f90_block_pusheigen` 
  * block_pushover.f90: Rotuine :ref:`f90_block_pushover` 
  * block_finalize.f90: Rotuine :ref:`f90_block_finalize` 
  * check_force_convergence.f90: Rotuine :ref:`f90_check_force_convergence` 
  * push_over_procedure.f90: Rotuine :ref:`f90_push_over_procedure` 
  * block_finalize.f90: Rotuine :ref:`f90_block_finalize` 



move_mode.f90
^^^^^^^^^^^^^
  Contains the module :ref:`f90_m_move_mode`:
  Encapsulate the routine :ref:`f90_move_mode` that changes the `disp_vec` gave by *artn()* to velocity/force array for FIRE algorithm


artn_step.f90
^^^^^^^^^^^^^
  Contains the module `m_artn_step` where the routine :ref:`f90_artn_step` is. 
  Routine to perform single step of artn research



Interface Module:
-----------------


artn_api.f90
^^^^^^^^^^^^
  Contains the module :ref:`f90_artn_api`:
  Contains routines to create/destroy artn instance, set/get parameters from this instance and launch artn algorithm routines


artn_c_wrappers.f90
^^^^^^^^^^^^^^^^^^^
  Contains the module :ref:`f90_artn_c_wrappers`:
  Contains all the C-wrappers to artn routines.








