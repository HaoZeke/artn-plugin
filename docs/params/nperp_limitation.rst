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

Limit the number of perpendicular relaxation steps in each ARTn step.

The values given by ``nperp_limitation`` array prescribe the maximal number of steps
for the perpendicular relaxation (perp-relax) proedure of each ARTn step.

The first value in the array is used when the eigenvalue is positive (system is in basin).
After a negative eigenvalue is detected, each ARTn step takes the next value of ``nperp_limitation`` as
the maximal number of perp-relax steps.
If the number of ARTn steps exceeds the size of this array, the last value is used
for all further steps.

The value ``-1`` means 'no limitation'. In this case the perp-relax procedure continues until some other stopping criterion is met.

The size of array is automatically detected.

This mechanism is turned on by default, but can be turned off by ``lnperp_limitation = .false.``.


Unexpected behavior
"""""""""""""""""""


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









