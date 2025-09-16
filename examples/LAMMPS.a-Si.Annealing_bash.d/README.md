# Example: Stabilization of amorphous Si


## Description:

The goal of this example is to show how pART can be used to stabilize the 1000-atom amorphous Si structure.
The processus is the following:

-1 do an exploration of the potential energy surface with pART
-2 read the atomic events
-3 chose one of the events
-4 update the structure
-5 clean and go back to 1

Steps 2 to 5 are done in a bash script, KMC.sh, that executes LAMMPS with mpi for step 1

For step 1, you can have 2 levels of parallelization:
one for the number of group of searches (nparev) and one for the number of mpi processes used by the force engin (nparf).
nparf * nparev will be the total number of simultaneous mpi processes.

Each group will do independantly its own searches with lammps in its own diectory. 
The number of events to be searched by each group is defined in the do loop of the lammps.in file

In adequation with your system, you can modify the artn.in file in which is specified the initial push of the exploration.
In this a-Si case, we asked for explorations centered on a specified atom and its neighbors:
  push_mode = 'rad'
  dist_thr=3.5
  push_ids= 955 
and in the KMC.sh, we randomly modify the id of the central atom so that it is different for each seach group:
  sed -i '20d' artn.in
  sed -i '20i\  push_ids= '$((1 + $RANDOM % 1000))' ' artn.in    ##### Mod

## Launch command:

In the KMC script, you can decide:
-the number of steps you want: nsteps
-the temperature (needed if the algo that choses the event is Monte Carlo): temp
-the number of search groups for the events: nparev
-the number of mpi processes you want for the force engine (LAMMPS): nparf
-the algorithm that choses the atomic event (Monte-Carlo, minE, or whatever you want) 

Launch the KMC bash script

    ./KMC.sh

## Expected results:

One KMC.xyz file is created with all the chosen structures and saddle points.
Each searches with artn is saved in the folders stepsX, 
that contains one folder for each group of search and their results.

Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/sections/Output.html).
