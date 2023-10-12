#This script runs 10 differents searchs,
#each located on one of the 2 oxygen atoms.
. ../../environment_variables
sed -i "s|PUT_HERE_ART_PATH|$ART_PATH\/..\/..|g" lammps.in #put the correct path in lammps.in  
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
    echo "push_ids = $((1201 + RANDOM % 2 ))">>artn.in
    echo "zseed = $((1 + RANDOM % 1000 ))">>artn.in
    echo "/">>artn.in
    mpirun -np 1 $LAMMPS_PATH/src/lmp_mpi -in lammps.in
    cd ../
done
grep Fail run_*/artn.out
grep "dE=" run_*/artn.out
