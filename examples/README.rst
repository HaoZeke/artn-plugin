.. _examples:

########
Examples
########

List of official examples of the ARTn-plugin (pARTn) interfaced with Quantum ESPRESSO, Siesta, VASP and LAMMPS

**TODO**: Fill the description for each examples


Python
======

**COUPLE/py_metropolis**
    Python script implimentation of a loop of ARTn research associated to LAMMPS.
    A Metropolis algorithm is applied to the barrier of actual event, if found by ARTn, to decide to start the next research from the new minimum or restart from the actual one.



Quantum ESPRESSO
================

**QE.Al-vacancy.d**
  Aluminum vacancy

**QE.Alad.Al100.d**
  Aluminum adatom on Aluminum (111) surface

**QE.ClCH3+Cl.d**
  Molecule blabla

**QE.graphene.d**
  Graphene blabla

**QE.Li-migration.d**
  Li atom migration in ...

**QE.NH3.d**
  :math:`NH_3` doing something

**QE.Si-vac.d**
  Vacancy in silicon crystal


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



