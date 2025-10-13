*eigenvec_guess*
======================

Syntax
""""""

.. parsed-literal::

   eigenvec_guess = arg

* arg = character


Default
"""""""

.. code-block:: fortran

   eigenvec_guess = " "


Description
"""""""""""

Filename where the eigenvector guess is read. Use in combination with ``eigenvec_mode='file'``.

This option can be used when a specific eigenvector should be used to start the calculation, for example to refine a saddle point when the eignevector is known.

The file format is *modified xyz* (see below), vector read from file is used as-is.

.. include:: ./modified_xyz.rst


Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`eigenvec_mode`
