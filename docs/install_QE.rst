##################################
Install pARTn for Quantum ESPRESSO
##################################

QE-7.0/pARTn Interface 
======================


**Install/update the ARTn-plugin**:
First ``configure`` QE, then put correct paths of QE and ART in the ``environment_variables`` file, then compile the libartn.a:

.. code-block:: bash

   cd /path/to/artn-plugin
   make lib

then you need to patch QE, by running:

.. code-block:: bash

   make patch-qe

This command will recompile ``pw`` (QE) automatically.


.. note::

   For QE versions other than 7.0, please contact us.

