#!/bin/bash

QE_PATH=$(grep "QE_PATH" ../../make.inc | cut -d "=" -f 2)

mpirun -np 4  ${QE_PATH}/bin/pw.x -partn -in relax.Si-vac.in | tee relax.Si-vac.out
