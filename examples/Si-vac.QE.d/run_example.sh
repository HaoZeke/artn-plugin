#!/bin/bash

#QE_PATH should be defined in environment_variables
source ../../environment_variables

${PARA_PREFIX} ${QE_PATH}/bin/pw.x -partn -in relax.Si-vac.in > relax.Si-vac.out
