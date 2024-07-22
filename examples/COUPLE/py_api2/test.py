import lammps
import numpy as np
import pypARTn2

# create lammps instance (compile lammps for python with 'make install-python' in lammps/src)
lmp = lammps.lammps()
# silent lammps
#lmp = lammps.lammps( cmdargs = ["-log", "none", "-screen", "none"] )

# create artn instance (must be done after creating lammps, needs the 'engine' keyword)
artn = pypARTn2.artn( engine="lmp")


## send some commands to lmmps
lmp.command("units metal")
lmp.command("dimension 3")
lmp.command("read_data   pt111_heptamer.in")
lmp.command("atom_modify sort 0 0.0")
lmp.command("region rb block 0.0 19.2088 0.0 19.2088 0.0 6.0")
lmp.command("group bottom region rb")
lmp.command("fix 1 bottom setforce 0.0 0.0 0.0")
lmp.command("pair_style morse/smooth/linear 9.5")
lmp.command("pair_coeff * * 0.7102 1.6047 2.897")

## load artn plugin
lmp.command("plugin load ../../../lib/libartn-lmp.so")

## set artn fix
lmp.command("fix 10 all artn dmax 8.0")

lmp.command("min_style fire")
#lmp.command("dump 10  all custom 1 config.dmp id type x y z fx fy fz")


# set some variables to artn:
artn.set( "engine_units","lammps/metal" )
artn.set("verbose", 3)
artn.set("nperp_limitation", np.array([3,6,8,-1]) )
artn.set("forc_thr", 2e-3)
artn.set("nnewchance",1)
artn.set("ninit", 2)
artn.set("lpush_final", True )
artn.set("struc_format_out", "none")


# set custom initial push vector
push_init = np.zeros( [343, 3], dtype=np.float64 )
push_init[0] = [-0.1, 0.22, 1.01]
artn.set("push_init", push_init )

# launch lammps
lmp.command("minimize 1e-3 1e-3 1000 1000")

print( "" )
print(" === Extracting data after lammps")


# extract data from pARTn
err = artn.extract( "has_error" )
print( "ARTn has error:", err)
if err:
   errmsg = artn.get_runparam("error_message")
   print( errmsg )

print( "number of force evaluations:", artn.extract("nevalf") )
print( "number of times eigval lost:", artn.get_runparam("inewchance") )


eval_saddle = artn.extract("eigval_sad")
print( "eigenvalue at saddle:", eval_saddle )

pos_saddle = artn.extract("tau_sad")

delr_min1 = artn.extract("delr_min1")
delr_min2 = artn.extract("delr_min2")
ener_sad = artn.extract("etot_sad")
ener_min1 = artn.extract("etot_min1")
ener_min2 = artn.extract("etot_min2")

print( "delr_min1",delr_min1)
print( "delr_min2",delr_min2)

# close artn and lmp instances
#artn.destroy()
#lmp.close()

