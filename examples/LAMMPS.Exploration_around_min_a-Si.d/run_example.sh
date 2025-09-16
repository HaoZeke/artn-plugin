#!/bin/bash
make
mpirun -np 4 multiple_group.x 
