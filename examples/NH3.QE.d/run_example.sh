#!/bin/bash

QE_READY=$(grep "with_qe" ../../make.inc | cut -d "=" -f 2)
if test $QE_READY = '"no"'; then
	echo "pARTn has not been compiled for QE. Exiting."
	exit
fi

QE_PATH=$(grep "QE_PATH" ../../make.inc | cut -d "=" -f 2)

mpirun -np 2 ${QE_PATH}/bin/pw.x -partn  < relax.NH3.in | tee relax.NH3.out 
