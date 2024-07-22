.. _api_usage:

#############
The pARTn API
#############

.. toctree:: contents
   :maxdepth: 1

   Interaction_with_partn
   ../group/variable_groups
   ../api/setget_detail



Description
===========

The API can be used to interact with, or fully control the pARTn from another application.
To interact with the memory of pARTn, the ``artn_set`` and ``artn_extract`` functions are used, see :ref:`this <setextract_interf>` page.

All API functions are written in fortran, and have an equivalent C-function.
To use the API in python, an interface module is needed.

In the directory ``artn-plugin/interface`` there is the C-header file ``artn.h``, and the python interface module ``pypARTn2``.


Examples
--------

Some simple examples of calling the pARTn API from different languages are in the ``examples/COUPLE`` directory.


Usage
=====

The general idea is to first use the ``artn_create`` function, which is documented below.
After that, the ARTn memory can be handled externally.

.. doxygengroup:: group_artn_create
   :project: plugin-ARTn


Usage from fortran
------------------

To use the API from fortran, you need to use the ``artn_api2`` module in you code. In order to do that, your source code must be compiled with including the pARTn object files, and linked with ``libartn.so``. For example a caller source file named ``my_code.f90`` could be:

.. code-block:: fortran

   use artn_api2
   implicit none
   integer :: ierr

   ierr = artn_create()

   call artn_set( "engine_units", "lammps/metal" )
   call artn_set( "forc_thr", 1e-3 )

   ! ... etc

To compile this with ``gfortran`` include the ``src/Obj`` directory of pARTn, and link the ``libartn.so``:

.. code-block:: bash

   ARTN_PATH=/your/path/to/pARTn
   ARTN_LIBPATH=$(ARTN_PATH)/lib
   ARTN_LIB=$(ARTN_LIBPATH)/libartn.so

   gfortran -I$(ARTN_PATH)/src/Obj -o my_code.x my_code.f90 $(ARTN_LIB) -Wl,-rpath,$(ARTN_LIBPATH)

The ``-Wl,-rpath,`` part is to specify the path for the linker.

.. note::

   If the caller ``my_code.f90`` will use lammps as the engine, then you should link with ``libartn-lmp.so`` instead.


Usage from C
------------

Under construction, see "Usage from fortran" in the meantime, should be similar if not identical for C.


Usage from python
-----------------

The python interface is the module ``pypARTn2``, in the directory ``artn-plugin/interface``. In order to import the module to python, you need to specify the path in the ``PYTHONPATH`` environment variable:

.. code-block:: bash

   export PYTHONPATH=/your/path/to/artn-plugin/interface:$PYTHONPATH

Then import, and initialize the module with the ``engine`` keyword:

   >>> import pypARTn2
   >>> artn = pypARTn2.artn( engine = "other" )

The ``engine`` keyword currently accepts values ``lammps`` and ``other``. When using lammps as the engine, use the according keyword.

