.. index:: fix artn

fix artn command
===============

Syntax
""""""

.. parsed-literal::

   fix ID group-ID artn keyword value

* ID, group-ID are documented in :doc:`fix <fix>` command
* artn = style name of this fix command
* zero or more keyword/value pairs may be appended
* keyword = *dmax* or *alpha0* or *delaystep* or *alphashrnk* or *dtgrow* or *dtshrink* or *tmin* or *tmax* or *initialsdelay* or *integrator*

.. parsed-literal::

     *dmax* value = real
     *alppha0* value = real
     *delaystep* value = real
     *alphashrink* value = real
     *dtgrow* value = real
     *dtshrink* value = real
     *tmin* value = real
     *tmax* value = real
     *initialdelay* value = real
     

Examples
""""""""

.. code-block:: LAMMPS

   fix 1 active artn 
   fix 2 all artn alpha0 0.2
   fix 2 all artn alpha0 0.1 alphashrink 0.99 dtshrink 0.5 dmax 0.5 tmax 20 tmin 0.02


Description
"""""""""""


write something


Restart, fix_modify, output, run start/stop, minimize info
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

No information about this fix is written to :doc:`binary restart files <restart>`.  None of the :doc:`fix_modify <fix_modify>` options
are relevant to this fix.  No global or per-atom quantities are stored
by this fix for access by various :doc:`output commands <Howto_output>`.
No parameter of this fix can be used with the *start/stop* keywords of
the :doc:`run <run>` command.

The forces due to this fix are imposed during an energy minimization,
as invoked by the :doc:`minimize <minimize>` command via the
:doc:`neb <neb>` command.

Restrictions
""""""""""""

This command can only be used if LAMMPS was built with PLUGIN
package.  See the :doc:`Build package <Build_package>` doc
page for more info.

Related commands
""""""""""""""""

:doc:`neb <neb>`

Default
"""""""

The option defaults are parallel = neigh, perp = 0.0, ends is not
specified (no inter-replica force on the end replicas).

----------

.. _Mousseau:

**(Mousseau)** .

.. _Henkelman2:

**(Henkelman2)** Henkelman, Uberuaga, Jonsson, J Chem Phys, 113,
9901-9904 (2000).

.. _WeinanE:

**(WeinanE)** E, Ren, Vanden-Eijnden, Phys Rev B, 66, 052301 (2002).

.. _Jonsson:

**(Jonsson)** Jonsson, Mills and Jacobsen, in Classical and Quantum
Dynamics in Condensed Phase Simulations, edited by Berne, Ciccotti,
and Coker World Scientific, Singapore, 1998, p 385.

.. _Maras1:

**(Maras)** Maras, Trushin, Stukowski, Ala-Nissila, Jonsson,
Comp Phys Comm, 205, 13-21 (2016).
