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
