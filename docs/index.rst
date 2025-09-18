
Plugin-ARTn (pARTn) documentation!
=======================================

..
   This is the online documentation for the plugin-ARTn (pARTn) software.

GitLab `repository`_.

.. _repository: https://gitlab.com/mammasmias/artn-plugin


Introduction
============

Activation-Relaxation Technique nouveau (ARTn) is a method for finding transition states, i.e. saddle points of Potential Energy Surfaces (PES), and the associated minima.
It is an open-ended method, which means only the initial structure is needed to perform the exploration.
More details can be found in the associated :ref:`References<refs>`.

The plugin-ARTn (pARTn) code unifies original ARTn software into a single library, which makes it possible to perform the ARTn saddle point exploration within various Energy/Force engines with minimal coding effort.


Engine interfaces
=================

Currently, pARTn can be used with:

- **Quantum ESPRESSO**: :ref:`install_qe`;
- **LAMMPS**: :ref:`install_lammps`;
- **Siesta**: :ref:`install_siesta`;
- **VASP 5.4.4**: :ref:`install_VASP`;

It is also possible to :ref:`howto_use_step`, with a slight coding effort.



.. toctree::
   :maxdepth: 1
   :caption: User Guide

   user_guide/Installation
   user_guide/Input
   user_guide/Output
   user_guide/HowTo
   user_guide/troubleshoot
   user_guide/Ex
..   sections/Examples


.. toctree::
   :maxdepth: 1
   :caption: Programmer Guide

   programmer_guide/philosophy
   programmer_guide/extensions
   programmer_guide/navigation
   programmer_guide/contributing
..   programmer_guide/API_usage



.. _refs:

References
==========

* G. T. Barkema, N. Mousseau, 1996, https://doi.org/10.1103/PhysRevLett.77.4358
* R. Malek, N. Mousseau, 2000, https://doi.org/10.1103/PhysRevE.62.7723
* H. Kallel, et al., 2010, https://doi.org/10.1103/PhysRevLett.105.045503
* M. C. Marinica, et al., 2011, https://doi.org/10.1103/PhysRevB.83.094119
* M. Trochet, et al., 2015, https://doi.org/10.1103/PhysRevB.91.224106
* A. Jay, et al., 2020, https://doi.org/10.1021/acs.jctc.0c00541
* A. Jay, et al., 2022, https://doi.org/10.1016/j.commatsci.2022.111363
* M. Gunde, et al., 2024 https://doi.org/10.1063/5.0210097
* M. Poberznik, et.al., 2024 https://doi.org/10.1016/j.cpc.2023.108961
