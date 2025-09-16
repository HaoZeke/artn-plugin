# Example: bash script for performing ARTn explorations

## Description:

This example shows a simple bash script `exploration.sh` to perform a number of explorations of the potential energy surface with pARTn.
The initial structure is a (001) surface of pure Silicon with reconstructed dimers, and two Oxygen atoms are inserted on top of this surface. The structure is in the file `Cryst_Si_and_O.reax`.

The script `exploration.sh` launches a sequence of 10 event searches:

    nevent=10

Each next search creates a new directory, called `run_Id` where `Id` is the current number of search. It copies all needed files into this new directory, and launches `lammps` within it.

Each exploration starts with an initial deformation localized on one of the two Oxygen atoms that have atomic indices `id=1201` and `id=1202`, respectively.
This is performed by appending a line to the `artn.in` file of the current search, which chooses one of the two indices randomly:

    echo "push_ids = $((1201 + RANDOM % 2 ))" >> artn.in

## Launch command

In order to run the exploration script, the line:

    mpirun -np 1 $LAMMPS_PATH/src/lmp_mpi -in lammps.in

should be modified by inserting the proper path to your `lammps` executable. Then, the script can be launched as:

    ./exploration.sh

## Expected resutls

In the output, you should have 10 `run_id` directories in which you have many possible diffusion events of the Oxygen atoms.

## Additional comments:

The empirical potential used is a reax force field, thus `lammps` must be compiled with:

    make yes-reaxff

