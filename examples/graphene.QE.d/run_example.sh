#!/bin/bash

QE_PATH=$(grep "QE_PATH" ../../make.inc | cut -d "=" -f 2)

mpirun -np 2 ${QE_PATH}/bin/pw.x -partn < relax.graphene-3x2.C-vac.in | tee relax.graphene-3x2.C-vac.out
