.. _py2d:

Python.2D.d
-----------

**description**

This script launches a pARTn calculation over a 2D analytical surface, and plots the full path.

It can be used to play around and explore the effect of different ARTn parameters on the exploration of the PES. The behaviour in output ``artn.out`` can be analysed in parallel to the visual representation of the path.

There are also some plotting options, such as drawing the normalized force vectors, or the ionflection regions.
Please see the file ``artn_2d.py``.

The 2D function is defined in the file ``my_function.py``; it can be thought of as a one-atom system confined to a 2D plane.

.. note::

    this is **not** a real physical system, the 2D picture is a big (over-)simplification. Therefore this should not be compared in any quantitative way to a system with N atoms (thus 3N dimensions).

Run as:

.. code-block:: bash

   ## get the dependencies (needed only once)
   python -m pip install -r requirements.txt

   ## run example
   python artn_2d.py

