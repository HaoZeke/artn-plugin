QE.NH3.d  
--------


**Description:**

An example of identifying a saddle point for a molecular reconfiguration, the inversion of the ammonia (NH_3) molecule.
The starting configuration is an NH3 molecule in a box. 
The ARTn input file `artn.in` specifies the initial push on one atom, specifically the index 1, whereas the direction of the initial push is constrained to the z-axis:
::
   push_mode = 'list'
   push_ids = 1
   add_const(3,1) = -1.0


**Launch command:**

You can run this example with the command: 

``./run_example.sh``

Or as any QE calculation, by specifying the ``-partn`` flag:

.. code-block:: bash 

		mpirun -np N /QE_path/bin/pw.x -partn -in relax.NH3.in > relax.NH3.out


**Expected results:**

You should obtain similar results as the ones reported in directory ``reference.d``, i.e., a barrier of 0.0165 Ry (0.22 eV).
