*eigenvec_mode*
======================

Syntax
""""""

.. parsed-literal::

   eigenvec_mode = arg

* arg = character


Default
"""""""

.. code-block:: bash

   eigenvec_mode = 'all'


Description
"""""""""""

Specify the mode in which to generate a non-zero initial eigen vector, used as the first Lanczos vector.
Possible values are ``'all'``, or ``'file'``.

When using ``eigenvec_mode='file'``, the vector is read from a file, whose filename needs to be provided in ``eigenvec_guess``.

Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

:doc:`eigenvec_guess`.
