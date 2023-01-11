#############
 Plugin-ARTn
#############

This is a working repository of the current version of the plugin-ARTn; currently it can be used with Quantum ESPRESSO and LAMMPS.
This code has been developed in collaboration by Matic Poberznik, Miha Gunde, Nicolas Salles and Antoine Jay.

The repository is developed on `GitLab`_ where you can post your `issue(s)`_.

.. _GitLab: https://gitlab.com/mammasmias/artn-plugin
.. _issue(s): https://gitlab.com/mammasmias/artn-plugin/-/issues


.. image:: ../.extra/ARTn_workflow-1.png
   :scale: 30 %
   :alt: ARTn workflow schema

The algorithm `ARTn`_ allows to explore the energetic landscape of configuration to find the saddle point and the energy minimum configuration associate to.

.. _ARTn: https://normandmousseau.com/ART-nouveau.html

Contains:
=========


- ``examples/``: Contains many examples, from molecules to surfaces;
- ``Files_LAMMPS/``: Contains the lammps fix, for the LAMMPS/ARTn interface;
- ``Files_QE/``: Contains the file `plugin_ext_forces.f90`, for the QE/ARTn interface;
- ``README.md``: This file;
- ``src/``: ARTn plugin subroutines;
- ``Makefile``: Compilation commands, uses the environment variables defined in `environment_variables`;
- ``environment_variables``: custom file defining:
	- compilers ``F90``, ``CXX``/``CC``;
	- the paths to ARTn (current directory), BLAS and FORTRAN libraries, and chosen engine(s) QE/LAMMPS;
	- ``PARA_PREFIX`` prefix for launching examples via provided run scripts.



Interface with engine
=====================

Two interfaces has been developed for the moment:

- One for **Quantum ESPRESSO**. To use it read the [manual](./Files_QE/README.md).
- One for **LAMMPS**. Two version exist, one using the class `Plugin`_ of LAMMPS, for this version please read the [manual](./Files_LAMMPS/README.md); The second one does not use the class plugin of LAMMPS because this class exist only since 2022. If you use a version older than 2022 please read the [manual](./Files_LAMMPS/README-old.md)

.. _Plugin: https://docs.lammps.org/plugin.html

Examples
========

The list of :doc:`examples <../examples/rst_README>` using both interfaces.


Using ARTn
==========

To customise the input of ARTn please read the :doc:`manual <./rst_MANUAL>`.



Issues, bugs, requests
======================

Use the `issue`_ tracker to report the bugs.

.. _issue: https://gitlab.com/mammasmias/artn-plugin/-/issues


License
========

`Terms of use`_.

.. _Terms of use: ../TERMS_OF_USE


