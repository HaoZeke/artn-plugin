# Example: Aluminium vacancy diffusion with EAM potential in LAMMPS


## Description:

Starting configuration is a crystal Al with a single vacancy. 
The ARTNn input file `artn.in` specifies the initial push in one atom, specifically the index 251:

    push_mode = 'list'
    push_ids = 251


The direction of the initial push is specified as a random vector in the cone of 45 degress with axis (1.0, 1.0, 0.0), on atom index 251:

    add_const(:,251) = 1.0, 1.0, 0.0, 45.0

## Launch command:

Launch the same way as your favourite LAMMPS calculation:

    ./lmp -in lammps.in

## Expected results:

Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html).

By visualizing the LAMMPS dump file in `config.dmp` you should see the whole process of finding the vacancy diffusion. The ARTn output should report an energy barrier of 0.369 eV.

If you uncomment the last line of `artn.in`:

    zseed = 49550570

you should hopefully obtain the same results as the ones reported in directory `reference.d`.
