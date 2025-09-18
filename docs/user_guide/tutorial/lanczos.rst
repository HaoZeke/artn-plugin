.. _tuto_lanczos:

****************************************
Obtaining the eigenvalue and eigenvector
****************************************

The Lanczos algorithm is used to compute the lowest eigenvalue of the Hessian matrix, and its corresponding eigenvector.
Lanczos algorithm iteratively converges to some approximation of the lowest eigenvalue.


Number of iterations
====================

The most fundamental way to control the Lanczos algorithm is through the maximal number of iteration steps, :doc:`../../params/lanczos_max_size`.
If the Lanczos block reaches this number of steps, it will exit with whatever eigenvalue/vector is currently computed.


The minimal number of iteration steps can also be specified, :doc:`../../params/lanczos_min_size`.


Eigenvalue convergence
======================

The desired convergence criterion of the eigenvalue can be specified through :doc:`../../params/lanczos_eval_conv_thr`.


Changing the push vector
========================

Once a negative eigenvalue has been computed, ARTn switches the pushing vector from the initial push, to the current eigenvector.
This change can sometimes be abrupt (non-smooth), which can cause the system to perp-relax back into the basin, and lose the eigenvector.

In order to mitigate this, :doc:`../../params/nsmooth` parameter can be used, which specifies a number of steps in which the pushing vector will be linearly interpolated from the initial push to the eigenvector.


Limiting the eigenpush step size
================================

When the pushing vector is an eigenvector, the step size is inversely related to the eigenvalue (curvature) at the current point.
In regions of small negative curvature, this can lead to large step sizes. Thus the step size is limited by :doc:`../../params/eigen_step_size`.


Losing the eigenvalue (convex regions of the PES)
=================================================

For a number of reasons, the negative eigenvalue computed by ARTn can become positive.
This is not desired, and is referred to as "losing" the eigenvalue, and the region where it happens is referred to as "convex region".

A mitigation implemented in pARTn is to force the system to cross the convex region, by a mixing the initial push vector with some random component, and using it as a temporary push vector, until a negative eigenvalue is found.

The maximal number of convex regions the system is allowed to cross (or number of times an eigenvalue can be lost), is specified by :doc:`../../params/nnewchance` parameter.

More information about this scenario in the article [1]_.

.. [1] https://doi.org/10.1063/5.0210097


Initial Lanczos vector
======================

By default, each time ARTn enters a Lanczos block, it will initialize the first Lanczos vector with the eigenvector obtained as result of the previous Lanczos block.
The reason for this is that the eigenvectors typically do not change considerably during the ascent toward the saddle.
Such "reuse" of previous eigenvectors can considerably lower the number of needed iterations to calculate the eigenvector.

This behaviour can be changed by:

.. code-block:: fortran

   lanczos_always_random = .true.

which will always initialize the first Lanczos vector to a random vector.


Computing the curvature at minima
=================================

If you wish to compute the lowest eigenvalue in the found minima, in order to check if they really are minima of the PES, you can specify :doc:`../../params/lanczos_at_min`.
