#############################
E/F engine inputs
#############################


For a proper execution of pARTn, there are some restrictions on the variables specified in the input files of E/F engines.



Quantum ESPRESSO
================

For a proper execution of pARTn within QE, three variables must always be specified in the QE input file, namely:

 - in the ``CONTROL`` namelist, the calculation type must be specified as ``calculation = "relax"``,
 - in the ``SYSTEM`` namelist, the use of symmetries disabled ``nosym = .true.``,
 - in the ``IONS`` namelist, the dynamics must be specified as ``ion_dynamics="fire"``.

*minimal example of QE input file:*

.. code-block:: bash

  &CONTROL
    calculation = 'relax' 
  /
  &SYSTEM
    nosym = .true. 
  /
  &IONS
    ion_dynamics = 'fire' 
  /

Running the calculation
-----------------------

QE calculation with pARTn must be launched with the flag ``-partn``, as follows:

.. code-block:: bash

   QE/bin/pw.x -partn -inp input_pw


Related pages:
--------------

| The full list of `QE input parameters <https://www.quantum-espresso.org/Doc/INPUT_PW.html>`_
| :doc:`install_QE`





LAMMPS
======


In the LAMMPS input script, the pARTn library passes through the ``class plugin``.
The ``fix artn`` can be used only after loading the dynamic library ``libartn.so``, as for example:

.. code-block:: bash

   plugin load /path/to/pARTn/libartn.so
   fix fix_ID all artn
   min_style fire 
   minimize etol ftol maxiter maxeval

The ``fix artn`` must also be associated with the algorithm FIRE that is defined by the ``min_style`` command.

NOTE: The function ``delete_atoms`` of LAMMPS should be used with the keyword ``compress yes``.

To be able to use the ``Fix/ARTn`` the plugin ARTn has to be loaded with ``plugin load`` command.
Then you can activate the ``Fix/ARTn`` like all other fix commands in lammps:
.. code-block:: bash

   fix ID group-ID style args value

with ``style = artn``.
For the moment we only test ``group-ID = all``.
It is possible to customize the FIRE parameters you want to use with the fix ARTn. For each parameter you give the ``args`` followed by the ``value``. The ``args`` can be:

-  ``alpha``
-  ``alphashrink``
-  ``dtshrink``
-  ``dmax``
-  ``tmax``
-  ``tmin`` 



*minimal example of LAMMPS input file:*

.. code-block:: bash
   plugin load /path/to/artn-plugin/libartn.so
   fix ID all artn dmax value
   min_style fire 
   minimize etol ftol maxiter maxeval


Running the calculation
-----------------------

LAMMPS calculation is run the same way as any other LAMMPS calculation.


Related pages:
--------------


| The full list of `LAMMPS input commands <https://docs.lammps.org/Commands.html>`_
| :doc:`install_LAMMPS`
