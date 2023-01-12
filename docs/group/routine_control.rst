.. _group_routine_control:

Routine Control
===============

.. #doxygengroup:: Control
   :project: plugin-ARTn

- :ref:`f90_nextmin`: Option can be use with ``lmove_nextmin = .true.``
..  Once a saddle point is reached, the default ARTn behaviour also involves the final push and relaxation to the two adjacent minima. 
  This is controlled by the logical flag lpush_final, which when set to `.false.`, will signal ARTn to stop once a saddle point has been found, and reset the atomic positions to the initial configuration. 
  On the other hand, if `lpush_final = .true.`, the algorithm will use the eigenvector obtained at saddle to push the configuration to the +/- directions, and then allowed to relax. 
  The size of this final push is regulated through push_over parameter.
  Once the two minima are obtained, it is possible to set the atomic positions to the adjacent local minimum, which is
  achieved by setting the flag `lmove_nextmin=.true.`. 
  As such the subsequent ARTn exploration starts from the new minimum configuration, otherwise the atomic positions are reset to the initial configuration.

- :ref:`f90_push_init`: Custom the initial push in basin

- :ref:`f90_read_guess`: Allow to read the initial push and/or the initial eigenvector through a file 

- :ref:`f90_smooth_interpol`: Custom the transition betwen the initial push and the eigenvector direction by an interpolation between them



