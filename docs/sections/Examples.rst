.. _examples:

########
Examples
########

List of official examples of the ARTn-plugin (pARTn) interfaced with Quantum ESPRESSO and LAMMPS

**TODO**: Fill the description for each examples

Quantum ESPRESSO
================

**Al-vacancy.QE.d**
  Aluminum vacancy

**Alad.Al100.QE.d**
  Aluminum adatom on Aluminum (111) surface

**ClCH3+Cl.QE.d**
  Molecule blabla

**graphene.QE.d**
  Graphene blabla

**Li-migration.QE.d**
  Li atom migration in ...

**NH3.QE.d**
  :math:`NH_3` doing something

**Si-vac.QE.d**
  Vacancy in silicon crystal



LAMMPS
======

All LAMMPS examples use the plugin class of lammps to link pARTn library following the specific installation [LINK].
If you use the old style pARTn library installation [LINK] you can use the same lammps.in removing the ``plugin load`` and ``plugin list`` command in the script.

**a-Si.LAMMPS.d**
    Amorphous Silicon box of 1000 atoms using Sterlinger-Weber interatomic potential.
    The initial push of ARTn move all the atom in random direction ``push_mode = 'all'``.

**Al-vac-EAM.LAMMPS.d**
    Diffusion of Vacancy in aluminum crystal of 255 atoms using EAM interatomic potential.
    One atom around the vacancy is pushed in constrained direction using the option ``add_const``. 

**LJ.SaddleRefine.LAMMPS.d**
    Refine saddle point from 200 configurations of 38-atoms cluster describes by Lennard-Jones Potential.
    Artn start directly by compute the minimum hessian eigenvalues to push in the saddle point direct.
    There is two lammps input script:
    - lammps-1.in: for one saddle point refinement
    - lammps.in: making a loop in lammps script to be able to refine the 200 configuration in the folder coords-lmp/
 
**Oxydation.ReaxFF.LAMMPS.d**
    Silicon oxydation in 1200 atoms box using ReaxFF interatomic potential.
    The initial push happen on two atoms with constrained direction using the option ``add_const``.

**Pt111.LAMMPS.d**
    Platinum eptamer on platinum (111) surface for a box of 343 atoms using ``morse/smooth/linear`` pair style potential in LAMMPS.
    This example use an external initial push give in ``ini_push.xyz`` file and using the option ``push_mode = 'file'`` and ``push_guess = 'ini_push.xyz'``.

**Si-vac.LAMMPS.d**
    Silicon vacancy in crystal diamond of 511 atoms using the Sterlinger-Weber interatomic potential.
    The initial push of ARTn move all the atom in random direction ``push_mode = 'all'``. 

**Si-vac.local.LAMMPS.d**
    Silicon vacancy in crystal diamond of 7999 atoms using the Sterlinger-Weber interatomic potential.
    One atom around the vacancy is pushed in constrained direction using the option ``add_const``.

