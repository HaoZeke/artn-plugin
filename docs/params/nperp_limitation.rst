*nperp_limitation*
======================

Syntax
""""""

.. parsed-literal::

   nperp_limitation = arg

* arg = `INT(:)` integer array


Default
"""""""

.. code-block:: fortran

   nperp_limitation = [ 4, 8, 12, 16, -1 ]


Example
"""""""

.. code-block:: fortran

   nperp_limitation = [ 3, 3, 5, 10, 15, 20, -1 ]


Description
"""""""""""

Limit of perpendicular relaxation steps for each ARTn step.
More ARTn goes far from the basin more perpendicular relaxation are needed.
This option ensure a better convergence to the saddle point.
This option allows the user to customize the number of perp relax.
The value ``-1`` means ``no limitation`` and ``-2`` represent ``NULL``.

The size of array is automatically detected.

This mechanism is turned on by default but can be turned off put ``.false.`` to the flag :doc:`lnperp_limitation`


Unexpected behavior
"""""""""""""""""""

The sequence does not reset if eigenvalue goes positive.


Related commands
""""""""""""""""

:doc:`nperp`
:doc:`lnperp_limitation`


Implementation Description
""""""""""""""""""""""""""

Related to this machanism, 5 variables are defined in the module ``d_artn_params``:


.. code-block:: fortran
   
   integer :: def_nperp_limitation(5)
   integer :: nperp_limitation(:)      ! user customizable
   logical :: lnperp_limitation        ! Flag 
   integer :: nperp_step               ! Index of the nperp_limtation array
   integer :: nperp = -1


and two functions are used:


.. code-block:: fortran
   
   subroutine nperp_limitation_init( flag )
     !> Initialize nperp_limitation array as function of the 
     !! nperp and nperp_limitation array defined by the user

   subroutine nperp_limitation_step( incr )
     !> increment the nperp_step value of incr and define nperp = nperp_limitation( nperp_step )
     !! incr = -1 means return to the nperp_step = 1 and nperp = nperp_limitation( nperp_step )



The subroutine ``nperp_limitation_init()`` is called in routine ``setup_artn()`` at the moment to read the input, before to start the ARTn algorithm.
The subroutine ``nperp_limitation_step()`` is called in ``block_lanczos()`` and ``clean_artn()`` to be reinitialized (-1) and called in ``check_force_convergence()`` to be incremented.









