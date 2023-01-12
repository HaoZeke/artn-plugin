*etot_diff_limit*
======================

Syntax
""""""

.. parsed-literal::

   etot_diff_limit = arg

* arg = real


Default
"""""""

.. code-block:: bash

   etot_diff_limit = 80 Ry


Description
"""""""""""

The limit to the difference in energy ``Etot``, between the current and initial configuration.
If ``Etot`` exceeds ``etot_diff_limit``, the research stops with an error:

.. code-block:: bash
 
   Failure message: ENERGY EXCEEDS THE LIMIT


Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""
