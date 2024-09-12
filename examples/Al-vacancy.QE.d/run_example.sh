#!/bin/bash

QE_PATH=$(grep "QE_PATH" ../../make.inc | cut -d "=" -f 2)

mpirun -np 2 ${QE_PATH}/bin/pw.x -partn < relax.Al-vacancy.in | tee relax.Al-vacancy.out
