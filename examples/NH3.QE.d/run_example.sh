#!/bin/bash

QE_PATH=$(grep "QE_PATH" ../../make.inc | cut -d "=" -f 2)

mpirun -np 2 ${QE_PATH}/bin/pw.x -partn  < relax.NH3.in | tee relax.NH3.out 
