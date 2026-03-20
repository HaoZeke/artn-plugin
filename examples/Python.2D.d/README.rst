Python.2D.d
-----------

**description**

This script launches a pARTn calculation over a 2D analytical surface, and plots the full path.

It can be used to play around and explore the effect of different ARTn parameters on the exploration of the PES, and finding the saddle point.

There are also some plotting options, such as drawing the normalized force vectors, or the ionflection regions.
Please see the file ``artn_2d.py``.

NOTE: this is **not** a real physical system, the 2D picture is a great (over-)simplification. Therefore this should not be compared in any way to any system with N atoms (thus 3N dimensions).

The 2D function is defined in the file ``my_function.py``.

Run as:

.. code-block:: bash

   python artn_2d.py

