######################
How to use plugin-ARTn
######################

Philosophy
==========

Plugin-ARTn is linked with Energy/Forces calculation engine through the minimization algorithm FIRE. The idea is to launch the engine for a FIRE minimization, and bias the minimization with the plugin-ARTn, to hijack FIRE and perform the ARTn method instead.

How to use
==========

ARTn can be used in different ways, with some optional variables.

- Research from the local minimum...
- Saddle refine...

Input and Parameters
====================

Once the Engine is compiled with the pARTn library, the ARTn input file `artn.in` is automatically read at the first step of the FIRE minimization. 
All parameters related to the ARTn calculation are defined in the file `artn.in`, which should be located in the working directory of the calculation. 

Depending of the engine, the working units change, and it is up to the user to be coherent between the units of input parameters, and the units of the engine. 
This warning is mainly for the **saddle point convergence**. The units are specified by the parameter `engine_units`. 
.. The list of ARTn's parameters are: 
**The values given in the input file should be in engine units**

The input variable are presented and explained in details in the documentation `link`_

.. _link: https://mammasmias.gitlab.io/artn-plugin/


.. .. include:: docs/sections/artn_input.rst
   .. include:: docs/sections/engine_input.rst
   .. inlucde:: docs/sections/Output.rst


The output
==========

Various files can be found in output. 

- The details of ARTn research is given in file named `artn.out`. This file follows the engine units defined thank to the variable `engine_units`.  It gives the system parameters evolution used by ARTn to find the saddle point as well as the the balance energies between the locals minimum and saddle point.
- At the beginnning ARTn write the initial configuration in file `initp.*` where `*` is the format indicated by the variable `struc_format_out`.
- During the ARTn path toward the saddle point, the currently followed eigenvector is stored in the file `lastest_engenvec.*`.
- For each convergence reached, saddle point and local minima, the configurations are stored in files `sad####.*`, and `min####.*`

