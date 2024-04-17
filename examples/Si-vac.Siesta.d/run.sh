rm -f *.MD*
rm -f conf.xyz
export OMP_NUM_THREADS=2
#mpirun --use-hwthread-cpus -np 14 ../../Obj-lua/siesta < in.fdf |tee out
#mpirun -np 8 ../../Obj-lua/siesta < in.fdf |tee out
mpirun -np 8 ../../Obj-luaOMP/siesta < in.fdf |tee out
