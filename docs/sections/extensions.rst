.. _partn_extension:

pARTn Extension 
===============

This figure presente the workflow of pARTn and give an idea of how to build an interface with an E/F engine. 
The interface is composed by 3 main routines: :ref:`f90_artn`, :ref:`f90_move_mode` and :ref:`f90_clean_artn`.


.. image:: ../../.extra/ARTn_workflow-1.png
   :scale: 30 %
   :alt: ARTn workflow schema
   :name: fig-partn_workflow

To resume the philosophy of the Hijacking approach, there is two important parameters: the host algorithm and the E/F engine.
The first parameter constraint the which actual properties :math:`\left\{q_{mod}(i)\right\}` the routine :ref:`f90_move_mode` has to return.
Each host algorithm has its own set of properties it uses to integrate the system.
The second parameter define the implementation strategy of the interface.
Indeed the E/F engine interface will be written in the same language of the E/F engine and follow the philosophy of the software architecture.

For each of theses case the procedure to follow are describes in these two link: 

.. toctree::
   :maxdepth: 1

   extensions_engine
   extensions_algo


