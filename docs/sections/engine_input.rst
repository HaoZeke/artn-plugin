.. _engine_input:

#############################
E/F engine inputs
#############################


For a proper execution of pARTn, there are some restrictions on the variables specified in the input files of E/F engines.

.. tab-set::

   .. tab-item:: Quantum ESPRESSO
      :sync: qe

      For a proper execution of pARTn within QE, three variables must always be specified in the QE input file, namely:

       - in the ``CONTROL`` namelist, the calculation type must be specified as ``calculation = "relax"``,
       - in the ``SYSTEM`` namelist, the use of symmetries disabled ``nosym = .true.``,
       - in the ``IONS`` namelist, the dynamics must be specified as ``ion_dynamics="fire"``.

      *minimal example of QE input file:*

      .. code-block:: bash

        &CONTROL
          calculation = 'relax'
        /
        &SYSTEM
          nosym = .true.
        /
        &IONS
          ion_dynamics = 'fire'
        /


   .. tab-item:: LAMMPS
      :sync: lammps


      In LAMMPS, pARTn is implemented as a ``class fix``, and must be used together with the FIRE optimizer:

      .. code-block:: bash

         min_style fire


      The ``fix artn`` passes through the ``class plugin``.
      It can be used only after loading the dynamic library ``libartn-lmp.so``, through ``plugin load`` command:

      .. code-block:: bash

         plugin   load   /path/to/pARTn/lib/libartn-lmp.so
         fix   ID   group-ID   artn   args   value

      For the moment, only ``group-ID = all`` is available.

      It is possible to customize the FIRE parameters you want to use with the ``fix artn``.
      For each parameter you give the ``args`` followed by ``value``.
      The ``args`` can be:

      -  ``alpha``
      -  ``alphashrink``
      -  ``dtshrink``
      -  ``dmax``
      -  ``tmax``
      -  ``tmin``
      -  ``filin``: change the name of input file ``artn.in``.

      Finally, the script is launched with ``minimize`` command:

      .. code-block::

         minimize   etol   ftol   maxiter   maxeval


      NOTE: The function ``delete_atoms`` of LAMMPS should be used with the keyword ``compress yes``.


      *minimal example of LAMMPS input file:*

      .. code-block:: bash

         plugin load /path/to/artn-plugin/lib/libartn-lmp.so
         fix ID all artn dmax value
         min_style fire
         minimize etol ftol maxiter maxeval


   .. tab-item:: Siesta
      :sync: siesta

      The Siesta interface works through LUA.
      Make sure that Lua knows where to search for the file ``artn-plugin/ENGINES/Siesta/partn_lua.so``.
      This can be done by either:

      .. code-block:: bash

          export LUA_CPATH=$LUA_CPATH:";$HOME/artn-plugin/Files_Siesta/?.so;"

      or by declaring it at the beginning of the Lua script.

      In the input file for Siesta, i.e. ``input.fdf``, the MD type needs to be specified to Lua, and the name of Lua script specified:

      .. code-block:: bash

         # Enable Lua
         MD.TypeOfRun     Lua

         # name of the Lua script
         Lua.Script     artn.lua

      The Lua script in ``artn.lua`` can be copied from ``examples/Siesta.Si-vac.d`` directory, and does not need to be modified.


      The Siesta interface uses ``artn_step()`` functionality, thus the internal FIRE is used.
      Its parameters can be modified by adding a namelist ``&fire_params /`` into ``artn.in``, unless a different ``infile`` was specified.


   .. tab-item:: VASP
      :sync: vasp

      To use pARTn with VASP, the keyword ``ARTN_is_active = TRUE`` should be set in the ``INCAR`` file, and
      also the parameters:

      .. code-block::

         IBRION = -1
         ISYM = 0
         POTIM = 0
         ARTN_is_active = TRUE



      The VASP interface uses ``artn_step()`` functionality, thus the internal FIRE is used.
      Its parameters can be modified by adding a namelist ``&fire_params /`` into ``artn.in``, unless a different ``infile`` was specified.




Running the calculation
-----------------------

.. tab-set::

   .. tab-item:: Quantum ESPRESSO
      :sync: qe

      QE calculation with pARTn must be launched with the flag ``-partn``, as follows:

      .. code-block:: bash

         QE/bin/pw.x -partn -inp input_pw

   .. tab-item:: LAMMPS
      :sync: lammps

      LAMMPS calculation is run the same way as any other LAMMPS calculation.

   .. tab-item:: Siesta
      :sync: siesta

      The calculation is run the same way as any other Siesta calculation.

   .. tab-item:: VASP
      :sync: vasp

       The calculation is run the same way as any other VASP calculation.


Related pages:
--------------

.. tab-set::

   .. tab-item:: Quantum ESPRESSO
      :sync: qe

      | The full list of `QE input parameters <https://www.quantum-espresso.org/Doc/INPUT_PW.html>`_
      | :ref:`install_qe`

   .. tab-item:: LAMMPS
      :sync: lammps

      | The full list of `LAMMPS input commands <https://docs.lammps.org/Commands.html>`_
      | :ref:`install_lammps`

   .. tab-item:: Siesta
      :sync: siesta

      :ref:`install_siesta`

   .. tab-item:: VASP
      :sync: vasp

      :ref:`install_vasp`


