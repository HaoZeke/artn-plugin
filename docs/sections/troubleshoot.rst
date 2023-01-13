Troubleshooting
===============

.. note::

   This page lists some common errors, warnings, and failures of the pARTn code. Some insight into what might be their cause is given, and how to go about solving them on your own. For any trouble not listed here, please post an issue to the GitLag `issues <https://gitlab.com/mammasmias/artn-plugin/-/issues>`_ page.



pARTn does not launch?
----------------------

Look into :doc:`Installation`, :doc:`engine_input`, and make sure you have followed all steps correctly.
Also make sure you use the appropriate versions of the E/F engines.
Look up possible error messages related to the E/F engine in their respective reference manuals.


Crash without any message
-------------------------

You are possibly missing a crucial ARTn input parameter, please see :doc:`artn_input` page.

If the problem continues, please post an issue on the GitLab `issues <https://gitlab.com/mammasmias/artn-plugin/-/issues>`_ page.



Fail with a message
-------------------

The ARTn algorithm can fail for several reasons. If the failure occured due to a known reason, there will be a message printed in the ``artn.out`` file, for example as:

.. code-block:: bash

   Failure message: RESTART FILE DOES NOT EXIST

Which gives you an idea of what is happening. Depending on the message, there are several actions you can do to try to resolve the failure, they are listed below.

Error message:
 - ``RESTART FILE DOES NOT EXIST``: you have desired a restart ``lrestart = .true.`` but do not provide the needed restart file ``artn.restart``.

 - ``<variable_name> has unsupported value``: self-explanatory, check :doc:`artn_input`

 - ``ENERGY EXCEEDS THE LIMIT``: The energy difference ``Etot`` of the current configuration has exceeded the limit value, see :doc:`params/etot_diff_limit`. This usually happens when the push direction includes some (near-)collision of atoms, or the step size is much too large, or both.

 - ``BOX EXPLOSION``: this error means the simulation box has exploded, which is identified by a very large movement of atoms coming from the E/F engine, it can happen in LAMMPS.

 - ``Atoms lost``: Same as above.

 - ``Received a NaN value from engine``: there is a problem with some array passed by the E/F engine to pARTn, look into the E/F calculation specification. If no apparent reason, then need to inspect by debugging the code/interface.

 - ``EIGENVALUE LOST``: This is the most common failure when exploring the Potential Energy Surface. It singnifies that the structure is already outside of the basin (a negative lowest eigenvalue of the Hessian has already been found) for some number of steps, but then for some reason that eigenvalue goes back to positive (the value is "lost"). In this case the corresponding eigenvector cannot be trusted anymore to be pointing to the saddle point, thus the default solution is to abort the research.
  There are several possible reasons for this, some numerical, and some physical:

   - due to the Lanczos diagonalization scheme, try tuning the ``lanczos_*`` parameters;

   - due to an abrupt change in the pushing vector when the structure passes the inflection line of the Hessian (lowest eigenvalue becomes negative), which causes the perpendicular relaxation to bring the structure back into the basin. This is mediated by the smoothing factor ``nsmooth`` (see :doc:`params/nsmooth`);

   - the loss of eigenvalue can sometimes be "corrected" by resetting the Lanczos algorithm with a random initial Lanczos vector, the number of times this resetting is allowed during a single research is given by the parameter ``nnewchance`` (see :doc:`params/nnewchance`). Using this method can however bring the structure very far from the initial structure, thus the saddle point and its adjacent minima can be completely irrelevant to what has been originally desired. It is thus recommended to keep ``nnewchance`` at some small integer value, *e.g.* ``nnewchance=2``.

