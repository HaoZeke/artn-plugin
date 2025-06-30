.. _f90_artn_step:

artn_step
=========

This is manually added Fortran-style block, that gets interpreted by ``sphinx-fortran`` module.
For more info see `this link <https://sphinx-fortran.readthedocs.io/en/latest/user.domain.html#>`_.

.. f:subroutine:: artn_step(force, nat, posout)

   description of subroutine in .rst file written manually, not captured from source code.

   :p float force(3*nat) [in]: engine force
   :p integer nat [in]: number of atoms
   :r float dr_out(3*nat) [out]: atomic displacement

--------------

The following is captured from Doxygen and merged with the ``breathe`` software.
For documentation see `this website <https://breathe.readthedocs.io/en/latest/index.html>`_.

.. doxygenfile:: artn_step.f90
   :project: plugin-ARTn





