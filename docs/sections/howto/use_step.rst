.. _howto_use_step:

*****************************************
Use pARTn with a non-supported E/F engine
*****************************************

pARTn can also be used with E/F engines which are not directly supported through an interface.
To do that, a separate program/script has to be implemented, which calls the desired E/F engine, and executes prescribed ARTn steps.

.. note::
   In order to use it, pARTn can be compiled without any specific engine, i.e. it suffices to:

   .. code-block:: bash

      ./configure && make lib

   or:

   .. code-block:: bash

      cmake -B <my_builddir> && cmake --build <my_builddir>



The underlying routine here is called ``artn_step()``, which gives the displacement vector associated to the current step in the ARTn algorithm.
Any other interaction with pARTn is done through the API.


Pseudocode
----------

To use the function in action, a pseudocode might look something like (emphasized lines for setting the engine units, and the loop over ARTn steps):

.. tab-set::

    .. tab-item:: fortran
       :sync: fortran

       .. code-block:: fortran
          :linenos:
          :caption: Pseudocode
          :emphasize-lines: 19, 32-52

          use artn_api, only: artn_rp => DP
          use artn_api, only: artn_create, artn_set, artn_extract, artn_step, get_error
          implicit none
          type( other_engine ) :: my_engine
          integer :: maxsteps
          integer :: ierr
          logical :: lerr, lconv
          real( artn_rp ), allocatable :: displ_vec(:,:)

          maxsteps = 500

          !! initialize your E/F engine of choice
          my_engine = engine( ... )

          !! create artn instance
          ierr = artn_create()

          !! set your parameters to artn (remember to check ierr value)
          call artn_set( "engine_units", "lammps/metal", ierr=ierr )
          call artn_set( "verbose", 0, ierr=ierr )
          call artn_set( "struc_format_out", "none", ierr=ierr )
          call artn_set( "nevalf_max", maxsteps, ierr=ierr )
          call artn_set( "forc_thr", force_thr, ierr=ierr )
          !! etc ...

          !! call setup (not strictly necessary, but gives option to modify the runparams from here)
          call setup_artn2( nat, lerr )

          !! allocate the array for dispalcement vector
          allocate( displ_vec(1:3, 1:nat) )

          istep_: do istep = 1, maxsteps

             !! get energy, force of current atomic configuration
             call my_engine% run( positions, types, box, ... , energy, force )

             !! call artn_step, remember it is only on one cpu (``me==0``). Units are as specified above
             if( me==0 ) call artn_step( nat, energy, force, types, positions, box, if_pos, displ_vec, lconv )

             !! bcast the lconv flag, if mpi
             call mpi_bcast( lconv, .... )

             !! exit the loop if convergence flag is .true.
             if( lconv ) exit istep_

             !! apply displacement vector (it's only available on ``me==0`` in mpi), in proper precision
             if( me==0 ) positions = positions + real( displ_vec, kind=positions )

             !! bcast the new positions
             call mpi_bcast( positions, ... )

          end do istep_

          !! check for error (all data is only on ``me==0`` in mpi):
          if( me==0 ) ierr = artn_extract( "has_error", lsuccess )
          call mpi_bcast( lsuccess, ... )

          if( lsuccess ) then
             !! extract data from ``me===0`` and bcast if needed
             !! etcetc ...
          else
             !! get errmsg
             if(me==0) then
                ierr = get_error( msg )
                write(*,*) msg
             end if
             !! whatever error management ...
             call mpi_barrier( ... )
             call mpi_abort( ... )
          end if


    .. tab-item:: C
       :sync: C

       (under construction. Check the fortran version in the meantime, it should be similar for C)

    .. tab-item:: python
       :sync: python

        .. code-block:: python
           :linenos:
           :caption: Pseudocode
           :emphasize-lines: 4,25-41

           import pypARTn

           ## initialize artn, specify the engine as "other"
           a = pypARTn.artn( engine="other" )

           # set the set of units to use: lammps/metal is Ang, eV
           a.set_param( "engine_units", "lammps/metal")

           # set some other params to artn:
           a.set_param( "verbose", 0)
           a.set_param( "forc_thr", 1e-2)
           a.set_param( "ninit", 2)
           a.set_param( "push_step_size", 0.1)
           a.set_param( "nnewchance", 5)
           a.set_param( "struc_format_out", "none")

           # create an initial push vector
           push_in = np.ndarray( [nat,3], dtype=np.float64 )
           push_in = ....
           a.set("push_init", push_in )

           maxsteps = 500
           a.set_param( "nevalf_max", maxsteps-1 )

           ## loop over the steps
           for istep in range( maxsteps ):

               ## compute E/F with the engine of choice, with whatever arguments are needed,
               ## return energy and force of current atomic configuration
               my_engine.run( positions, types, ... , energy, force )

               ## get next displacement vector from artn. Use the previously computed
               ## energy and force, they should be in units of Ang, eV (eqv. to "lammps/metal")
               displ_vec, lconv = a.next_displ( nat, energy, force, types, positions, box, if_pos )

               ## `lconv` is the convergence flag, is `True` when converged, or error.
               if( lconv ):
                   break

               ## `displ_vec` is the next displacement to make
               positions = positions + displ_vec

           # end of run, check for error
           if( a.extract("has_error") ):
               ierr, errmsg=a.get_error()
               print( errmsg )

           # extract desired data
           a.extract( ... )

           # etcetc.

           ## If another exploration will be launched in the same script,
           ## the internal data and parameters of ARTn need to be cleaned before-hand:
           ## (this will keep the input parameters as previously defined)
           #a.clean()

           ## If you wish to completely clean (destroy) the ARTn instance, including
           ## resetting the input parameters to their default values, call:
           a.destroy()



Function reference
------------------

.. tab-set::

    .. tab-item:: fortran
        :sync: fortran

        From fortran, we directly call ``artn_step()`` routine.
        It has the following documentation:

        .. doxygengroup:: artn_step
           :project: plugin-ARTn


    .. tab-item:: C
        :sync: C

        There is a C-bound routine to ``artn_step()``, with the same name:

        .. doxygengroup:: c_artn_step
           :project: plugin-ARTn


    .. tab-item:: python
        :sync: python

        In Python, the wrapper to ``artn_step()`` routine is called ``artn.next_displ()``, and has the documentation:

        .. autoclass:: pypARTn.artn
           :members: next_displ

