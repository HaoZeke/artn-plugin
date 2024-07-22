import pypARTn2
import lammps
import numpy as np
import random
import local_defs

## If you have compiled lammps with OpenMP support, use this line
lmp = lammps.lammps( cmdargs = ["-screen", "none", "-log", "none", "-sf", "omp"])

## If you don't have OMP support for lammps use this line
# lmp = lammps.lammps( cmdargs = ["-screen", "none", "-log", "none"])


artn = pypARTn2.artn( engine="lmp" )

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
lmp.command("plugin load ../../lib/libartn-lmp.so")
lmp.command("fix 10 all artn dmax 8.0")
lmp.command("min_style fire")

## get nat
nat = lmp.extract_global('natoms')


# set some variables to artn:
artn.set("engine_units","lammps/metal" )
artn.set("verbose", 0)
artn.set("nperp_limitation", np.array([6,10,12,14,-1]) )
artn.set("converge_property", "norm" )
artn.set("forc_thr", 1e-3)
artn.set("nnewchance",0)
artn.set("nsmooth",2)
# artn.set("ninit", 2)
artn.set("ninit", 3)
artn.set("lpush_final", True )
artn.set("struc_format_out", "none")
artn.set("eigval_thr",-0.05)
artn.set("lanczos_max_size",20)
artn.set("eigen_step_size", 0.3)


## initialize two catalogue objects::

# for saddle structures
cat_sad = local_defs.catalogue()

# for all structures
cat_all = local_defs.catalogue()


### === specifications for generating the initial push (displacement)
# how many atoms can be in the push?
min_Natom = 1
max_Natom = 7

# minimal and maximal norm per each atom: units ang
dmin = 0.05
dmax = 0.5

## atomic indices on which to possibly create an initial displacement
possible_idcs = [0,1,2,3,4,5,6]
### ===================



icr_tot = 0
i=0
# for i in range(30):
while( cat_sad.n_conf < 27 ):
   i += 1
   print( ">>>> Exploration Nr.:", i)
   ## increment Nrun
   cat_all.nrun += 1
   cat_sad.nrun += 1

   # generate integer m on range [min, max)
   m = int( random.uniform(min_Natom, max_Natom+1) )

   # generate m random idcs from the array possible_idcs
   idcs = random.sample( possible_idcs, m )
   print("  push on m atoms:",m, "idcs:", idcs )

   # generate random vector on these indices
   v = local_defs.gen_random_v( nat, idcs, dmin, dmax )

   # set vec to artn
   artn.set("push_init", v)
   # artn.set( "filout", "artn"+str(i)+".out")

   # launch lammps
   # lmp.command("dump 10  all custom 1 config"+str(i)+".dmp id type x y z fx fy fz")
   lmp.command("minimize 1e-3 1e-3 2000 2000")
   # lmp.command("undump 10")


   ## extract info from artn
   success = artn.extract( "has_sad" ) and artn.extract( "has_min1" ) and artn.extract( "has_min2" )
   err = not success
   # print( "ARTn has error:", err, artn.extract("has_error"))
   if err:
      errmsg = artn.get_runparam("error_message")
      print( errmsg )

   ## get the conf from artn
   this_conf = local_defs.conf()
   this_conf.extract_conf( artn )

   # print( "success:",this_conf.success )
   print("  Eb =",this_conf.Eb, "connected =",this_conf.connected )

   ## add to catalogue of all confs
   added = cat_all.add_conf( this_conf )

   if( this_conf.success ):

       ## check Eb
       if( this_conf.Eb < 1.5 and this_conf.connected ):
           ## add to catalogue of saddles:
           ## `added=True` if conf has been added, False if it already exists
           added = cat_sad.add_conf( this_conf )
           print("  :: adding to cat_sad?", added, " :: n_conf =",cat_sad.n_conf )

           ## print some info about the push v
           # rmin = 999.9
           # rmax = 0.0
           # for k in range(m):
           #    j = idcs[k]
           #    rmin = min(rmin, np.linalg.norm(v[j]))
           #    rmax = max(rmax, np.linalg.norm(v[j]))
           #    print(j, np.linalg.norm(v[j])*0.529177)
           # print( rmin*0.529177, rmax*0.529177)

           if( added ):
              ## count CR of new only
              icr_tot += this_conf.cr_count

              ## print current state of saddles catalogue
              # cat_sad.print_run_info()
              cat_sad.print_barriers()

              ## current force count
              print( "Nevalf_tot = ",cat_all.Nf)



cat_all.print_run_info()
print( "icr_tot", icr_tot)
