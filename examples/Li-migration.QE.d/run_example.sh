#!/bin/bash

QE_PATH=$(grep "QE_PATH" ../../make.inc | cut -d "=" -f 2)

mpirun -np 8 ${QE_PATH}/bin/pw.x -partn < relax.Li-migration.graphite-3x2x2.in | tee relax.Li-migration.graphite-3x2x2.out 
