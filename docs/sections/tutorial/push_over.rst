.. _tuto_push_over:

***************************************
Finding adjacent minima from the saddle
***************************************

Once a saddle is reached, the calculation can either be stopped, or continued to compute the adjacent minima.
This is controlled by :doc:`../../params/lpush_final` flag.

In case the final push is performed, the algorithm will push the saddle structure once in the direction of the eigenvector, and then let it relax.
When the first minimum is found, the structure will be brought back to the saddle, and pushed in the opposite direction of the eigenvector, and let to relax.


Size of the final push
======================

The size of final push-over step is controlled by :doc:`../../params/push_over`.


Relaxation to minima
====================

The minimzation from saddle is controlled by the FIRE parameters such as timestep, alpha, inc/dec factors, etc.
The modifications of these parameters depends on your E/F engine, and the mode of using pARTn.


.. tab-set::

   .. tab-item:: QE

      The FIRE parameters can be modified from the QE input, in the IONS card: https://www.quantum-espresso.org/Doc/INPUT_PW.html#idm1103

   .. tab-item:: LAMMPS

      The FIRE parameters can be modified using the ``min_modify`` command, see: https://docs.lammps.org/min_modify.html


   .. tab-item:: Siesta

      The Siesta interface uses ``artn_step()`` functionality, thus the internal FIRE is used.
      Its parameters can be modified by adding a namelist ``&fire_params /`` into ``artn.in``, unless a different ``infile`` was specified.


   .. tab-item:: VASP

      The VASP interface uses ``artn_step()`` functionality, thus the internal FIRE is used.
      Its parameters can be modified by adding a namelist ``&fire_params /`` into ``artn.in``, unless a different ``infile`` was specified.
