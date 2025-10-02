VASP.Al-vac.d
*************

Diffusion of vacancy in aluminum crystal of 31 atoms. The inital push of ARTn moves a single atom. The direction of the push is specified as a with axis (1.0, 0.0, 1.0).


**Description:**
The ARTNn input file ``artn.in`` specifies the initial push on one atom, specifically the index 1, whereas the direction of the initial push is specified as a random vector in the cone of 45 degress with axis (1.0, 0.0, 1.0), on atom index 1:
::
    push_mode = 'list'
    push_ids = 1
    push_add_const(:,1) = 1.0, 0.0, 1.0, 0.

**Launch command:**

Make sure to modify the ``VASP_PATH`` variable in ``run_example.sh`` to point to the location of the ``VASP`` E/F engine on your system. Then launch this example by running:

.. code-block:: bash

		./run_example.sh
		

