QE.Alad.Al100.d
---------------

Diffusion of an aluminum adatom on the hollow site of the aluminum (100) surface (the system consists of 151 atoms). Two searches are used, the first one corresponds to the exchange mechanism, and the second to the hopping mechanism. 

**Description:** The starting configuration is an Al adatom adsorbed
in the hollow site on the Al(100) surface. The ``run_example.sh``
generates the two inputs for ARTn searches, for the exchange mechanism
two atoms are displaced; the adatom (index 1) and one of its nearest
neighbors (index 14), The direction of the initial push is constrained
so that the adatom approaches the position of the displaced nearest
neighbor, and the nearest neighbor is displaced twoards a hollow site
and the eigenvalu threshold is lowered, because the eigenvalue of the
eignevector associated to the saddle point is greater than the default
threshold (-0.01):
::
   push_mode = 'list'
   push_ids = 1, 14 
   add_const(:,1) = 1.0, 1.0, -1.0, 0.0
   add_const(:,14) = 1,0, 1.0, 1.0, 0.0
   eigval_thr = -0.005

For the second search, only the adatom is displaced in the direction
twoards one of the nearest hollow sites
::
   push_mode = 'list'
   push_ids = 1
   add_const(:,1) = 0.0, 1.0, 0.0, 0.0



**Launch command:**

To launch this example simply run:

.. code-block:: bash 

	./run_example.sh

.. warning::

   This example is computationally very demanding and should only be
   run on a dedicated machine, utilizing the parallelization
   capabilities of QE by setting the appropriate number of cores in
   ``run_example.sh``. The default value is set to 8 cores, note
   that a single search running on 16 cores (Intel-Xeon W2295 CPU
   3.00GHz) consumes about 5 hours of wall time.


**Expected results:**
If the example concludes succesfully you should obtain two saddle
points, one for the exchange mechanism of Al adatom diffusion, with a
barrier of 0.38 eV and one for the hopping mechanism, with a barrier
of 0.54 eV. An example of a succesfull run (along with the files
generated) is available in the ``reference.d`` folder.

