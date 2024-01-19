.. _api_usage:

The pARTn API
=============

:ref:`API function documentation <f90_artn_api>` automatically generated from code.


Description
-----------

The provided API functions can be used to control the pARTn through another application.
The API provides functionality to set input parameters to pARTn, and to extract the generated data.

In order to use the API, an interface layer is needed in languages other than C. In the directory ``artn-plugin/interfaces`` there are python and fortran interfaces, and the C header file. Some simple examples of use of each API interface are in the ``examples/COUPLE`` directory.


How does it work?
-----------------

When an instance of the API is created, it creates an instance of the ``artn_data`` module. This module stores the input and output data which can get communicated through the API.
The passing of data from the opened module, into pARTn used by the E/F engine, can happen in two ways:
 a) through the opened shared library ``libartn.so``;
 b) via writing/reading certain files.

The point a) can only happen if the E/F engine opens an instance of the ``libartn.so``, this is the case with the LAMMPS command ``plugin load /path-to-file/libpartn-lmp.so``. In this case, the module ``artn_data`` which is opened and written by the API, is readily available with proper data for LAMMPS. Likewise, during the LAMMPS run, data is written into ``artn_data`` module, which is readily available to the API for extraction.


The point b) exists for cases when the E/F engine cannot be launched in library mode, but instead through a separate process. In that case, the ``artn_data`` instance created and modified by the API must be serialized before launching the engine. After the engine finishes, the generated data also needs to be read back into ``artn_data``.


Setting the input parameters
----------------------------

After creating an instance of the API, input data can be set through the API function ``artn_set()``, which accepts two arguments, one is the name of the variable you are setting, and the second is the value of that variable.
The list of currently supported variables can be printed by calling the ``artn_list_set()`` function.


Extracting generated data
-------------------------

Once and ARTn expoloration, it is possible to extract certain data from the ``artn_data`` module, through calling the ``artn_extract()`` function, which accepts one argument, the name of varibale to extract, while the result of the function is a variable of the proper typ and dimension to hold the extracted value. The list of all variables currently supported for extraction can be printed by calling the ``artn_list_extract()`` function.

The generated data contains some information about the general state of ARTn exploration, such as error messages, number of steps done etc., and four "blocks" of data, each block related to one of the configurations encountered during the ARTn research:

 - ``initial`` : the initial configuration;
 - ``sad`` : the saddle configuration;
 - ``min1`` : the first minimum obtained by relaxation from the saddle;
 - ``min2`` : the second minimum obtained by relaxation from saddle;
 - ``latest`` : used only in case of error.

Each of the blocks has a set of data associated to it, such as the atomic positions, types, the eigenvalue (if applicable), and similar. Therefore, for example extracting the atomic positions at the saddle, one would call ``artn_extract( "coords_sad" )``. Other values follow a similar pattern for the naming.
