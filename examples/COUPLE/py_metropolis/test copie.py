import lammps
import random 
import numpy as np
import pypARTn2

init_push= "random"


# create lammps instance (compile lammps for python with 'make install-python' in lammps/src)
lmp = lammps.lammps()
# silent lammps
#lmp = lammps.lammps( cmdargs = ["-log", "none", "-screen", "none"] )

# create artn instance (must be done after creating lammps, needs the 'engine' keyword)
artn = pypARTn2.artn( engine="lmp")


## send some commands to lmmps
lmp.command("units metal")
lmp.command("atom_modify map array")
lmp.command("atom_modify sort 0 1")
lmp.command("dimension 3")
lmp.command("read_data   conf.sw")
lmp.command("pair_style sw ")
lmp.command("pair_coeff * * Si.sw Si")
lmp.command("mass        1  29.0")
lmp.command("neighbor        0.0  bin")
lmp.command("neigh_modify    delay 0 every 1 check no")

lmp.command('run 0 post no')

## load artn plugin
lmp.command("plugin load ../../../lib/libartn-lmp.so")

## set artn fix
lmp.command("fix 10 all artn dmax 8.0")

lmp.command("min_style fire")
#lmp.command("dump 10  all custom 1 config.dmp id type x y z fx fy fz")


# set some variables to artn:
artn.set( "engine_units","lammps/metal" )
artn.set("verbose", 3)
artn.set("forc_thr", 2e-3)
artn.set("nnewchance",1)
artn.set("ninit", 2)
artn.set("lpush_final", True )
artn.set("struc_format_out", "none")
num_atoms = lmp.get_natoms()

# set custom initial push vector
push_init = np.zeros([num_atoms, 3], dtype=np.float64 )

if (init_push== "random" ) :

   x = lmp.gather_atoms("x",1,3) # Vecteur 1-3000
   boxlo, boxhi, xy, yz, xz, periodicity, box_change = lmp.extract_box()

   boxl = np.zeros(3)
   boxl = boxhi-boxlo
   invbox = 1.0/boxl

   idx = lmp.find_pair_neighlist('sw')
   nl = lmp.numpy.get_neighlist(idx)
   tags = lmp.extract_atom('id')   
   icenter = random.randint(0,num_atoms)
   print("Initial move - central atom: ", icenter)

   dr = 0.0
   natom_displaced = 0
   atom_displaced = np.zeros([num_atoms])
   xi = x[icenter]
   yi = x[icenter+ num_atoms]
   zi = x[icenter+2*num_atoms]

   y = x[num_atoms:2*num_atoms-1]
   z = x[num_atoms:3*num_atoms-1]

   natom_displaced = 0
   atom_displaced = np.zeros(num_atoms,dtype=int)
   dx = np.zeros(num_atoms,dtype=float)
   dy = np.zeros(num_atoms,dtype=float)
   dz = np.zeros(num_atoms,dtype=float)


   # Move central atom
   dr2 = 1.0
   while (dr2 > 0.25) :
      dx[icenter] = random.uniform(-0.5, 0.5)
      dy[icenter] = random.uniform(-0.5, 0.5)
      dz[icenter] = random.uniform(-0.5, 0.5)
      
      ! Ensures that the random
      ! displacement is isotropic
      dr2 = dx(icenter)**2 + dy(icenter)**2 + dz(icenter)**2
            
      natom_displaced = natom_displaced + 1
      atom_displaced(icenter) = 1


   # We now turn to the first neighbours
   lcutoff2 = 0.0
   idx, list_neighbors  = nl.get(icenter)
   print("!!! neighbors: ", num_atoms, idx,tags[idx],nlist.size, nlist[0], tags[nlist[0]])
   for j in range(nlist_neighbors.size) :

      xij = x[j] - xi - boxl[1] * round((x[j]-xi) * invbox[1])
      yij = y[j] - yi - boxl[2] * round((y[j]-yi) * invbox[2])
      zij = z[j] - zi - boxl[3] * round((z[j]-zi) * invbox[3])

      drij2 = xij*xij + yij*yij + zij*zij
      if ( drij2 < lcutoff2 ) :
         dr2 = 1.0
         while (dr2 > 0.25) :
            dx[j] = random.uniform(-0.5, 0.5)
            dy[j] = random.uniform(-0.5, 0.5)
            dz[j] = random.uniform(-0.5, 0.5)

            # Ensures that the random
            # displacement is isotropic
            dr2 = dx[j]**2 + dy[j]**2 + dz[j]**2
            
         natom_displaced = natom_displaced + 1
         atom_displaced[j] = 1


#   call center_and_norm ( INITSTEPSIZE )
  


   print("!!! neighbors: ", num_atoms, idx,tags[idx],nlist.size, nlist[0], tags[nlist[0]])
   # push_init(neighbors,push_init, )

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
delr_sad = artn.extract("delr_sad")
ener_sad = artn.extract("etot_sad")
ener_min1 = artn.extract("etot_min1")
ener_min2 = artn.extract("etot_min2")

print( "delr_min1",delr_min1)
print( "delr_sad", delr_sad)
print( "delr_min2",delr_min2)

# close artn and lmp instances
#artn.destroy()
#lmp.close()

