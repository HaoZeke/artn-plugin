############
Introduction
############

Activation-Relaxation Technique nouveau (ARTn) is a method for finding transition states, i.e. saddle points of Potential Energy Surfaces (PES), and the associated minima.
It is an open-ended method, which means only the initial structure is needed to perform the exploration.

The plugin-ARTn (pARTn) code unifies original ARTn software into a single library, which makes it possible to perform the ARTn saddle point exploration within various Energy/Force engines with minimal coding effort.

Supported engines
=================

Currently, pARTn can be used with:

`Quantum ESPRESSO <https://mammasmias.gitlab.io/artn-plugin/user_guide/install/install_qe.html>`__;
`LAMMPS <https://mammasmias.gitlab.io/artn-plugin/user_guide/install/install_lammps.html>`__;
`Siesta <https://mammasmias.gitlab.io/artn-plugin/user_guide/install/install_siesta.html>`__;
`VASP 5.4.4 <https://mammasmias.gitlab.io/artn-plugin/user_guide/install/install_VASP.html>`__
or `custom engine <https://mammasmias.gitlab.io/artn-plugin/user_guide/howto/use_step.html>`__.

Documentation
=============

The full documentation is available at: `<https://mammasmias.gitlab.io/artn-plugin/>`_.

Compilation
===========

pARTn can be compiled either by ``make`` or ``CMake``.
Please refer to the `installation <https://mammasmias.gitlab.io/artn-plugin/user_guide/Installation.html>`__ page, or any of the ``artn-plugin/ENGINES/<engine>/README.rst`` files.

For the impatient, typing:

.. code-block:: bash

   make help

should give you some idea what to do.

Using pARTn
===========

- `List of input parameters <https://mammasmias.gitlab.io/artn-plugin/user_guide/artn_input.html>`__;
- `Output description <https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html>`__;
- `Tutorials and How-to <https://mammasmias.gitlab.io/artn-plugin/user_guide/HowTo.html>`__.

Issues, questions, bugs, requests
=================================

Use the `issue <https://gitlab.com/mammasmias/artn-plugin/-/issues>`__ tracker.

License
========

`Terms of use`_.

.. _Terms of use: ../../TERMS_OF_USE


Citation
========

Please cite the article of this project (`more references <https://mammasmias.gitlab.io/artn-plugin/#references>`__):

`pARTn: a plugin implementation of the Activation Relaxation Technique nouveau that takes over the FIRE minimisation algorithm`, **Computer Physics Comunications** 295, 108961 (2024), M. Poberznik, M. Gunde, N. Salles, A. Jay, A. Hemeryck, N. Richard, N. Mousseau and L. Martin-Samos. DOI: https://doi.org/10.1016/j.cpc.2023.108961

BibTeX entry:

.. code-block:: bash

   @article{POBERZNIK2024108961,
   title = {pARTn: A plugin implementation of the Activation Relaxation Technique nouveau that takes over the FIRE minimisation algorithm},
   journal = {Computer Physics Communications},
   volume = {295},
   pages = {108961},
   year = {2024},
   issn = {0010-4655},
   doi = {https://doi.org/10.1016/j.cpc.2023.108961},
   url = {https://www.sciencedirect.com/science/article/pii/S0010465523003065},
   author = {M. Poberznik and M. Gunde and N. Salles and A. Jay and A. Hemeryck and N. Richard and N. Mousseau and L. Martin-Samos},
   keywords = {Saddle point, Potential energy surface, Transition state, Chemical reaction},
   abstract = {}
   }

Acknowledgment
==============

The developers are active members of the Multiscale And Multi-Model
ApproacheS for Materials In Applied Science consortium (MAMMASMIAS
consortium), and acknowledge the efforts of the consortium in
fostering scientific collaboration. This work was partially supported
by the Slovenian Research and Innovation Agency, under the grant
number J1-50218.
