.. _examples:

########
Examples
########
List of official examples of the ARTn-plugin (pARTn) interfaced with Quantum ESPRESSO, Siesta, VASP and LAMMPS

Python
======

**COUPLE/py_metropolis**
    Python script implimentation of a loop of ARTn research associated to LAMMPS.
    A Metropolis algorithm is applied to the barrier of actual event, if found by ARTn, to decide to start the next research from the new minimum or restart from the actual one.



Quantum ESPRESSO
================
All QE examples use the option ``push_mode = 'list'`` and specify the indices of the atoms that are moved with the initial push with the ``push_ids`` option. The initial push direction is further specified with the ``push_add_const`` option.

**QE.Al-vacancy.d**
  Diffusion of vacancy in aluminum crystal of 31 atoms. The inital push of ARTn moves a single atom. The direction of the push is specified as a random vector in the cone of 45 degrees with axis (1.0, 0.0, 1.0).

.. toctree::
   :maxdepth: 1

   details <examples/QE.Al-vacancy.rst> 

**QE.Alad.Al100.d**
  Diffusion of an aluminum adatom on the hollow site of the aluminum (100) surface (the system consists of 151 atoms). Two searches are used, the first one corresponds to the exchange mechanism, and the second to the hopping mechanism. 

.. toctree::
   :maxdepth: 1

   details <examples/QE.Alad.Al100.rst> 


**QE.ClCH3+Cl.d**
  Identification of a saddle point for the molecular reaction of CH\ :sub:`3`\Cl with a chloride ion, forming CH\ :sub:`3`\Cl and releasing the previously bound chloro group as a chloride ion. The initial push moves three atoms, specifically Cl, C and Cl in a specified direction along the z-axis.

.. toctree::
   :maxdepth: 1

   details <examples/QE.ClCH3Cl.rst> 


**QE.graphene.d**
  Diffusion of a vacancy in a graphene sheet of 11 atoms. The initial displacement is generated on a C atom along the y-direction.

.. toctree::
   :maxdepth: 1

   details <examples/QE.graphene.rst> 


**QE.Li-migration.d**
  Diffusion of an intercalated lithium atom in graphite (the system consists of 25 atoms) from one site to the other over the C-C bond. The initial displacement is generated on the Li atom along the x-direction.

.. toctree::
   :maxdepth: 1

   details <examples/QE.Li-migration.rst> 


**QE.NH3.d**
  Inversion of ammonia molecule (NH\ :sub:`3`\) in a box. The initial push of ARTn moves one atom, specifically the nitrogen atom, along the z-axis.

.. toctree::
   :maxdepth: 1

   details <examples/QE.NH3.rst> 


**QE.Si-vac.d**
  Diffusion of a vacancy in a silicon crystal of 63 atoms. The initial push of ARTn moves one atom in the vicinity of the vacancy towards it.

.. toctree::
   :maxdepth: 1

   details <examples/QE.Si-vac.rst> 


  
 
Siesta
======

**Siesta.Si-vac.d**
  Silicon diamond with vacancy


VASP
====

**VASP.Al-vac.d**
  Aluminum criystal with vacancy



LAMMPS
======

All LAMMPS examples use the plugin class of lammps to link pARTn library following the specific installation [LINK].
If you use the old style pARTn library installation [LINK] you can use the same lammps.in removing the ``plugin load`` and ``plugin list`` command in the script.

**LAMMPS.a-Si.d**
    Amorphous Silicon box of 1000 atoms using Sterlinger-Weber interatomic potential.
    The initial push of ARTn move all the atom in random direction ``push_mode = 'all'``.

**LAMMSP.Al-vac-EAM.d**
    Diffusion of Vacancy in aluminum crystal of 255 atoms using EAM interatomic potential.
    One atom around the vacancy is pushed in constrained direction using the option ``add_const``. 

**LAMMPS.LJ.SaddleRefine.d**
    Refine saddle point from 200 configurations of 38-atoms cluster describes by Lennard-Jones Potential.
    Artn start directly by compute the minimum hessian eigenvalues to push in the saddle point direct.
    There is two lammps input script:
    - lammps-1.in: for one saddle point refinement
    - lammps.in: making a loop in lammps script to be able to refine the 200 configuration in the folder coords-lmp/
 
**LAMMPS.Oxydation.ReaxFF.d**
    Silicon oxydation in 1200 atoms box using ReaxFF interatomic potential.
    The initial push happen on two atoms with constrained direction using the option ``add_const``.

**LAMMPS.Pt111.d**
    Platinum eptamer on platinum (111) surface for a box of 343 atoms using ``morse/smooth/linear`` pair style potential in LAMMPS.
    This example use an external initial push give in ``ini_push.xyz`` file and using the option ``push_mode = 'file'`` and ``push_guess = 'ini_push.xyz'``.

**LAMMPS.Si-vac.d**
    Silicon vacancy in crystal diamond of 511 atoms using the Sterlinger-Weber interatomic potential.
    The initial push of ARTn move all the atom in random direction ``push_mode = 'all'``. 

**LAMMPS.Si-vac.local.d**
    Silicon vacancy in crystal diamond of 7999 atoms using the Sterlinger-Weber interatomic potential.
    One atom around the vacancy is pushed in constrained direction using the option ``add_const``.



