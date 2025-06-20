#!/bin/bash
make
mpirun -np 4 KMC_multiple_group.x 
