Output
======

Various files can be found in output.

- The details of ARTn research is given in file named `artn.out`. This file follows the engine units defined thank to the variable ``engine_units``.  It gives the system parameters evolution used by ARTn to find the saddle point as well as the the balance energies between the locals minimum and saddle point.
- At the beginnning ARTn write the initial configuration in file `initp.*` where `*` is the format indicated by the variable ``struc_format_out``.
- During the ARTn path toward the saddle point, the currently followed eigenvector is stored in the file `lastest_engenvec.*`.
- For each convergence reached, saddle point and local minima, the configurations are stored in files `sad####.*`, and `min####.*`



There are various files produced as output of a single pARTn run:

- ``artn.out``: contains the details of the current ARTn research.
 | Depending on the value of the ``verbose`` parameter, the number of details printed differs (see :doc:`params/verbose`).
  Upon reaching different stages of the ARTn algorithm, several lines are printed indicating what happened. For example, when the algorithm has converged to a saddle point, the following is printed (for ``verbosity>0``):

 .. code-block:: bash

    --------------------------------------------------
     |> ARTn found a potential saddle point | E_saddle - E_initial =     0.98687 eV
     |> Stored in Configuration Files: * Start: initp.xyz | sad0006.xyz
     --------------------------------------------------
     |> DEBRIEF(SADDLE) | dE=      0.98687 eV | F_{tot,para,perp}=      0.00090      0.00029      0.00086 eV/Ang | EigenVal=     -0.32734 eV/Ang**2 | npart=   6.  | delr=      2.72439 Ang | evalf=  809. |
     --------------------------------------------------
     |> Pushing forward to a minimum  ***      
     -------------------------------------------------



- ``initp.*``: contains

- ``sad####`` and ``min####``: contain

- ``latest_eigenvec``: contains

- ``random_seed.dat``: contains

