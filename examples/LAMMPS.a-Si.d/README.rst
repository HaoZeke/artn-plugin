LAMMPS.a-Si.d
-------------

**Description:**
Amorphous Silicon box of 1000 atoms using Sterlinger-Weber interatomic potential. The initial push of ARTn move all the atom in a random direction. 

The ARTn input ``artn.in`` specifies the initial push on all atoms:

    push_mode = 'all'

With this option, all atoms get displaced initially, the displacement is random, and scaled by ``push_step_size``.

The ``zseed`` value for the random number generator is pre-set to some value. Changing this should produce various possible results.

**Launch command:**

Launch the same way as your favourite LAMMPS calculation:
``./lmp -in lammps.in``

**Expected results:**

Read more about pARTn output files `here <https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html>`_.
