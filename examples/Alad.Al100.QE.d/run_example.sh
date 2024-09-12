#!/bin/bash

QE_PATH=$(grep QE_PATH ../../make.inc|cut -d "=" -f 2)

cat > artn.in << EOF 
&ARTN_PARAMETERS
  engine_units = 'qe'
  ! parameters for the push
  push_mode = 'list'
  ! define which atoms are to be pushed and the constraints ...
  push_ids = 1, 14
  push_add_const(:,1) = 1.0, 1.0, -1.0, 0.
  push_add_const(:,14) = 1.0, 1.0,  1.0, 0.
  ! eigenpush parms
  eigval_thr = -0.005 
  lpush_final = .true.
/
EOF

mpirun -np 8 ${QE_PATH}/bin/pw.x -partn  < artn.Al-hollow.Al100-5x5-6l.in > artn.Al-hollow.Al100-5x5-6l.out  

cp artn.out artn-exchange.out

cat > artn.in << EOF 
&ARTN_PARAMETERS
  engine_units = 'qe'
  ! parameters for the push
  push_mode = 'list'
  ! define which atoms are to be pushed and the constraints ...
  push_ids = 1
  push_add_const(:,1) = 1.0, 0.0, 0.0, 0.
  ! eigenpush parms
  lpush_final = .true.
/
EOF

mpirun -np 8 ${QE_PATH}/bin/pw.x -partn  < artn.Al-hollow.Al100-5x5-6l.in > artn.Al-hollow.Al100-5x5-6l.out  

cp artn.out artn-hopping.out

