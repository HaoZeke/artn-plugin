############
Introduction
############

This is a working repository of the plugin-ARTn.
The code has been developed in collaboration by Matic Poberznik, Miha Gunde, Nicolas Salles and Antoine Jay.

.. image:: ./.extra/ARTn_workflow-2.png
   :scale: 8 %
   :alt: ARTn workflow schema

The algorithm `ARTn`_ allows the exploration of the energetic landscape of an atomic configuration, to find the saddle point (transition state), and the associated energy minima.

.. _ARTn: https://normandmousseau.com/ART-nouveau.html

Documentation:
==============

The full documentation is available at: `LINK`_.
Please post any issue(s) on `GitLab`_.

.. _GitLab: https://gitlab.com/mammasmias/artn-plugin
.. _LINK: https://mammasmias.gitlab.io/artn-plugin/


Interface with engine
=====================

Currently developed engine interfaces:

- **Quantum ESPRESSO**, to install see: :ref:`install_qe`;
- **LAMMPS**, to install see: :ref:`install_lammps`;
- **Siesta**, see: :ref:`install_siesta`;
- **VASP 5.4.4**, see: :ref:`install_VASP`;



Using ARTn
==========

The installation depends on the Energy/Forces engine you want to use.
For the impatient, typing:

.. code-block:: bash

   make help

should give you some idea what to do.

For complete information please read documentation on the `installation`_.
To customise the input of ARTn read the section `input`_.
The different output files are explained in section `output`_.

.. _installation: https://mammasmias.gitlab.io/artn-plugin/sections/Installation.html
.. _input: https://mammasmias.gitlab.io/artn-plugin/sections/artn_input.html
.. _output: https://mammasmias.gitlab.io/artn-plugin/sections/Output.html


Examples
========

The list of :ref:`examples` using both interfaces.


Issues, bugs, requests
======================

Use the `issue`_ tracker to report the bugs.

.. _issue: https://gitlab.com/mammasmias/artn-plugin/-/issues


License
========

`Terms of use`_. 

.. _Terms of use: ../../TERMS_OF_USE


Citation
========

Please cite the article of this project:

`pARTn: a plugin implementation of the Activation Relaxation Technique nouveau hijacking a minimisation algorithm`, **Computer Physics Comunication** 295, 108961 (2024), M. Poberznik, M. Gunde, N. Salles, A. Jay, A. Hemeryck, N. Richard, N. Mousseau and L. Martin-Samos




