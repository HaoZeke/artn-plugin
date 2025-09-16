.. _perp_relax:

****************************
The perpendicular relaxation
****************************

After the push, ARTn algorithm performs a perpendicular relaxation.
That is, a relaxation constrained to the direction perpendicular to the push.

The perpendicular relaxation is often abbreviated as "perp relax", or just "perp".


The number of perp relax steps
==============================

Depending on the current position on the PES, the goal of perp relax differs:

 1) in the initial basin, the goal of perp relax is to avoid atomic collisions which can happen due to a randomized push vector;
 2) near a saddle point, the goal is to minimize the force, and converge the system to the saddle.

We can see that in case 1), the goal can be achieved with only a few steps of perp relax, but in case 2) we might need more steps.

This is regulated with :doc:`../../params/nperp_limitation`, which is an array of integer values.
For example, the specification:

.. code-block:: fortran

   nperp_limitation = 4, 8, 12, 12, 12, 18

means that within the basin, the number of perp relax steps will be 4 (the first integer).
Once the system reaches a negative eigenvalue, the number of perp relax steps will be progressively increased from 4 to 18.
Specifically, the number of perp relax steps will first increase to 8, then it will be held at 12 for 3 steps, and finally increased to 18.
If the saddle is still not reached, the number will be kept at 18.

It is also possible to specify the last value as -1:

.. code-block:: fortran

   nperp_limitation = 4, 8, 12, 12, 18, -1

which signifies that the number of perp relax steps is unlimited.
That means perp relax will continue until some :ref:`stop_perp_relax` is met.


FIRE parameters
===============

The perp relax is mainly controlled by the FIRE parameters, such as the timestep, alpha, and inc/dec factors.
The modification of these parameters depends upon your E/F engine, and the mode of execution.
See also: :ref:`final_relax`.


.. _stop_perp_relax:
Stopping criteria
=================

While the system is within the starting basin, the only criterion to stop the perp relax is:

 - number of perp relax steps has reached the limit according to current value of ``nperp_limitation``;

When outside of the basin, any of the following criteria will stop the perp relax block:

 - system has converged to saddle point;
 - number of perp relax steps has reached the limit according to current value of ``nperp_limitation``;
 - parallel component of the force is larger in magnitude than the perpendicular component;
 - perpendicluar component of the force is aligned in the direction such that relaxation along it, would bring the system back toward the initial minimum;

