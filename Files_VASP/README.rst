
.. note::

   For VASP versions higher than 5.4.4, please contact us.

VASP-5.4.4/pARTn Interface 
==========================


**In the** ``artn-plugin/`` **directory:**

Edit the file ``environment_variables``:
 - Define your compilator in the variable ``F90``
 - Define the path of VASP in the variable ``VASP_PATH``
 - Don't forget to define the path for the blas library in the variable ``BLAS_LIB`` 

Write the command: 

.. code-block:: bash

   make vasp

It will compile ARTn and  copy the file ``ARTn_VASP.F`` in ``${VASP_PATH}/src`` directory

**In VASP directory:**

Edit the file ``VASP/src/.objects`` to add the file ``ARTn_VASP.o`` at the compilation.
More precisly in the variable ``SOURCES`` or/and ``SOURCE_GPU`` if you use GPU compilation.

Write in ``VASP/src/main.F`` after the ``CALL CHAIN_FORCE()`` the call to ``artn_vasp()`` subroutine (around l.3190)

.. code-block:: Fortran

   CALL CHAIN_FORCE(T_INFO%NIONS,DYN%POSION,TOTEN,TIFOR, &
            LATT_CUR%A,LATT_CUR%B,IO%IU6)
   
   CALL ARTN_VASP( TIFOR, toten, T_INFO, INFO, dyn, latt_cur, IO )

Edit ``Makfile.include`` to add the path for the ``libartn.a`` in variable ``LLIBS`` :

.. code-block:: Makefile

   LLIBS += /path-to-artn/lib/libartn.a

Compile VASP

.. code-block:: bash

   make all


.. note::

   Intel compiler, remove the ``-check all`` flag because problem during the link of VASP


Use in VASP
===========

To use correctly ARTn the keyword ``ARTN = TRUE`` in the ``INCAR`` file with also the two parameters:

.. code-block::

   IBRION = 3
   POTIM = 0
   ARTN = TRUE

these tells to VASP to do Molecular Dynamic with zero time step, to don't move the ions.


