Description
===========

``test.py``
-----------

Launch lammps through python, load pARTn as plugin through lammps command.
Test setting and extracting values from artn.


``artn_step.py``
----------------

This example shows how to call the ``artn.next_displ()`` function, to obtain the next
displacement vector from ARTn algorithm.
The idea is to use any external E/F engine, which is not supported by proper p-ARTn interface,
and use the ``artn.next_displ`` function to perform ARTn.

The way to perform ARTn algorithm is then to set a loop of steps, in each step compute energy and force
with a guven E/F engine, then call ``artn.next_displ()`` to obtain a displacement, and update
the atomic positions with it. Once ARTn algorithm converges, the ``lconv`` flag is set to True.

The ARTn data needs to be cleaned after the exploration (``artn.clean()``), before starting a new one.

For the purpose of this example, the external E/F engine is lammps.

