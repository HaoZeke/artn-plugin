.. _setextract_interf:

###########################################################
The generic ``artn_set`` and ``artn_extract`` functionality
###########################################################


The **generic** ``artn_set`` **routine** is a wrapper to the ``set_param`` routine.

The **generic** ``artn_extract`` **routine** is a wrapper to ``get_data`` routine.


These generic functions perform checking of type, size, and rank of the passed data, and will return sensible errors when wrong data is passed.

.. note::

   The usage differs slightly between Fortran and python.


For concrete examples on how to use this functionality, see the ``examples/COUPLE`` directory.


Function ``artn_set``
=====================

This function sets variables in the ``param`` group only, they are located in ``artn_params.f90`` and represent the input parameters of the ARTn exploration.

.. note::
   Where applicable, the data should be in units specified by ``engine_units`` variable.
   If the ``engine_units`` are not specified, ``artn_set`` will return an error.

The fortran interface is:

.. doxygengroup:: group_artn_set
   :project: plugin-ARTn

The python interface is:

.. autoclass:: pypARTn.artn
   :members: set, set_param

The list of names of variables which can be used with the *artn_set* can be printed to screen using the ``list_set`` function:

   >>> import pypARTn
   >>> a = pypARTn.artn( engine="other" )
   >>> a.list_set()
    List of variables which can be set into the module artn_params:
     name                   :       type   rank   size
   ================================================================================
     alpha_mix_cr           :       real      0   0
     converge_property      :     string      0   any
     current_step_size      :       real      0   0
     delr_thr               :       real      0   0
     eigenfname             :     string      0   .le. 255
     eigen_step_size        :       real      0   0
     eigenvec_guess         :     string      0   .le. 255
     eigenvec               :       real      2   fortran (3,natoms); python [natoms,3]
     eigval_thr             :       real      0   0
     engine_units           :     string      0   .le. 256
     etot_diff_limit        :       real      0   0
     filout                 :     string      0   .le. 255
     filin                  :     string      0   .le. 255
     forc_thr               :       real      0   0
     initpfname             :     string      0   .le. 255
     lanczos_always_random  :    logical      0   0
     lanczos_at_min         :    logical      0   0
     lanczos_disp           :       real      0   0
     lanczos_eval_conv_thr  :       real      0   0
     lanczos_max_size       :    integer      0   0
     lanczos_min_size       :    integer      0   0
     lmove_nextmin          :    logical      0   0
     lnperp_limitation      :    logical      0   0
     lpush_final            :    logical      0   0
     lrelax                 :    logical      0   0
     lrestart               :    logical      0   0
     nevalf_max             :    integer      0   0
     neigen                 :    integer      0   0
     ninit                  :    integer      0   0
     nnewchance             :    integer      0   0
     nperp                  :    integer      0   0
     nperp_limitation       :    integer      1   any
     nrelax_print           :    integer      0   0
     nsmooth                :    integer      0   0
     push_add_const         :       real      2   fortran (4,natoms); python [natoms,4]
     push_dist_thr          :       real      0   0
     push_guess             :     string      0   .le. 255
     push_ids               :    integer      1   .le. natoms
     push                   :       real      2   fortran (3,natoms); python [natoms,3]
     push_mode              :     string      0   .le. 5
     push_over              :       real      0   0
     push_step_size         :       real      0   0
     push_step_size_per_atom:       real      0   0
     prefix_sad             :     string      0   .le. 255
     prefix_min             :     string      0   .le. 255
     restart_freq           :    integer      0   0
     restartfname           :     string      0   .le. 255
     struc_format_out       :     string      0   .le. 10
     verbose                :    integer      0   0
     zseed                  :    integer      0   0



Function ``artn_extract``
=========================

This functions extracts variables from the ``data`` group, they are located in ``m_artn_data.f90`` and represent the results of an ARTn exploration.

.. note::
   Where applicable, the extracted data is in units specified by ``engine_units``.

The fortran interface is:

.. doxygengroup:: group_artn_extract
   :project: plugin-ARTn

The python interface is:

.. autoclass:: pypARTn.artn
   :members: extract, get_data

The list of names of variables which can be used with the *artn_extract* can be printed to screen using the ``list_extract`` function:

.. code-block:: python

   >>> import pypARTn
   >>> a = pypARTn.artn( engine="other" )
   >>> a.list_extract()
   List of variables which can be extracted from m_artn_data:
   ================================================================================
     name              :       type   rank   size
   ================================================================================
     Information about the current run:
     has_error         :    logical      0   0
     nevalf            :    integer      0   0
   
     Initial structure:
     natoms            :    integer      0   0
     lat               :       real      2   (3,3)
     etot_init         :       real      0   0
     typ_init          :    integer      1   natoms
     tau_init          :       real      2   fortran (3,natoms); python [natoms,3]
     push_init         :       real      2   fortran (3,natoms); python [natoms,3]
   
     Saddle structure:
     has_sad           :    logical      0   0
     etot_sad          :       real      0   0
     delr_sad          :       real      0   0
     eigval_sad        :       real      0   0
     typ_sad           :    integer      1   natoms
     tau_sad           :       real      2   fortran (3,natoms); python [natoms,3]
     eigen_sad         :       real      2   fortran (3,natoms); python [natoms,3]
     nevalf_sad        :    integer      0   0
   
     Minimum1 structure:
     has_min1          :    logical      0   0
     etot_min1         :       real      0   0
     delr_min1         :       real      0   0
     eigval_min1       :       real      0   0
     typ_min1          :    integer      1   natoms
     tau_min1          :       real      2   fortran (3,natoms); python [natoms,3]
     eigen_min1        :       real      2   fortran (3,natoms); python [natoms,3]
     nevalf_min1       :    integer      0   0
   
     Minimum2 structure:
     has_min2          :    logical      0   0
     etot_min2         :       real      0   0
     delr_min2         :       real      0   0
     eigval_min2       :       real      0   0
     typ_min2          :    integer      1   natoms
     tau_min2          :       real      2   fortran (3,natoms); python [natoms,3]
     eigen_min2        :       real      2   fortran (3,natoms); python [natoms,3]
     nevalf_min2       :    integer      0   0
   
     Current step:
     etot_step         :       real      0   0
     delr_step         :       real      0   0
     eigval_step       :       real      0   0
     typ_step          :    integer      1   natoms
     tau_step          :       real      2   fortran (3,natoms); python [natoms,3]
     force_step        :       real      2   fortran (3,natoms); python [natoms,3]
     eigen_step        :       real      2   fortran (3,natoms); python [natoms,3]
   


Interacting with other variables
================================

In order to interact with other variables, you first need to know in which group the variable is located.
The variables of pARTn are split into three "groups":

 - ``param``     : all input variables accessible to the user through the input file;
 - ``data``      : all output data that is generated by ARTn;
 - ``runparam``  : the internal flags and counters, used to control the main steps of ARTn.

For more details on these groups, see :doc:`../group/variable_groups`.

Once the group is identified, the interaction between a caller and pARTn can be done with the ``set_*`` and ``get_*`` functions.
The ``*`` symbol here refers to one of the three groups mentioned above (``param``, ``data``, or ``runparam``).
For example, to communicate a variable from the ``param`` group from the caller to pARTn, one should use the ``set_param`` function; while to obtain a variable from the ``data`` group after the ARTn run, one should use the ``get_data`` function.

The details on the lower-level ``set_*`` and ``get_*`` routines are available :ref:`here <setget_detail>`.

.. warning::

    The functions ``set_*`` and ``get_*`` provide no checking of the type, size, or rank of the data that is being passed, which might cause crashes/strange errors when wrong data is passed.


