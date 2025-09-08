##
## This example shows how to call the `artn.next_displ` function, to obtain the next
## displacement vector from ARTn algorithm.
## The idea is to use any external E/F engine, which is not supported by proper p-ARTn interface,
## and use the `artn.next_displ` function to perform ARTn.
##
## The way to perform ARTn algorithm is then to set a loop of steps, in each step compute energy and force
## with a guven E/F engine, then call `artn.next_displ()` to obtain a displacement, and update
## the atomic positions with it. Once ARTn algorithm converges, the `lconv` flag is set to True.
##
## The ARTn data needs to be cleaned after the exploration (`artn.clean()`), before starting a new one.
##
## For the purpose of this example, the external E/F engine is lammps.
##


import pypARTn
import lammps
import numpy as np

## open artn
a=pypARTn.artn(engine="other")

## open lammps
lmp=lammps.lammps( cmdargs=["-screen", "none", "-log", "none"])

## set some lammps commands
lmp.command("atom_modify map array")
lmp.command("units metal")
lmp.command("read_data pt111_heptamer.in")
lmp.command("pair_style morse/smooth/linear 9.5")
lmp.command("pair_coeff * * 0.7102 1.6047 2.897")
lmp.command("region rb block 0.0 19.2088 0.0 19.2088 0.0 6.0")
lmp.command("group bottom region rb")
lmp.command("fix 1 bottom setforce 0.0 0.0 0.0")

maxstep=1000

nat = 343

## lattice vectors
box=np.ndarray([3,3],dtype=float)
box[0] = [19.2088, 0.0, 0.0]
box[1] = [0.0, 19.0118, 0.0]
box[2] = [ 0.0, 0.0, 30.0]


##
## set artn parameters
##
a.set_param("engine_units","lammps/metal")
# a.set_param("verbose", 0)
a.set_param("verbose", 3)
a.set_param("forc_thr",1e-2)
a.set_param("ninit", 2)
a.set_param("push_step_size", 0.1)
a.set_param("nnewchance", 1)
# a.set_param("struc_format_out","none")
a.set_param("struc_format_out","xyz")
a.set_param("push_mode", "rad")
a.set_param("push_ids", np.array([7]) )
a.set_param("push_dist_thr", 3.0)
a.set_param("lpush_final",True)
a.set_param("nevalf_max",maxstep-1)

## integer atomic types
typ=np.ones([nat],dtype=int)
## array indicating fixed atoms. Set all to 1
if_pos = np.ones([nat,3],dtype=int)


## loop over maxsteps
for istep in range(maxstep):

   ## compute E/F
   lmp.command("run 1")
   x = lmp.gather_atoms("x",1,3)
   f = lmp.gather_atoms("f",1,3)
   etot = lmp.extract_compute("thermo_pe",0,0)

   ## get next displacement from artn
   dr, lconv = a.next_displ( nat, etot, np.reshape(f,[nat,3]), typ, np.reshape(x,[nat,3]), box, if_pos )

   ## convergence criterion achieved
   if( lconv ):
      break

   ## dr is the next displacement to make
   dr = np.reshape(dr, [nat*3] )

   ## displace atoms
   for j in range(3*nat):
      x[j] += dr[j]
   ## give new positions back to lammps
   lmp.scatter_atoms("x",1,3,x)



has_error = a.extract("has_error")
has_sad = a.extract("has_sad")
has_min1= a.extract("has_min1")
has_min2= a.extract("has_min2")

if( has_error ):
   ## error management
   ierr, errmsg = a.get_error()
   print(errmsg)

## extract data on saddle point, etc
if( has_sad ):
   pos_sad = a.extract("tau_sad")

## list all extract-able quantities:
#a.list_extract()

## If another exploration will be launched in the same script,
## the internal data and parameters of ARTn need to be cleaned before-hand:
## (this will keep the input parameters as previously defined)
#a.clean()

## If you wish to completely clean (destroy) the ARTn instance, including
## resetting the input parameters to their default values, call:
#a.destroy()


