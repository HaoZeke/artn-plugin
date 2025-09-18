.. _tuto_initial_push:

****************
The initial push
****************


The exploration for a saddle point typically starts from a structure in the minimum, or very close to it.
The structure is deformed with an initial push, after which the ARTn algorithm starts.

There are multiple ways you can specify the initial push vector to pARTn.
In the most basic case, you can let the code generate it for you.

Push mode
=========

First choose the value for :doc:`../../params/push_mode` parameter, which controls the choice of atoms on which the push is generated, and then specify the IDs of atoms where the push shall be generated.

For example specify generation of a push vector on a list of atoms, specifically indices 12 and 17:

.. code-block:: fortran

   push_mode =  "list"
   push_ids  =  12, 17


Push direction: conical constraint
==================================

The direction of the initial push vector can be specified as a cone with a direction and angle, such that the generated vector is a random vector within the specified cone.

To specify the cone, use :doc:`../../params/push_add_const` parameter, where the first 3 values specify cone direction, and the 4th value the solid angle:

.. code-block:: fortran

   ! specify cone for the vector on atom index 12;
   ! with direction [ 1, -1, 0 ], and solid angle 25 degree:
   push_add_const(:, 12) = 1.0, -1.0, 0.0,  25.0

The same can be done for all atoms specified in ``push_ids``.
If the constraint is not specified for any atom, that atom will get a completely random vector.


Size of the push
================

The size is controlled by :doc:`../../params/push_step_size`, which specifies the 2-norm of the vector.


Number of initial pushes
========================

The ARTn algorithm involves the cmoputation of the lowest eigenvector of the Hessian matrix, with the Lanczos algorithm.
However, the information of the eigenvector is only used when the corresponding eigenvalue is negative, which happens once the system is outisde of the basin.
In addition, the computation of the eigenvector can be relatively costly.
For these reasons, the Lanczos procedure can be skipped in the first few ARTn steps, since it is quite certain that the value will be positive, since the system has probably not moved very far from the initial minimum.

The number of ARTn steps in which Lanczos is skipped, is controlled by the :doc:`../../params/ninit` parameter.
For example, if ``ninit = 3``, the first calculation of the eigenvector will only happen after 3 ARTn steps, where each step consists of a push and perpendicular relax.
