import lammps
import random 
import numpy as np
import pypARTn2
import utils
import os
from ctypes import c_double


#Parameters
TEMPERATURE = 0.3       # Temperature is  in eV
NUMBER_EVENTS = 50      # Maximum number of succesfull event
ACCEPT_CHECK= "fin-ini" # Can be either "fin-ini" -energy asymmetry- or "sad-ini"
REVERSIBLE   = False     # If True, check whether the event is reversible with MAX_DELR_INI
MAX_DELR_INI = 0.1      # Maximum displacement when returning to initial minimum

# files
filecounter = "filecounter"  # Counter for numbering files and events
refconfig = "refconfig"      # reference configuration from which events are started
file_format = 'lammps'       # Input/Output style : either 'lammps' or 'xyz'

# Set parameter
if REVERSIBLE == False :
   MAX_DELR_INI = 100.0

# create lammps instance (compile lammps for python with 'make install-python' in lammps/src)
lmp = lammps.lammps()
# silent lammps
#lmp = lammps.lammps( cmdargs = ["-log", "none", "-screen", "none"] )

# create artn instance (must be done after creating lammps, needs the 'engine' keyword)
artn = pypARTn2.artn( engine="lmp")

## send some commands to lmmps
lmp.command("units metal")
lmp.command("atom_style charge")
lmp.command("atom_modify map array")
lmp.command("atom_modify sort 0 1")
lmp.command("dimension 3")
lmp.command("boundary    p p p")
lmp.command("read_data   conf.init")
lmp.command("pair_style      vashishta ")
lmp.command("pair_coeff      * * potential_SiO2(vashishta).TPF Si O ")
lmp.command("mass            1 28.0855")
lmp.command("mass            2 15.9994")
lmp.command("set             type 1 charge +1.6")
lmp.command("set             type 2 charge -0.8")
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
artn.set("forc_thr", 2e-1)
artn.set("nevalf_max", 2999)
artn.set("push_step_size", 0.4)
artn.set("eigen_step_size", 0.4)
artn.set("nnewchance",10)
artn.set("ninit", 2)
artn.set("lpush_final", True )
artn.set("struc_format_out", "none")
artn.set("push_mode","rad")
artn.set("push_dist_thr", 2.0)

num_atoms = lmp.get_natoms()

# Create the header to the event list file if needed
utils.create_event_list()

# Reads the reference configuration and counter
counter = utils.get_counter(filecounter)
ref_counter, ref_box, ref_boxlo, ref_boxhi, ref_id, charge, ref_conf,ref_en = utils.read_configuration(refconfig, num_atoms,file_format)

print("Refcounter: ", ref_counter, "  Ref_en:", ref_en)
if ref_counter == 0 or ref_counter > counter :
   ref_counter = counter

ini_file = utils.write_init_configuration(ref_counter, "min", ref_conf, num_atoms,ref_id, charge, ref_en,ref_boxlo,ref_boxhi,file_format)

# Scatter the new positions to lammps
vecsize = 3*num_atoms
x = (vecsize*c_double)()
for i in range(num_atoms) : 
   x[3*i]   = ref_conf[i][0]
   x[3*i+1] = ref_conf[i][1]
   x[3*i+2] = ref_conf[i][2]

lmp.scatter_atoms("x",1,3,x)

iter = 0
while iter < NUMBER_EVENTS :
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
      pos_min1 = artn.extract("tau_min1")
      pos_min2 = artn.extract("tau_min2")

      delr_min1 = artn.extract("delr_min1")
      delr_min2 = artn.extract("delr_min2")
      delr_sad = artn.extract("delr_sad")
      ener_sad = artn.extract("etot_sad")
      ener_min1 = artn.extract("etot_min1")
      ener_min2 = artn.extract("etot_min2")

      if (delr_min1 < delr_min2 and delr_min1 < MAX_DELR_INI ): 
         # Event finds its way back to init
         delr_ini = delr_min1
         delr_fin = delr_min2
         ener_ini = ener_min1
         ener_fin = ener_min2
         pos_fin = pos_min2
      elif (delr_min2 < delr_min1 and delr_min2 < MAX_DELR_INI ):
         delr_ini = delr_min2
         delr_fin = delr_min1
         ener_ini = ener_min2
         ener_fin = ener_min1
         pos_fin = pos_min1
      else: 
         print("Event is not reversible")
         continue

      if ACCEPT_CHECK == "fin-ini" :
         del_en = ener_fin - ener_ini
      elif  ACCEPT_CHECK == "sad-ini" :
         del_en = ener_sad - ener_ini
      else:
         print("ACCEPT_CHECK can only be 'fin_ini' or 'sad_ini'")
         sys.exit(1)
               
      if ref_en == 0.0 :
         ref_en = ener_ini


      # Update the counter, write to counter file and write the sad and fin configurations
      counter = utils.update_counter(counter,filecounter)
      sad_file = utils.write_configuration(counter, "sad", pos_saddle, num_atoms,ref_id, charge, ener_sad,ref_boxlo,ref_boxhi,file_format)
      fin_file = utils.write_configuration(counter, "min", pos_fin, num_atoms,ref_id, charge, ener_fin,ref_boxlo,ref_boxhi,file_format)
   
      # Apply Metropolis criterion
      random_number = np.random.rand() 
      if (del_en < -TEMPERATURE*np.log(random_number) and TEMPERATURE > 0.0) :
         print("Event accepted")
         event_status = "accepted"
         ref_counter = counter
         ref_conf = pos_fin
         ref_en = ener_ini
         utils.write_configuration_name(refconfig, counter, ref_conf, num_atoms,ref_id, charge, ener_fin,ref_boxlo,ref_boxhi,file_format)

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
         en_sad = ener_sad - ener_ini
         feventlist.write(f"  {ini_file}     {sad_file}     {fin_file}    {event_status} {ref_en:9.4f}  {del_en:8.4f}  {en_sad:8.4f}      {delr_sad:8.4f}     {delr_ini:8.4f}     {delr_fin:8.4f}        {selected_atom}\n" )

      # Update the name of ini file after writing the output for the event
      if event_status == "accepted" :
         ini_file = fin_file

      iter = iter + 1


# close artn and lmp instances
artn.destroy()
lmp.close()