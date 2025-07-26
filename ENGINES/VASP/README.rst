
############################
Install pARTn for VASP 5.4.4
############################

.. note::

   For VASP versions higher than 5.4.4, please contact us.

VASP-5.4.4/pARTn Interface
==========================

#. Create (or copy) your ``makefile.include`` inside the VASP root path.
#. Run the ``configure`` of pARTn, giving the flag ``--with-vasp``, and the path ``VASP_PATH=`` to the root directory of VASP:

   .. code-block:: bash

      cd /path/to/artn-plugin
      ./configure --with-vasp VASP_PATH=/path/to/vasp

   At the end of ``configure``, you should get all further instructions pronted on the screen. They should be pretty much as follows:

#. Compile the pARTn library

   .. code-block:: bash

      make lib

#. Optionally you might be instructed to patch the vasp code, which includes copying the needed interface file to vasp source, adding it to the list of objects, and appending library path to your ``makefile.include``:

   .. code-block:: bash

      make patch-vasp

   The inverse command is to unpatch vasp:

   .. code-block:: bash

      make unpatch-vasp

#. Then you will likely need to recompile vasp:

   .. code-block:: bash

      cd /path/to/vasp
      make std

Now you are ready to launch!


What does the ``configure`` do?
-------------------------------

The ``configure`` script performs several things for VASP:

#. attempts to extract the ``FCL`` compiler from the ``makefile.include``, which is used to compile VASP;
#. copies the interface file ``/artn-plugin/Files_VASP/ARTn_VASP.F`` into the VASP source: ``/path/vasp/src/``;
#. inserts the objects into ``/path/vasp/src/.objetcs``;
#. inserts a call to ``ARTN_VASP`` into the ``/path/vasp/src/main.F``;
#. and adds the library and include paths to the ``makefile.include``.


.. note::

   Presently, the pARTn-VASP interface requires pARTn to be compiled with the same compiler as VASP (this will change soon enough).


.. note::

   Intel compiler: If you compile with the option ``-check all`` you have to add the option ``-check nouninit`` to remove the SPAM of MemorySanitizer


.. _use_in_vasp:
Use in VASP
===========

To use pARTn with VASP, the keyword ``ARTN_is_active = TRUE`` should be set in the ``INCAR`` file, and
also the parameters:

.. code-block::

   IBRION = -1
   ISYM = 0
   POTIM = 0
   ARTN_is_active = TRUE



