#!/bin/bash

VASP_PATH=/home/ajay/Programmes/vasp.5.4.4.pl2/bin

mpirun -np 8  ${VASP_PATH}/vasp_std > GaN-Ga_vac.out
