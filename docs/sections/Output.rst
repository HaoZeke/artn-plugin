.. _output:

Output
======

There are various files produced as output of a single pARTn run:

``artn.out``:
"""""""""""""

Contains the details of the current ARTn research. Depending on the value of the ``verbose`` parameter, the number of details printed differs (see :doc:`../params/verbose`). For non-silent mode (``verbosity>0``), they are as follows.

The header contains a resume of input parameters used, written in units defined by the variable ``engine_units`` (see :doc:`../params/engine_units`). The rest of the file contains the information of each step of the ARTn research, compacted into one or several lines. Each line contains the following numbers:

.. code-block:: bash

     istep    ART_step    Etot     init/eign/perp/lanc/relx     Ftot       Fperp      Fpara     eigval      delr  npart evalf  a1
                           [eV]                               -----------[eV/Ang]-----------  [eV/Ang**2]   [Ang]
        0   Bstep void    0.0000     0    0    0    0    0     0.0133     0.0133     0.0000     0.0000     0.0000     0     1   0.00
        1   Bstep/init    0.0424     1    0    4    0    0     1.1156     0.7597     0.8170     0.0000     0.1058     0     6   0.00
        2   Bstep/init    0.1741     2    0    4   17    0     2.3296     1.6015     1.6919     0.5472     0.2117     1    28   0.61
        3   Bstep/init    0.4006     3    0    4   14    0     3.6556     2.5399     2.6292     0.3898     0.3175     6    47   0.81
        4   Bstep/init    0.7281     4    0    4    2    0     5.1192     3.6019     3.6377     0.3892     0.4234     7    54   1.00
        5   Bstep/init    1.1637     5    0    4    2    0     6.7438     4.8114     4.7253     0.3881     0.5292     7    61   1.00
        6   Bstep/init    1.7147     6    0    4    2    0     8.5506     6.1901     5.8988     0.3866     0.6350     7    68   1.00
        7   Bstep/init    2.3885     7    0    4    2    0    10.5588     7.7569     7.1636     0.3845     0.7409     7    75   1.00
        8   Bstep/init    3.1924     8    0    4    2    0    12.7850     9.5287     8.5240     0.3817     0.8468     7    82   1.00
        9   Bstep/init    4.1336     9    0    4    2    0    15.2436    11.5202     9.9825     0.3780     0.9526     7    89   1.00
       10   Sstep/smth    4.3998     9    1    4   17    0    15.8527    15.4459     3.5683    -0.4762     1.0037     7   111   0.23
       11   Sstep/smth    4.1651     9    1    8    8    0    14.9397    14.9095     0.9502    -0.6058     0.9698     7   128   0.99
       12   Sstep/eign    3.3500     9    1   12   17    0    11.2293    11.2010     0.7968    -1.0900     1.0246     7   158   0.16
       13   Sstep/eign    2.2708     9    1   16    7    0     6.2064     6.0974     1.1582    -1.2398     1.0697     8   182   0.99
       14   Sstep/eign    1.0081     9    1   36    9    0     1.4098     0.9444     1.0467    -1.2137     1.0057     8   228   0.95
       15   Sstep/eign    1.0721     9    1   20    9    0     1.2102     0.8428     0.8685    -0.8023     1.0933     8   258   0.97
       16   Sstep/eign    1.1248     9    1   22    4    0     1.0470     0.7335     0.7471    -0.9048     1.1856     8   285   1.00
       17   Sstep/eign    1.0418     9    1   31    5    0     0.7919     0.5584     0.5615    -0.9824     1.2593     8   322   1.00

                

o

 - ``istep``: iteration step of ARTn;
 - ``ART_step``: computation block, possible values:

     | ``Bstep/init`` basin, initial pushing vector;
     | ``Sstep/eign`` outside of basin, pushing with eigenvector;
     | ``Sstep/smth`` outside of basin, push vector interpolated (*smoothed*);
     | ``Rstep/relx`` unconstrained relaxation.

 - ``Etot``: energy difference from initial configuration;
 - ``init/eign/perp/lanc/relx``: value of iterator "iblock" for each computational block;
 - ``Ftot``: the value of total force;
 - ``Fperp``: value of perpendicular component of the force;
 - ``Fpara``: value of the parallel component of the force;
 - ``eigval``: lowest eigenvalue computed by Lanczos algorithm;
 - ``delr``: the total displacement of the configuration from the initial configuration;
 - ``npart``: number of paricles moved from the initial configuration;
 - ``evalf``: number of force evaluations;
 - ``a1``: scalar product between the current and the previous push direction.


 | Upon reaching different stages of the ARTn algorithm, several lines are printed indicating what happened. For example, when the algorithm has converged to a saddle point, the following is printed:

 .. code-block:: bash

    --------------------------------------------------
     |> ARTn found a potential saddle point | E_saddle - E_initial =     0.98687 eV
     |> Stored in Configuration Files: * Start: initp.xyz | sad0006.xyz
     --------------------------------------------------
     |> DEBRIEF(SADDLE) | dE=      0.98687 eV | F_{tot,para,perp}=      0.00090      0.00029      0.00086 eV/Ang | EigenVal=     -0.32734 eV/Ang**2 | npart=   6.  | delr=      2.72439 Ang | evalf=  809. |
     --------------------------------------------------
     |> Pushing forward to a minimum  ***      
     -------------------------------------------------

 Similar blocks are printed upon relaxation to the adjacent minima.

 When the ARTn algorithm is finished, the finalize block is printed:

 .. code-block:: bash

     --------------------------------------------------
     |> BLOCK FINALIZE..
     |> number of steps: 352
     |> Initial Configuration loaded...
     !> CLEANING ARTn | Fail: 0
     --------------------------------------------------

 The integer number at ``Fail: 0`` indicates possible failure of the research, the value 0 indicates success, while a   positive value indicates the number of failed attempts.

 In case of failure, there is a message containing the reason of failure, for example:

 .. code-block:: bash
                
   Failure message: EIGENVALUE LOST

 For details on how to troubleshoot a calculation see :doc:`troubleshoot` page.

 In the silent mode (``verbose = 0``), the only information is printed at the end of ARTn algorithm, for example:

 .. code-block:: bash

     ifail:  0 * Start: initp.xyz | sad0008.xyz | min0015.xyz | min0016.xyz

 which indicates the possible failure, and filenames containing the structures found by the research.

``initp.*``, ``sad####.*``, and ``min####.*``:
""""""""""""""""""""""""""""""""""""""""""""""

Contain the atomic structures found by the research, the file format ``.*`` is specified by the input variable ``struc_format_out`` (see :doc:`../params/struc_format_out`):

 - The ``initp.*`` contains the initial configuration, at the start of ARTn algorithm;
 - The ``sad###.*`` contains the saddle point found, where ``####`` are automatically assigned numbers, which are kept track in a file called ``sadcounter``, and increase by one for each new ARTn research.
 - Two ``min####`` files, containing the minima obtained by +/- relaxation from the saddle point.


``latest_eigenvec``:
""""""""""""""""""""

Contains the latest eigenvector obtained by Lanczos procedure. This can be useful when restarting a calculation with a prescribed initial eigenvector (see :doc:`../params/eigenvec_guess`).

``random_seed.dat``:
""""""""""""""""""""

Contains the value of random seed ``zseed`` that was used in the calculation. Knowing this value can be useful when it is desired to launch exactly the same calculation again, possibly for debugging, or otherwise (see :doc:`../params/zseed`).


``artn.restart``:
"""""""""""""""""

Contains the needed information for pARTn to resume an aborted calculation (see :doc:`../params/lrestart`).

Related pages
"""""""""""""

