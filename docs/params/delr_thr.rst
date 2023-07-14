*delr_thr*
======================

Syntax
""""""

.. parsed-literal::

   delr_thr = arg

* arg = real


Default
"""""""

.. code-block:: bash

   delr_thr = 0.1

Example
"""""""

.. code-block:: bash

    |> ARTn research : 1 0
     --------------------------------------------------
     istep    ART_step    Etot     init/eign/perp/lanc/relx     Ftot       Fperp      Fpara     eigval      delr  npart evalf  a1
                        [Kcal/mol]                               ------[Kcal/mol/Ang]-----  [Kcal/mol/Ang**2]   [Ang]
        0   Bstep void    0.0000     0    0    0    0    0     0.2657     0.2657     0.0109     0.0000     0.0000     0     1   0.00
        1   Bstep/init    3.1206     1    0    5    0    0    49.0089    49.0089     6.9190     0.0000     0.3425     1     7   0.00
        2   Bstep/init    5.2124     2    0    5    0    0    37.3672    44.4687    17.7833     0.0000     0.6251     1    13   0.00

Description
"""""""""""

Threshold at which an atom is considered to have moved. 
This threshold affects the `npart` parameter in the artn.out output.


Unexpected behavior
"""""""""""""""""""


Related commands
""""""""""""""""

