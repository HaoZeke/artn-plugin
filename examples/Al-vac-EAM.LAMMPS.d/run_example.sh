#!/bin/bash

#QE_PATH should be define in environment_variables
source ../../environment_variables

$PARA_PREFIX ${LAMMPS_PATH}/src/lmp_mpi -in lammps.in
