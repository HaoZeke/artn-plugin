# Example: Aluminium vacancy diffusion in QE


## Description:

Starting configuration is a crystal Al with a single vacancy. 
The ARTNn input file `artn.in` specifies the initial push in one atom, specifically the index 1:

    push_mode = 'list'
    push_ids = 1


The direction of the initial push is specified as a random vector in the cone of 45 degress with axis (1.0, 0.0, 1.0), on atom index 1:

    add_const(:,1) = 1.0, 0.0, 1.0, 45.0

In the QE input file `relax.Al-vacancy.in`, the option `nosym = .true.` from `&SYSTEM` card, and the option `ion_dynamics = 'fire'` from the `&IONS` card need to be set.

## Launch command:

Launch as any QE calculation, specifying the `-partn` flag:

    mpirun -np N /QE_path/bin/pw.x -partn < relax.Al-vacancy.in

## Expected results:

Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/sections/Output.html).

You should hopefully obtain similar results as the ones reported in directory `reference.d`.
