QE.Al-vacancy.d
---------------

Diffusion of vacancy in aluminum crystal of 31 atoms. The inital push of ARTn moves a single atom. The direction of the push is specified as a random vector in the cone of 45 degrees with axis (1.0, 0.0, 1.0).


**Description:**
The ARTNn input file ``artn.in`` specifies the initial push on one atom, specifically the index 1, whereas the direction of the initial push is specified as a random vector in the cone of 45 degress with axis (1.0, 0.0, 1.0), on atom index 1:
::
    push_mode = 'list'
    push_ids = 1
    push_add_const(:,1) = 1.0, 0.0, 1.0, 45.0

In the QE input file ``relax.Al-vacancy.in``, the option ``nosym = .true.`` from ``&SYSTEM`` card, and the option ``ion_dynamics = 'fire'`` from the ``&IONS`` card need to be set.

**Launch command:**
Launch as any QE calculation, specifying the ``-partn`` flag:

.. code-block:: bash

		mpirun -np N /QE_path/bin/pw.x -partn < relax.Al-vacancy.in

**Expected results:**
You should obtain similar results as the ones reported in directory
``reference.d``. Read more about pARTn output files `here`_.


.. _here: https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html
