.. _artn_input_params:

List of ARTn input parameters
=============================

The ARTn parameters are given in the file `artn.in`. That file is formatted as FORTRAN NAMELIST, called `ARTN_PARAMETERS` as for example:

.. code-block:: bash

   &ARTN_PARAMETERS
                ... specify parameters ...
   /


All parameters available in pARTn are listed below, grouped by the part of ARTn algorithm they affect.

.. toctree::
   :maxdepth: 1
   :caption: I/O control

   ../params/verbose
   ../params/engine_units
   ../params/struc_format_out
   ../params/delr_thr

.. toctree::
   :maxdepth: 1
   :caption: Exploration Option

   ../params/lrestart
   ../params/lpush_final
   ../params/lmove_nextmin
   ../params/zseed
   ../params/etot_diff_limit


.. toctree::
   :maxdepth: 1
   :caption: Control initial push

   ../params/push_mode
   ../params/push_guess
   ../params/push_ids
   ../params/push_add_const
   ../params/push_dist_thr
   ../params/push_step_size
   ../params/push_step_size_per_atom
   ../params/ninit


.. toctree::
   :maxdepth: 1
   :caption: Control the Lanczos algorithm

   ../params/lanczos_max_size
   ../params/lanczos_min_size
   ../params/lanczos_disp
   ../params/lanczos_eval_conv_thr
   ../params/lanczos_at_min


.. toctree::
   :maxdepth: 1
   :caption: Control the eigenvector push

   ../params/eigval_thr
   ../params/eigen_step_size
   ../params/nsmooth
   ../params/neigen
   ../params/alpha_mix_cr
   ../params/nnewchance
   ../params/eigenvec_mode
   ../params/eigenvec_guess


.. toctree::
   :maxdepth: 1
   :caption: Control the perpendicular relaxation

   ../params/nperp
   ../params/nperp_limitation


.. toctree::
   :maxdepth: 1
   :caption: Control convergence

   ../params/forc_thr
   ../params/converge_property
   ../params/nevalf_max.rst




