.. _partn_input:

***************
The pARTn input
***************

Fortran namelist
----------------

The basic input for pARTn is a file ``artn.in``.
This file needs to be present in the running directory, and needs to have that exact name.

File ``artn.in`` should contain a Fortran namelist named ``artn_parameters`` (case insensitive).
That is a block which ends with a forward slash, like:

.. code-block:: fortran

   &artn_parameters

         ! parameter definitions here

   /

Each parameter should be given on a separate line, with the form:

.. code-block:: fortran

   <name> = <value>

Where ``<name>`` is the case-insensitive name of the paramater, and ``<value>`` is the desired value.
In case of string parameters, the ``<value>`` is case-sensitive.

See also :ref:`artn_input_params`.


Rules
-----

The usual Fortran rules apply within the namelist structure:

 - lines starting with ``!`` are comments;
 - whitespace is ignored;
 - valid specifications of real values:

 .. code-block:: fortran

    forc_thr = 0.01,
    eigval_thr = -1e-2,
    push_step_size = 3.0d-1

 - specification of arrays:

 .. code-block:: fortran

    ! full array:
    nperp_limitation = 4, 12, 16, 22, 25

    ! component of a 2D array:
    push_add_const(:,1) = 1.0, 1.0, 0.0, 30.0

 - specification of string values:

 .. code-block:: fortran

    ! double quote marks
    engine_units = "QE"

    ! single quote marks
    struc_format_out = 'xyz'

 - details such as commas at the end of each line might depend on your Fortran compiler.
