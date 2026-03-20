.. _examples:

########
Examples
########
List of official examples of the ARTn-plugin (pARTn) interfaced with Quantum ESPRESSO, Siesta, VASP and LAMMPS. The list is divided into sections for usage with specific E/F engines, where the basic examples for all engines are either the diffusion of an Al vacancy in bulk aluminum, or Si vacancy in bulk silicon. The final section is devoted to the usage of ``pARTn`` library within ``python`` workflows.  
  

Quantum ESPRESSO
================
All QE examples use the option ``push_mode = 'list'`` and specify the indices of the atoms that are moved with the initial push with the ``push_ids`` option. The initial push direction is further specified with the ``push_add_const`` option.

**QE.Al-vacancy.d**
  Diffusion of vacancy in aluminum crystal of 31 atoms. The inital push of ARTn moves a single atom. The direction of the push is specified as a random vector in the cone of 45 degrees with axis (1.0, 0.0, 1.0).

.. toctree::
   :maxdepth: 1

   Al-vacancy details <examples/QE.Al-vacancy.rst> 

**QE.Alad.Al100.d**
  Diffusion of an aluminum adatom on the hollow site of the aluminum (100) surface (the system consists of 151 atoms). Two searches are used, the first one corresponds to the exchange mechanism, and the second to the hopping mechanism. 

.. toctree::
   :maxdepth: 1

   Alad.Al100 details <examples/QE.Alad.Al100.rst> 


**QE.ClCH3+Cl.d**
  Identification of a saddle point for the molecular reaction of CH\ :sub:`3`\Cl with a chloride ion, forming CH\ :sub:`3`\Cl and releasing the previously bound chloro group as a chloride ion. The initial push moves three atoms, specifically Cl, C and Cl in a specified direction along the z-axis.

.. toctree::
   :maxdepth: 1

   ClCH3+Cl details <examples/QE.ClCH3Cl.rst> 


**QE.graphene.d**
  Diffusion of a vacancy in a graphene sheet of 11 atoms. The initial displacement is generated on a C atom along the y-direction.

.. toctree::
   :maxdepth: 1

   graphene details <examples/QE.graphene.rst> 


**QE.Li-migration.d**
  Diffusion of an intercalated lithium atom in graphite (the system consists of 25 atoms) from one site to the other over the C-C bond. The initial displacement is generated on the Li atom along the x-direction.

.. toctree::
   :maxdepth: 1

   Li migration details <examples/QE.Li-migration.rst> 


**QE.NH3.d**
  Inversion of ammonia molecule (NH\ :sub:`3`\) in a box. The initial push of ARTn moves one atom, specifically the nitrogen atom, along the z-axis.

.. toctree::
   :maxdepth: 1

   NH3 details <examples/QE.NH3.rst> 


**QE.Si-vac.d**
  Diffusion of a vacancy in a silicon crystal of 63 atoms. The initial push of ARTn moves one atom in the vicinity of the vacancy towards it.

.. toctree::
   :maxdepth: 1

   Si-vac details <examples/QE.Si-vac.rst> 


  
 
Siesta
======

**Siesta.Si-vac.d**
  Silicon vacancy example with the Siesta E/F engine

.. toctree::
   :maxdepth: 1

   Si vacancy with Siesta details <examples/Siesta.Si-vac.rst> 

**Siesta.SiO_strand.d**
  Oxygen insertion into Si surface with the Siesta E/F engine

.. toctree::
   :maxdepth: 1

   SiO strand details <examples/Siesta.SiO_strand.rst>

VASP
====

**VASP.Al-vac.d**
  Aluminum vacancy example with the VASP E/F engine 

.. toctree::
   :maxdepth: 1

   Al vacancy with VASP details <examples/VASP.Al-vac.rst> 

  

LAMMPS
======

All LAMMPS examples use the plugin class of lammps to link pARTn library following the specific installation `lammpsinst`_.
If you're using and older version of LAMMPS (befor June 2022) with the pARTn library you can use the same ``lammps.in`` removing the ``plugin load`` and ``plugin list`` command in the script.

.. _lammpsinst: https://mammasmias.gitlab.io/artn-plugin/user_guide/install/install_lammps.html


**LAMMPS.a-Si.d**
    Amorphous Silicon box of 1000 atoms using Sterlinger-Weber interatomic potential.
    The initial push of ARTn move all the atom in random direction ``push_mode = 'all'``.
.. toctree::
   :maxdepth: 1

   a-Si details <examples/LAMMPS.a-Si.rst> 


**LAMMSP.Al-vac-EAM.d**
    Diffusion of Vacancy in aluminum crystal of 255 atoms using EAM interatomic potential.
    One atom around the vacancy is pushed in constrained direction using the option ``push_add_const``.

.. toctree::
   :maxdepth: 1

   Al-vac-EAM details <examples/LAMMPS.Al-vac-EAM.rst> 



**LAMMPS.LJ.SaddleRefine.d**
    Refine saddle point from 200 configurations of 38-atoms cluster describes by Lennard-Jones Potential.
    Artn start directly by compute the minimum hessian eigenvalues to push in the saddle point direct.
    There is two lammps input script:
    - ``lammps-1.in:`` for one saddle point refinement
    - ``lammps.in:`` making a loop in lammps script to be able to refine the 200 configuration in the folder coords-lmp/

.. toctree::
   :maxdepth: 1

   LJ Saddle Refine details <examples/LAMMPS.LJ.SaddleRefine.rst> 

     
**LAMMPS.Oxydation.ReaxFF.d** A simple example of using a shell script
    to launch multiple ARTn explorations. Simulation of silicon
    oxydation in 1200 atoms box using ReaxFF interatomic potential by
    adding two oxygen atoms on top of the surface.  The initial push
    on the two oxygen atoms is constrained to specific directions using the option
    ``push_add_const``.

.. toctree::
   :maxdepth: 1

   Silicon oxydation details <examples/LAMMPS.Oxydation.ReaxFF.rst> 


**LAMMPS.Pt111.d**
    Platinum eptamer on platinum (111) surface for a box of 343 atoms using ``morse/smooth/linear`` pair style potential in LAMMPS.
    This example use an external initial push give in ``ini_push.xyz`` file and using the option ``push_mode = 'file'`` and ``push_guess = 'ini_push.xyz'``.

.. toctree::
   :maxdepth: 1

   Pt111 heptamer details <examples/LAMMPS.Pt111.rst> 


**LAMMPS.Si-vac.d**
    Silicon vacancy in crystal diamond of 511 atoms using the Sterlinger-Weber interatomic potential.
    The initial push of ARTn move all the atom in random direction ``push_mode = 'all'``. 

.. toctree::
   :maxdepth: 1

   Si vacany details <examples/LAMMPS.Si-vac.rst> 

   
**LAMMPS.a-Si.Annealing_bash.d**
  The goal of this example is to show how pART can be used to stabilize the 1000-atom amorphous Si structure.

.. toctree::
   :maxdepth: 1

   a-Si annealing details <examples/LAMMPS.a-Si.Annealing_bash.rst> 


Python
======

**COUPLE/py_metropolis**
    Python script implimentation of a loop of ARTn research associated to LAMMPS.
    A Metropolis algorithm is applied to the barrier of actual event, if found by ARTn, to decide to start the next research from the new minimum or restart from the actual one.
.. toctree::
   :maxdepth: 1

   py_metropolis details <examples/py_metropolis.rst> 

    
**OptBench_SaddleSearch.d**
    This example contains a python script which runs the "saddle search" benchmark test from `OptBench <https://optbench.org/saddle-search.html>`_
.. toctree::
   :maxdepth: 1

   OptBench saddle search details <examples/OptBench_SaddleSearch.rst> 

 
