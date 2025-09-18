.. _calling_order:

The order of calls to pARTn
###########################

In order to allow that pARTn can be called in different ways, the way of setting, accessing, and storing its memory needs to be somewhat flexible.


Typical interface
=================

On each step of the host algorithm (i.e. FIRE), a call from the E/F engine to pARTn is made.
A subroutine implementing the single call should typically look something like this (pseudocode):

.. code-block:: fortran

   subroutine plugin_artn( etot, force, ... )
   
      real, intent(in) :: etot
      real, intent(inout) :: force(:)
   
      real :: displ_vec(:)
      real :: force_mod(:)
      logical :: convergence_flag

      !!-------------
      !! in each step:
      !!-------------
   
      !! setup is performed only once, on each further call to setup, it does nothing.
      call setup_artn2()
   
      !! input the current engine energy and force, obtain displacement vector
      call artn( etot, force, ... , displ_vec, convergence_flag )
   
      !! transform the displacement vector into modified force, depending on which
      !! minimization algorithm is used (i.e. FIRE)
      call move_mode( displ_vec, ... , force_mod )
   
      !! overwrite the engine force with modified force
      force = force_mod
   
      !!-------------
      !! if artn has converged (impose the last step for host algorithm):
      !!-------------
      if( convergence_flag ) then:
         !! reset flags, prepare variables for next artn cycle
         call clean_artn()
      end if
   
   end subroutine plugin_artn

After that, the host algorithm will displace the atoms according to ``force_mod``, which effectively means perfomring the ARTn algorithm, instead of the host.

In this type of interface, the pARTn variables are first referenced in the first call to ``setup_artn2``.


Calling through pARTn API
=========================

A typical program which uses the pARTn API and an external E/F engine might look something like (pseudocode):

.. _call-api-label:
.. code-block:: fortran
   :linenos:
   :caption: API call
   :emphasize-lines: 11,14,21,24

   program main
      use artn_api
      implicit none
      integer :: ierr
      real, allocatable :: coords_sad(:,:)
   
      !! create artn
      ierr = artn_create()
   
      !! first need to specify the units
      call artn_set( "engine_units", "...") 
   
      !! set some values to artn variables:
      call artn_set( "forc_thr", 0.02 )
   
      ...
   
      !! call the engine, for example lammps:
      !! This launches the minimizer, which calls a routine similar to the
      !! routine above, on each step of the minimization.
      call lammps% command( "minimize ..." )
   
      !! extract some data from artn after the run
      ierr = artn_extract( "tau_sad", coords_sad )
   
      ...
   
   end program main

In this type of calls, the actual call to the engine (here in line 21), will call an interface to pARTn, similar to the one above. This includes a call to ``setup_artn2()`` on the first step of minimization.

However, in this case some ARTn variables are already referenced *before* the call to ``setup_artn2()``, namely the variables which are set via the ``artn_set()`` routine (here in lines 11 and 14).


Implications for ``setup_artn2()``
==================================

The two cases described above showcase why the routine ``setup_artn2()`` must not hard-set any values to variables, since the variables could be referenced *before* the ``setup_artn2()`` is called, meaning some variables already have a desired value which should not be touched.

How to set values then?
-----------------------

By giving a value at definition of a variable, as:

.. code-block:: fortran

   real(DP) :: forc_thr = 0.001_DP

the variable ``forc_thr`` gets that value when it is first referenced, by loading the module where it is stored, or otherwise. This way of definition also implies the ``SAVE`` keyword for that variable in fortran, but that's another story.

When the variable is referenced through ``artn_set()``, its value is overwritten by the desired value:

.. code-block:: fortran

   call artn_set( "forc_thr", 0.02 )

This call means the value of ``forc_thr`` is changed from 0.001_DP into 0.02.
If the variable ``forc_thr`` is not touched before ``setup_artn2()`` it will keep the value from definition.

Effectively this means that ``setup_artn2()`` must not make any assumptions about values of variables.
This is further complicated due to unit conversions, since then the values are set in engine units, not artn units.
For this reason we initialize the variables which need conversion, to some arbitrary high value, i.e. "undefined":

.. code-block:: fortran

   real(DP) :: forc_thr = NAN_REAL

Based on this, the ``setup_artn2()`` can detect whether the variable has been defined via ``artn_set()`` or not, and set it a default value or not:

.. code-block:: fortran

   if( .not. defined_var( forc_thr ) ) then
      !! set default value to forc_thr in internal units
      forc_thr = ...
   else
      !! variable already defined, do not touch it
   end if

where the function ``defined_var( forc_thr )`` returns ``.true.`` when the value of ``forc_thr`` is different than ``NAN_REAL``, meaning that ``forc_thr`` has already been given a value/defined.

Like this we avoid to convert the same values multiple times.


The ``setup_artn2()`` schema
============================


The pseudocode below is the schema of the ``setup_artn2()`` subroutine.
The routine should be called only once per artn exploration (at the start), so the integer flag ``isetup`` has value ``isetup=0`` if the setup routine has not yet been done, and ``isetup=1`` if yes.

.. code-block:: fortran

   subroutine setup_artn2()

      !! if this is not the istep==0, or setup has already been done somehow, do nothing
      if( istep /= 0 .or. isetup == 1 ) return

      !! if this is not the first call to artn, there is data allocated in the memory from
      !! a previous call. Destroy/deallocate it.
      call destroy_data()

      !! Now initialize the user params, this includes if we need to read
      !! from file or not, makeing the units if they are not yet made,
      !! and checking for any undefined variables to give them good values in artn units.
      call init_user_params()

      !! reset params used for the current artn run
      call reset_runparams()

      !! at this point all parameters have good values, do a check on their consistency, etc.
      call check_artn_params()

      call write_initial_report()

      !! set the flag of setup status to 1, indicating the setup has been done
      isetup = 1
      
   end subroutine setup_artn2()



Implications for ``clean_artn()``
=================================

In order to have the possibility of extracting the resulting data from pARTn (call to ``artn_extract()`` in line 24 of :ref:`API call<call-api-label>`), this data must persist in the memory after ARTn has converged, which means ``clean_artn()`` has already been called from the engine. Thus ``clean_artn()`` should take care to not actually destroy any data.


