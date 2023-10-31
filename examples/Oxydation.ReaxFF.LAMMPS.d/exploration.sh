#This script runs 10 differents searchs,
#each located on one of the 2 oxygen atoms.
source ../../environment_variables
export HWLOC_HIDE_ERRORS=2 #hide some warnings

RANDOM=42  # Permits to have exactly the same jobs
nevent=10
for ievent in `seq 0 $nevent`; do
    mkdir run_$ievent
    cd run_$ievent
    cp ../artn.in .
    cp ../lammps.in .
    cp ../Cryst_Si_and_O.reax .
    cp ../ffield.reax.SiOH .
    sed -i "s| ..\/..\/Files_LAMMPS| ..\/..\/..\/Files_LAMMPS|g" lammps.in #put the correct path in lammps.in  
    sed -i "s| push_ids = 1201| push_ids = $((1201 + RANDOM % 2 ))|g" artn.in
    sed -i "s| zseed = 42 | zseed = $((10*$ievent ))|g">>artn.in
    mpirun -np 1 $LAMMPS_PATH/src/lmp_mpi -in lammps.in
    cd ../
done
grep Fail run_*/artn.out
grep "dE=" run_*/artn.out
