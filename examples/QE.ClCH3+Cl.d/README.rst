QE.ClCH3+Cl
-----------


**Description:**

An example of identifying a saddle point for a molecular reaction, an
SN2 substitution:
   
 Cl + CH\ :sub:`3`\ Cl -> ClCH\ :sub:`3`\ + Cl

The ARTn input file ``artn.in`` specifies the initial push on three atoms, with indeces
1,2,6, corresponding to Cl,C, and Cl, respectively, which is
constrained along the z axis. For this example the number and step
size of the initial displacements is also increased: 


::

   push_mode = 'list'
   push_ids = 1,2,6
   add_const(3,1) = -0.2
   add_const(3,2) = 0.2
   add_const(3,6) = 1.0
   ninit = 4 
   push_step_size = 0.6


**Launch command:**
You can launch the example with the command: 
``./run_example.sh``

Or as any QE calculation, by specifying the ``-partn`` flag:

.. code-block:: bash 

		mpirun -np N /QE_path/bin/pw.x -partn -in relax.ClCH3+Cl.in > relax.ClCH3+Cl.out

		
**Expected results:**

You should hopefully obtain similar results as the ones reported in directory ``reference.d``, i.e., a barrier of 0.054 Ry (0.735 eV).
