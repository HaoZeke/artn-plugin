OptBench Saddle search
======================

This example is a python script which runs the "saddle search" benchmark test from OptBench: `LINK`_.

.. _LINK: https://optbench.org/saddle-search.html

To launch the example you need to compile your LAMMPS for python (see `here`_ how to do that), and properly set the python module ``pypARTn``.

.. _here: https://docs.lammps.org/Python_install.html


Launch as:

.. code-block:: bash

   python3 -i launch_script.py



If you have compiled lammps with OpenMP support, you might want to specify that first:

.. code-block:: bash

   export OMP_NUM_THREADS=N
   python3 -i launch_script.py
