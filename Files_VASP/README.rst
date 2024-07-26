###########################
Install pARTn for VASP5.4.4
###########################

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

Write in ``VASP/src/main.F`` after the ``CALL CHAIN_FORCE()`` the call to ``artn_vasp()`` subroutine (l.3190)

.. code-block:: Fortran

   CALL CHAIN_FORCE(T_INFO%NIONS,DYN%POSION,TOTEN,TIFOR, &
            LATT_CUR%A,LATT_CUR%B,IO%IU6)
   
   CALL ARTN_VASP( TIFOR, toten, T_INFO, INFO, dyn, latt_cur, IO )

Edit ``Makfile.include`` to add the path for the ``libartn.a`` in variable ``LLIBS`` :

.. code-block:: Makefile

   LLIBS += /path-to-artn/lib/libartn.a

Compile VASP

.. code-block:: bash

   make


.. note::

   Even compilated with, pARTn has to be activated with the keyword ``ARTN = TRUE`` in the ``INCAR`` file

