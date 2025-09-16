# Example: heptamer island on the Pt(111) surface


## Description:

This example contains the structure from the OptBench [example "saddle search"](http://optbench.org/saddle-search.html#pt-heptamer).

The ARTn input `artn.in` specifies to read the initial push from a file called `ini_push.xyz`:

    push_mode = 'file'
    push_guess = 'ini_push.xyz'

By this option, one can impose a specific vector as initial push to ARTn. Note that the vector is read and used as-is, without any scaling applied. Thus the vector in the file needs to be written in units of ARTn, which is Bohr radius.


## Launch command:

Launch the same way as your favourite LAMMPS calculation:

    ./lmp -in lammps.in

## Expected results:

Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/sections/Output.html).

By visualizing the LAMMPS dump file in `config.dmp` you should see the whole process of finding the saddle poin. The ARTn output should report an energy barrier of 0.986 eV.

See the files in `reference.d` directory for expected results.
