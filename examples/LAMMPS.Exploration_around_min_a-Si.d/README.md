# Example: Parallelisation of the PES exploration 

## Description:

The goal of this example is to show how pART can be run using two levels of parallelization.
- 1 over the events
- 2 over the forces
This is performed into a fortran code that use the API of pART to control the I/O without any file. 

The command to modify one parameter is
```fortran
    USE artn_api
    CALL artn_set( "parameter", value, ierr )
```

The command to extract the value of one variable is
```fortran
    artn_extract( "variable_name", value )
```

The LAMMPS commands can also be set after having creating its pointor `lmp`
```fortran
   USE liblammps 
   lmp = lammps( comm=lmp_comm% mpi_val, args =args ) 
```
each command is then set using
```fortran
   CALL lmp% command( "your_command" )
```
The main advantage of using these commands is that the exploration is much faster.
In fact, you do not need to write data to extract the informations concerning the atomic event, 
and you do not need to open and close lammps for each event.

The system is amorphous silicon, controled by an SW potential. 
All the explorations start with a different random vector by imposing a different seed.
This vector is always located on the same central atom and its first neighbors (push_mode ='rad')

## Compilation:
The compilation needs the LAMMPS library. 
Check if the path to LAMMPS is correctly written in your environment variable, then 
```bash
   make group
```
will create the multiple_group.x file and the `Obj` directory containing `lammps.o`, `liblammps.mod` and multiple_group.o

## Launch command:
The code can be run from a terminal using
```bash
   mpirun -np 4 multiple_group.f90
```

## Expected results:
Two parameters are hard coded into multiple_groupe.f90: 
- 1 `ngroup`, that defines the number of processors groups used for the exploration (2 if not changed).
This means `ngroup` explorations are performed in parallel.
This number must be lower than the number of mpi processes asked.
- 2 `nevents`, that defines the total number of explorations (10 if not changed)

The output starts with mpi informations.
If you use `mpirun -np 4` and `ngroup=2`, then you will have two groups of two mpi processes:
```
 PROC=           0 GROUP=           0 key=           0
 PROC=           1 GROUP=           1 key=           0
 PROC=           2 GROUP=           0 key=           1
 PROC=           3 GROUP=           1 key=           1
```
With this configuration, 2 explorations will be performed simultaneously, and the forces will be calculated using 2 processes. 
The processes for which `key=0` are the master of each group, the ones that will extract the output information. 

The informations that are plotted are:
- iEV: indice of the event
- group: group of processes that have performed this exploration
- Connect: True ot False if the saddle point is connected to initial minimum (DEMin1 or DEMin2 quite null)
- Nforc: number of force calculations needed to reach each saddle point
- Ninfl: number of convex region meet. Read more about convex regions [here](https://doi.org/10.1063/5.0210097)
- DEsad, DEMin1, DEMin2: difference of energy between the initial structure and respectivelly the saddle point and the two minima.
- DRsad, DRMin1, DRMin2: distance between the initial structure and respectivelly the saddle point and the two minima.
This information is plotted like this:
```
 iEv group Connect  Nforc Ninfl     DEsad     DRSad      DEMin1    DRMin1      DEMin2    DRMin1
   1   1      T      1732   4      2.9263    1.9022      2.9204    2.0644     -0.0002    0.2498
   0   0      T      2049   8      6.4766    3.2387     -0.0002    3.4736     -0.0002    0.2302
   2   1      T      1208   7      2.9556    1.8025      2.5925    2.3136     -0.0002    0.0428
   4   1      T      1533   5      4.1582    3.7777      3.8616    4.4085     -0.0002    0.1311
```

In addition, one artn.out file is create for each event.
Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/sections/Output.html).
