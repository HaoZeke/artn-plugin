QE.graphene.d
-------------
Diffusion of a vacancy in a graphene sheet of 11 atoms. The initial displacement is generated on a C atom along the y-direction.

**Description:**

The ARTNn input file ``artn.in`` specifies a constrained initial push on atom index 1, along the `y` direction  and the number of initial displacements is limited to 2:
::
   push_mode = 'list'
   push_ids = 1
   push_add_const(:,1) = 0.0, 1.0, 0.0
   ninit = 2

**Launch command:**

To launch this example simply run:

.. code-block:: bash

   ./run_example.sh

or like a regular QE calculation by adding the ``-partn`` flag:

.. code-block:: bash 

		mpirun -np N /QE_path/bin/pw.x -partn -in relax.graphene-3x2.C-vac.in > relax.graphene-3x2.C-vac.out 

**Expected results:**
The saddle point should involve a C atom inbetween two vacant sites, and it is associated  with a barrier of 0.0772 Ry ( 1.05 eV). A sample of the expected output is in ``reference.d``, this example is based on the examples presented in the publication discussing the `R-NEB <https://doi.org/10.1021/acs.jctc.8b01229>`_ method.



