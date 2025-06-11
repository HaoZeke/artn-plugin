import lammps
import random 
import numpy as np
import pypARTn2
import utils
import os
from ctypes import c_double


# Temperature is  in eV
TEMPERATURE = 0.3 
NUMBER_EVENTS = 20
filecounter = "filecounter"
refconfig = "refconfig"

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
artn.set("nsmooth",3)
artn.set("forc_thr", 2e-3)
artn.set("nnewchance",30)
artn.set("ninit", 2)
artn.set("lpush_final", True )
artn.set("struc_format_out", "none")
artn.set("push_mode","rad")
artn.set("push_dist_thr", 3.0)

num_atoms = lmp.get_natoms()

# Create the header to the event list file if needed
utils.create_event_list()

# Reads the reference configuration and counter
counter = utils.get_counter(filecounter)
ref_counter, ref_box, ref_id, ref_conf,ref_en = utils.read_configuration(refconfig, num_atoms)
ini_file = utils.write_init_configuration(ref_counter, "min", ref_conf, num_atoms,ref_id, ref_en,ref_box)

# Scatter the new positions to lammps
vecsize = 3*num_atoms
x = (vecsize*c_double)()
for i in range(num_atoms) : 
   x[3*i]   = ref_conf[i][0]
   x[3*i+1] = ref_conf[i][1]
   x[3*i+2] = ref_conf[i][2]

lmp.scatter_atoms("x",1,3,x)


for i in range(NUMBER_EVENTS) :
   selected_atom = random.randint(0,num_atoms)
   print("Event #", i, "    Displaced atom: ", selected_atom)
   artn.set("push_ids", [selected_atom])

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
   else : 
      print( "number of force evaluations:", artn.extract("nevalf") )
      print( "number of times eigval lost:", artn.get_runparam("inewchance") )


      eval_saddle = artn.extract("eigval_sad")
      print( "eigenvalue at saddle:", eval_saddle )

      pos_saddle = artn.extract("tau_sad")
      pos_fin = artn.extract("tau_min2")

      delr_ini = artn.extract("delr_min1")
      delr_fin = artn.extract("delr_min2")
      delr_sad = artn.extract("delr_sad")
      ener_sad = artn.extract("etot_sad")
      ener_ini = artn.extract("etot_min1")
      ener_fin = artn.extract("etot_min2")
      del_en = ener_sad - ener_ini



      counter = utils.update_counter(counter,filecounter)
      sad_file = utils.write_configuration(counter, "sad", pos_saddle, num_atoms,ref_id, ener_sad,ref_box)
      fin_file = utils.write_configuration(counter, "min", pos_fin, num_atoms,ref_id, ener_fin,ref_box)
   
      # Apply Metropolis criterion
      random_number = np.random.rand() 
      if (del_en < -TEMPERATURE*np.log(random_number) and TEMPERATURE > 0.0) :
         print("Event accepted")
         event_status = "accepted"
         ref_counter = counter
         ref_conf = pos_fin
         ini_file = fin_file
         utils.write_configuration_name(refconfig, counter, ref_conf, num_atoms,ref_id, ener_fin,ref_box)

         # Scatter the new positions to lammps
         vecsize = 3*num_atoms
         x = (vecsize*c_double)()
         for i in range(num_atoms) : 
           x[3*i]   = ref_conf[i][0]
           x[3*i+1] = ref_conf[i][1]
           x[3*i+2] = ref_conf[i][2]

         lmp.scatter_atoms("x",1,3,x)

      else:
         event_status = "rejected"

      with open("eventlist", "a") as feventlist :
         feventlist.write(f"  {ini_file}     {sad_file}     {fin_file}    {event_status}   {del_en:8.4f}   {delr_sad:8.4f}    {random_number}\n" )



# close artn and lmp instances
artn.destroy()
lmp.close()

