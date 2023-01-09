Output
======

Various files can be found in output.

- The details of ARTn research is given in file named `artn.out`. This file follows the engine units defined thank to the variable ``engine_units``.  It gives the system parameters evolution used by ARTn to find the saddle point as well as the the balance energies between the locals minimum and saddle point.
- At the beginnning ARTn write the initial configuration in file `initp.*` where `*` is the format indicated by the variable ``struc_format_out``.
- During the ARTn path toward the saddle point, the currently followed eigenvector is stored in the file `lastest_engenvec.*`.
- For each convergence reached, saddle point and local minima, the configurations are stored in files `sad####.*`, and `min####.*`
