# Example: refinement of Lennard-Jones-38 clusters


## Description:

The folder `coords-lmp` contains 200 structures of Lennard-Jones clusters with 38 atoms each. These structures are close to some saddle point configuration, and were taken from the [OptBench Transition State Optimization example](http://optbench.org/tsopt.html).

The artn input `artn.in` specifies that the algorithm directly enters into the Lanczos algorithm, or the so-called refine-mode, by the line:

    ninit = 0

which forces ARTn to make zero initial pushes, thus immediately entering Lanczos.
The ARTn algorithm stops at the saddle, and does not push the structure into the minima. This is achieved by:

    lpush_final = .false.

The flag `lnperp_limitation = .true.` is used, which indicates a customisation of the number of perpendicular relaxation steps. The user-input sequence is set by the command:

    nperp_limitation = 12, 24, -1

where the values indicate 12 steps of perpendicular relax to be done in the first ARTn step, followed by 24 in the next, and from the third step perform relax until some force convergence criterion is met, indicated by value -1.

In this example, the behaviour of lanczos parameters can be crucial to the results, it can thus be used to get a feeling for how it behaves.


There are two lammps input files, `lammps.in`, and `lammps-1.in`:

  - the file `lammps-1.in` performs the calculation on a single structure given in the `read_data` variable;
  - the file `lammps.in` contains a LAMMPS loop construction, which loops over all structures in the folder `coords-lmp`.


## Launch command:

Launch the same way as your favourite LAMMPS calculation:

    ./lmp -in lammps-1.in

or

     ./lmp -in lammps.in



## Expected results:

Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html).

By visualizing the LAMMPS dump file in `config.dmp` you should see the whole process of finding the refined transition.
