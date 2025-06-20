#!/bin/bash

LMP_READY=$(grep "with_lammps" ../../make.inc | cut -d "=" -f 2)
if test $LMP_READY = '"no"'; then
	echo "pARTn has not been compiled for lammps. Exiting."
	exit
fi

LAMMPS_PATH=$(grep "LAMMPS_PATH" ../../make.inc | cut -d "=" -f 2)
LMP_MACHINE=$(grep "<machine>" ../../make.inc | cut -d "=" -f 2|tr -d " ")

mpirun -np 2 ${LAMMPS_PATH}/lmp_${LMP_MACHINE} -in lammps.in
