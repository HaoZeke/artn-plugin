*push_guess*
======================

Syntax
""""""

.. parsed-literal::

   push_guess = arg

* arg = character


Default
"""""""

.. code-block:: bash

   push_guess = " "


Description
"""""""""""

Filename to read the initial push vector, used in combination with ``push_mode='file'``.

The file format is *modified xyz* (see below), vector read from file is used as-is.

.. include:: ./modified_xyz.rst

Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`push_mode`
