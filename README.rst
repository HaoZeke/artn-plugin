############
Introduction
############

Activation-Relaxation Technique nouveau (ARTn) is a method for finding transition states, i.e. saddle points of Potential Energy Surfaces (PES), and the associated minima.
It is an open-ended method, which means only the initial structure is needed to perform the exploration.

The plugin-ARTn (pARTn) code unifies original ARTn software into a single library, which makes it possible to perform the ARTn saddle point exploration within various Energy/Force engines with minimal coding effort.

.. image:: ./.extra/ARTn_workflow-2.png
   :width: 400
   :alt: ARTn workflow schema


Documentation:
==============

The full documentation is available at: `LINK`_.
Please post any issue(s) on `GitLab`_.

.. _GitLab: https://gitlab.com/mammasmias/artn-plugin
.. _LINK: https://mammasmias.gitlab.io/artn-plugin/


Interface with engine
=====================

Currently developed engine interfaces:

- **Quantum ESPRESSO**, to install see `install_qe`_;
- **LAMMPS**, to install see: `install_lammps`_;
- **Siesta**, see: `install_siesta`_;
- **VASP 5.4.4**, see: `install_VASP`_;

With some more coding effort, it can also be used with an unsupported E/F engine (see `How_to`_).

.. _install_qe: https://mammasmias.gitlab.io/artn-plugin/sections/install_qe.html
.. _install_lammps: https://mammasmias.gitlab.io/artn-plugin/sections/install_lammps.html
.. _install_siesta: https://mammasmias.gitlab.io/artn-plugin/sections/install_siesta.html
.. _install_VASP: https://mammasmias.gitlab.io/artn-plugin/sections/install_VASP.html
.. _How_to: https://mammasmias.gitlab.io/artn-plugin/sections/howto/use_step.html


Using ARTn
==========

The installation depends on the Energy/Forces engine you want to use.
For the impatient, typing:

.. code-block:: bash

   make help

should give you some idea what to do.

- For complete information please read documentation on the `installation`_;
- To customise the input of ARTn read the section `input`_;
- The different output files are explained in section `output`_;
- Tutorials and How-to are available `here`_

.. _installation: https://mammasmias.gitlab.io/artn-plugin/sections/Installation.html
.. _input: https://mammasmias.gitlab.io/artn-plugin/sections/artn_input.html
.. _output: https://mammasmias.gitlab.io/artn-plugin/sections/Output.html
.. _here: https://mammasmias.gitlab.io/artn-plugin/sections/HowTo.html


Examples
========

The list of `examples <https://mammasmias.gitlab.io/artn-plugin/sections/Ex.html>`_.


Issues, bugs, requests
======================

Use the `issue`_ tracker to report bugs/issues/requests.

.. _issue: https://gitlab.com/mammasmias/artn-plugin/-/issues


License
========

`Terms of use`_. 

.. _Terms of use: ../../TERMS_OF_USE


Citation
========

Please cite the article of this project:

`pARTn: a plugin implementation of the Activation Relaxation Technique nouveau that takes over the FIRE minimisation algorithm`, **Computer Physics Comunication** 295, 108961 (2024), M. Poberznik, M. Gunde, N. Salles, A. Jay, A. Hemeryck, N. Richard, N. Mousseau and L. Martin-Samos. DOI: https://doi.org/10.1016/j.cpc.2023.108961


