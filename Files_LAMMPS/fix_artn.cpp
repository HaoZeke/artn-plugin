/* ----------------------------------------------------------------------
   LAMMPS - Large-scale Atomic/Molecular Massively Parallel Simulator
   https://lammps.sandia.gov/, Sandia National Laboratories
   Steve Plimpton, sjplimp@sandia.gov

   Copyright (2003) Sandia Corporation.  Under the terms of Contract
   DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains
   certain rights in this software.  This software is distributed under
   the GNU General Public License.

   See the README file in the top-level LAMMPS directory.
------------------------------------------------------------------------- */

#include "fix_artn.h"
#include "artn.h"

#include "atom.h"
#include "compute.h"
#include "domain.h"
#include "error.h"
#include "force.h"
#include "input.h"
#include "memory.h"
#include "modify.h"
#include "region.h"
#include "respa.h"
#include "update.h"
#include "variable.h"
#include "comm.h"
#include "universe.h"

#include "min_fire.h"

#include <cstring>

#include <fstream>
#include <iomanip>
#include <iostream>

#include <stdlib.h>

#include "lammps.h"
#include "library.h"

using namespace std;

using namespace LAMMPS_NS;
using namespace FixConst;

/* ---------------------------------------------------------------------- */
/**
 * @authors
 *   Matic Poberznic
 *   Miha Gunde
 *   Nicolas Salles
 *
 * @brief Constructor of the Class FixARTn
 *
 * @param[in]   lmp        PTR, on the Class lammps
 * @param[in]   narg       INT, number words are in arguments of the executable
 * @param[in]   arg        CHAR, Array of string of the argument
 *
 */
FixARTn::FixARTn(LAMMPS *lmp, int narg, char **arg) : Fix(lmp, narg, arg)
{

  if (narg < 3)
    error->all(FLERR, "Illegal fix ARTn command");

  // ...Set mpi parameters
  me = comm->me;
  nproc = comm->nprocs;

  nloc = nullptr;
  ftot = nullptr;
  xtot = nullptr;
  vtot = nullptr;
  order_tot = nullptr;

  tab_comm = NULL;

  // ...Set to null/0 all the variable of the class
  istep = 0;
  nword = 0;
  nmax = 0;
  word = nullptr;

  nextblank = 0;
  f_prev = nullptr;
  v_prev = nullptr;
  order = nullptr;
  elt = nullptr;
  if_pos = nullptr;

  alpha_init = 0.0;
  alphashrink = 0.0;
  dt_init = 0.0;
  dtsk = 0.0;
  dtgrow = 0.0;
  tmax = 0.0;
  tmin = 0.0;
  dtmax = 0.0;
  dtmin = 0.0;

  check_dmax_flag = 0;
  fire_integrator = 0;
  ntimestep_start = 0.0;

  delaystep_start_flag = 1;

  pe_compute = nullptr;

  etol = 0.0;
  ftol = 0.0;

  // ...Save the Fire Parameter - Init:
  alpha = alpha_init = 0.1;
  alphashrink = 0.99;

  // ...Get timestep
  dt_curr = update->dt;

  // ...Define delaystep for the relaxation
  nsteppos = nsteppos0 = 5;

  dtsk = 0.5;
  dtgrow = 1.1;

  dmax = 0.1;

  tmax = 20.;
  tmin = 0.02;

  fire_integrator = 0;

  int iarg(3);
  while (iarg < narg)
  {



    // read from fix_modify command string
    if (strcmp(arg[iarg], "dmax") == 0)
    // fire parameters
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      dmax = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "alpha0") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      alpha_init = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "delaystep") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      nsteppos0 = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "alphashrink") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      alphashrink = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "dtgrow") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      dtgrow = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "dtshrink") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      dtsk = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "tmax") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      tmax = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "tmin") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      tmin = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "initialdelay") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      if (strcmp(arg[iarg + 1], "yes") == 0)
        delaystep_start_flag = 1;
      else if (strcmp(arg[iarg + 1], "no") == 0)
        delaystep_start_flag = 0;
      else
        error->all(FLERR, "Illegal min_modify command");
      iarg += 2;
    }
    else if (strcmp(arg[iarg], "integrator") == 0)
    {
      if (iarg + 2 > narg)
        error->all(FLERR, "Illegal min_modify command");
      if (strcmp(arg[iarg + 1], "eulerimplicit") == 0)
        fire_integrator = 0;
      else
        error->all(FLERR, "Illegal min_modify command");
      iarg += 2;
    }
    // artn parameters from fix_modify command
    else if( strcmp(arg[iarg], "filin") == 0)
    {
      if( iarg + 2 > narg)
        error->all(FLERR, "Illegal fix_modify commaned");
      if ( set_param( "filin", 0, 0, arg[iarg+1] ) ){
        err_write(__FILE__,__LINE__);
      }
      iarg += 2;
    }
    else
    {
      int n = modify_param(narg - iarg, &arg[iarg]);
      if (n == 0)
        error->all(FLERR, "Illegal fix_modify command");
      iarg += n;
    }
  }

  // char uu[]="lammps/metal";
  // if ( set_param( "engine_units", 0, 0, "lammps/metal" ) ){
  //   err_write(__FILE__,__LINE__);
  // }
  // // set param int
  // double hj = 0.123;
  // int csz[1]={3};
  // if( set_param( "forc_thr", 0, &csz[0], &hj ) ){
  //   err_write(__FILE__,__LINE__);
  // }

  // int size_pushids[1]={3};
  // int push_ids[3]={4,5,-1};
  // if( set_param( "push_ids", 1, &size_pushids[0], &push_ids[0] ) ){
  //   err_write(__FILE__,__LINE__);
  // }


  // get disp_code values from artn
  int ierr;
  void *cval;
  if ( get_runparam( "PERP", &cval ) ){
    err_write(__FILE__,__LINE__ );
  }
  PERP = *(int *)cval;
  if( get_runparam( "RELX", &cval ) ){
    err_write(__FILE__,__LINE__);
  }
  RELX = *(int *)cval;
  // printf( "PERP is:%d\n", PERP);
  // printf( "RELX is:%d\n", RELX);
}

/* ---------------------------------------------------------------------- */

/**
 * @brief Destructor
 */
FixARTn::~FixARTn()
{

  /* deallocate the array */
  memory->destroy(word);
  memory->destroy(order);
  memory->destroy(elt);
  memory->destroy(f_prev);
  memory->destroy(v_prev);
  memory->destroy(if_pos);

  memory->destroy(nloc);
  memory->destroy(ftot);
  memory->destroy(xtot);
  memory->destroy(vtot);
  memory->destroy(order_tot);

  memory->destroy(tab_comm);

  pe_compute = nullptr;
}

/* ---------------------------------------------------------------------- */

/**
 * @brief Set mask to define when this fix must be active
 */
int FixARTn::setmask()
{
  int mask = 0;
  // mask |= POST_FORCE;
  // mask |= POST_FORCE_RESPA;
  mask |= MIN_POST_FORCE;
  mask |= POST_RUN;
  return mask;
}




/* ---------------------------------------------------------------------- */

int FixARTn::modify_param(int narg, char **arg)
{

  int iarg(0);

  printf("\n\t>FIX_ARTN->MODIFY_PARAM::Feature not ready, nothing wil happen...\n\n");
  return 1;

  // read from fix_modify command string
  if (strcmp(arg[narg], "dmax") == 0)
  // fire parameters
  {
    if( narg < 2 )
      error->all(FLERR, "Illegal min_modify command");
    dmax = utils::numeric(FLERR, arg[1], false, lmp);
    //iarg += 2;
    return 2;
  }
  else if (strcmp(arg[0], "alpha0") == 0)
  {
    if( narg < 2 )
      error->all(FLERR, "Illegal min_modify command");
    alpha_init = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "delaystep") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    nsteppos0 = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "alphashrink") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    alphashrink = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "dtgrow") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    dtgrow = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "dtshrink") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    dtsk = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "tmax") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    tmax = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "tmin") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    tmin = utils::numeric(FLERR, arg[iarg + 1], false, lmp);
    return 2;
  }
  else if (strcmp(arg[iarg], "initialdelay") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    if (strcmp(arg[iarg + 1], "yes") == 0)
      delaystep_start_flag = 1;
    else if (strcmp(arg[iarg + 1], "no") == 0)
      delaystep_start_flag = 0;
    else
      error->all(FLERR, "Illegal min_modify command");
    return 2;
  }
  else if (strcmp(arg[iarg], "integrator") == 0)
  {
    if (iarg + 2 > narg)
      error->all(FLERR, "Illegal min_modify command");
    if (strcmp(arg[iarg + 1], "eulerimplicit") == 0)
      fire_integrator = 0;
    else
      error->all(FLERR, "Illegal min_modify command");
    return 2;
  }
  // artn parameters from fix_modify command
  else if( strcmp(arg[iarg], "filin") == 0)
  {
    if( iarg + 2 > narg)
      error->all(FLERR, "Illegal fix_modify commaned");
    if ( set_param( "filin", 0, 0, arg[iarg+1] ) ){
      err_write(__FILE__,__LINE__);
    }
    return 2;
  }
  return 0;

}


/* ---------------------------------------------------------------------- */

/**
 * @brief Initialize the class
 */
void FixARTn::init()
{

  // Check if FIRE minimization is well define
  if (strcmp(update->minimize_style, "fire") != 0)
    error->all(FLERR, "Fix/ARTn must be used with the FIRE minimization");

  // compute for potential energy
  int id = modify->find_compute("thermo_pe");
  if (id < 0)
    error->all(FLERR, "Fix/ARTn could not find thermo_pe compute");
  pe_compute = modify->compute[id];

  // Check the option atom_modify sort 0 1 is available
  if( atom->sortfreq && atom->userbinsize != 1 )
    error->warning(FLERR, "Fix/ARTn needed option atom_modify sort 0 1"); 

  // Initialize some variable
  istep = 0;
  nword = 6;

  // Communication
  nmax = atom->nmax;
  memory->create(tab_comm, nmax, "pair:tab_comm");

  // printf( "tag_enable %d\n", atom->tag_enable);
  // if( comm->me==0){
  //   for( int i=0; i<atom->nlocal; i++){
  //     printf( "0 tag %d %d\n", i,atom->tag[i]);
  //   }
  // }
  // if( comm->me==1){
  //   for( int i=0; i<atom->nlocal; i++){
  //     printf( "1 tag %d %d\n", i,atom->tag[i]);
  //   }
  // }

}

/* ---------------------------------------------------------------------- */

/**
 * @brief Setup the class
 */
void FixARTn::min_setup(int vflag)
{

  class Min *minimize = update->minimize;

  if (comm->me == 0)
  {
    if (logfile)
      fprintf(logfile, " * FIX/ARTn::CHANGE PARAM...\n");
    if (screen)
      fprintf(screen, " * FIX/ARTn::CHANGE PARAM...\n");
  }

  // ...Comparison of push_step_size with dmax to don't be crazy
/*  void *cval;
  //if( get_param("push_step_size", &cval) )
  //   err_write(__FILE__, __LINE__);
  get_param("push_step_size", &cval); 
  double push_step_size = *((double *)cval);
  printf("\t>> push_step_size %lf\n", push_step_size );
  

  if( dmax < push_step_size ){
    printf("\t>> WARNING: dmax of FIRE lower than push_step_size of ARTn\n\t>> dmax = push_step_size");
    dmax = push_step_size;
  }*/

  /*
  -- Change & Save the initial Fire Parameter
     Exept: delaystep_start_flag = 1 (ALWAYS)
  */
  nword = 12;
  if (word)
    memory->destroy(word);
  memory->create(word, nword, 20, "fix:word");

  string str;
  strcpy(word[0], "alpha0");
  str = to_string(alpha_init);
  strcpy(word[1], str.c_str());
  strcpy(word[2], "alphashrink");
  str = to_string(alphashrink);
  strcpy(word[3], str.c_str());
  strcpy(word[4], "delaystep");
  str = to_string(nsteppos0);
  strcpy(word[5], str.c_str());
  strcpy(word[6], "halfstepback");
  strcpy(word[7], "no");
  strcpy(word[8], "integrator");
  strcpy(word[9], "eulerimplicit");
  strcpy(word[10], "dmax");
  str = to_string(dmax);
  strcpy(word[11], str.c_str());

  minimize->modify_params(nword, word);

  dt_init = update->dt;

  dtmax = tmax * dt_init;
  dtmin = tmin * dt_init;

  // fire_integrator = 0;
  ntimestep_start = update->ntimestep;

  etol = update->etol;
  ftol = update->ftol;

  // ...We Change the convergence criterium to control it
  update->etol = 0.0;
  update->ftol = 0.0;

  // ... set nevalf_max to artn from max_eval of lmp. Minus one because start at zero
  int nevalf_max = update->max_eval-1;
  if( set_param( "nevalf_max", 0, 0, &nevalf_max ) ){
    err_write(__FILE__,__LINE__);
  }


  // ...Print the new Parameters
  minimize->setup_style();

  // ...Print the Initial Fire Parameters
  if (comm->me == 0)
  {
    if( screen ){
      fprintf(screen, " * alpha0 -> %6g\n", alpha_init);
      fprintf(screen, " * dt0 -> %6g\n", dt_init);
      fprintf(screen, " * dtmin -> %4g\n", dtmin);
      fprintf(screen, " * dtmax -> %4g\n", dtmax);
      fprintf(screen, " * ftm2v -> %6g\n", force->ftm2v);
      fprintf(screen, " * dmax -> %4g\n", dmax);
      fprintf(screen, " * delaystep -> %9i\n", nsteppos0);
    }
    if( logfile ){
      fprintf(logfile, " * alpha0 -> %6g\n", alpha_init);
      fprintf(logfile, " * dt0 -> %6g\n", dt_init);
      fprintf(logfile, " * dtmin -> %4g\n", dtmin);
      fprintf(logfile, " * dtmax -> %4g\n", dtmax);
      fprintf(logfile, " * ftm2v -> %6g\n", force->ftm2v);
      fprintf(logfile, " * dmax -> %4g\n", dmax);
      fprintf(logfile, " * delaystep -> %9i\n", nsteppos0);
    }
  }

  // ...Copy the order of atom
  int nat = atom->natoms;
  natoms = nat; // Save for the rescale step
  int nlocal = atom->nlocal;
  oldnloc = nlocal;

  tagint *itag = atom->tag;
  memory->create(order, nlocal, "Fix/artn::order");
  for (int i(0); i < nlocal; i++)
    order[i] = itag[i];

  // ...Allocate the previous force table :: IS LOCAL
  memory->create(f_prev, nlocal, 3, "fix/artn:f_prev");
  memory->create(v_prev, nlocal, 3, "fix/artn:v_prev");
  nextblank = 0;

  // ...Define the Element array for each type
  memory->create(elt, nat, "fix/artn:");
  const int *ityp = atom->type;
  for (int i(0); i < nat; i++)
    elt[i] = alphab[ityp[i]];

  // ...Define the constrains on the atomic movement
  memory->create(if_pos, nat, 3, "fix/artn:if_pos");
  // memset( if_pos, 1, 3*nat );
  for (int i(0); i < nat; i++)
  {
    if_pos[i][0] = 1;
    if_pos[i][1] = 1;
    if_pos[i][2] = 1;
  }

  // ...Parallelization
  memory->create(nloc, nproc, "fix/artn:nloc");
  memory->create(nlresize, nproc, "fix/artn:nlresize");
  memory->create(ftot, nat, 3, "fix/artn:ftot");
  memory->create(xtot, nat, 3, "fix/artn:xtot");
  memory->create(vtot, nat, 3, "fix/artn:xtot");
  memory->create(order_tot, nat, "fix/artn:order_tot");
}

/* ---------------------------------------------------------------------- */

/**
 * @brief Apply the ARTn algorithm
 */
void FixARTn::min_post_force(int /*vflag*/)
{

  /*******************************
   *   Call pARTn library...
   *******************************/

  // ...Link the minimizer
  class Min *minimize = update->minimize;
  if (!minimize)
    error->all(FLERR, "fix/ARTn::Min_vector is not linked");

  // ...We Change the convergence criterium to control it
  update->etol = 0.0;
  update->ftol = 0.0;

  // ...Basic Array to work
  double **tau = atom->x;
  double **f = atom->f;
  double **vel = atom->v;
  const int *ityp = atom->type;

  // ...Update and share the local system size
  int nlocal = atom->nlocal;
  if( MPI_Allgather(&nlocal, 1, MPI_INT, nloc, 1, MPI_INT, world)){
    err_write(__FILE__,__LINE__);
  }
  int ntot(0), lresize(0);
  for (int ipc(0); ipc < nproc; ipc++)
    ntot += nloc[ipc];

  // ------------------------------------------------------------------- RESIZE SYSTEM SIZE

  // ...Resize total system:
  //    The Total Number of Atom Change
  resize_total_system(ntot);
  int nat = natoms;

  // ...Resize local system
  //    The atoms distribution between proc changes
  resize_local_system(nlocal);

  // ...Comput V.F to know in which part of alogrithm energy_force() is called
  double vdotf = 0.0, vdotfall;
  for (int i = 0; i < nlocal; i++)
    vdotf += vel[i][0] * f[i][0] + vel[i][1] * f[i][1] + vel[i][2] * f[i][2];
  if( MPI_Allreduce(&vdotf, &vdotfall, 1, MPI_DOUBLE, MPI_SUM, world) ){
    err_write(__FILE__,__LINE__);
  }

  // ---------------------------------------------------------------------
  // ...If v.f is 0 or under min_fire call the force to ajust
  // the integrator step parameter dtv
  if (!(vdotfall > 0) && update->ntimestep > 1 && nextblank)
  {

    // ...Rescale the force if the dt has been change
    double rscl = dt_curr / update->dt;

    // ...Reload the previous ARTn-force
    for (int i(0); i < nlocal; i++)
    {
      f[i][0] = f_prev[i][0] * rscl * rscl;
      f[i][1] = f_prev[i][1] * rscl * rscl;
      f[i][2] = f_prev[i][2] * rscl * rscl;
    }

    // ...Next call should be after the integration
    nextblank = 0;
    return;

  } // ---------------------------------------------------------------------------------------- RETURN

  if (atom->nmax > nmax)
  {
    memory->destroy(tab_comm);
    nmax = atom->nmax;
    memory->create(tab_comm, nmax, "pair:tab_comm");
  }

  /*****************************************
   *  Now we enter in the ARTn Algorithm
   *****************************************/

  // ...Extract the energy in Ry for ARTn
  double etot = pe_compute->compute_scalar();

  /* ...Convergence and displacement */
  bool lconv;
  int disp_code;

  // ...Build it with : domain-> boxlo[3], boxhi[3] and xy, xz, yz
  double lat[3][3];
  double dx = domain->boxhi[0] - domain->boxlo[0],
         dy = domain->boxhi[1] - domain->boxlo[1],
         dz = domain->boxhi[2] - domain->boxlo[2];

  // lat[0][0] = dx;
  // lat[0][1] = domain->xy;
  // lat[0][2] = domain->xz;
  // lat[1][0] = 0.0;
  // lat[1][1] = dy;
  // lat[1][2] = domain->yz;
  // lat[2][0] = 0.0;
  // lat[2][1] = 0.0;
  // lat[2][2] = dz;

  // lat needs to be transpose for fortran
  lat[0][0] = dx;
  lat[1][0] = domain->xy;
  lat[2][0] = domain->xz;
  lat[0][1] = 0.0;
  lat[1][1] = dy;
  lat[2][1] = domain->yz;
  lat[0][2] = 0.0;
  lat[1][2] = 0.0;
  lat[2][2] = dz;

  // ...Collect the position and force
  int *typ_tot;
  memory->create(typ_tot, natoms, "fix/artn:typ_tot");
  Collect_Arrays(nloc, tau, vel, f, nat, xtot, vtot, ftot, order_tot, typ_tot);

  bool clerr;
  // ...ARTn
  lconv = false;
  double **disp_vec;
  if (!me)
    {
      memory->create(disp_vec, natoms, 3, "fix/artn:disp_vec");

      // attempt permuting
      unpermute_int1d( nat, typ_tot, order_tot );
      unpermute_real2d( nat, &ftot[0][0], order_tot );
      unpermute_real2d( nat, &xtot[0][0], order_tot );

      // pass new order as 1,2,3,..
      int new_ordr[nat];
      for( int i=0; i< nat; i++ ){
        new_ordr[i] = i+1;
      }

      // call setup (will skip if not first istep)
      setup_artn( nat, &clerr );
      if( clerr ){
        artn_merr(__FILE__,__LINE__);
        // should probably exit the if(!me), bcast the clerr, and send error from all ranks.
        // currently, artn_merr kills the application from single node (causes improper exit on mpi)
        error->all(FLERR, "error in setup_artn");
      }

      artn( nat,
            &etot,
            &ftot[0][0],
            typ_tot,
            &xtot[0][0],
            // order_tot,
            new_ordr,
            &lat[0][0],
            &if_pos[0][0],
            &disp_code,
            &disp_vec[0][0],
            &lconv);

      // ...Convert the movement to the force
      move_mode( nat,
                 // order_tot,
                 new_ordr,
                 &ftot[0][0],
                 &vtot[0][0],
                 &etot,
                 &nsteppos,
                 &dt_curr,
                 &alpha,
                 &alpha_init,
                 &dt_init,
                 &disp_code,
                 &disp_vec[0][0] );
      memory->destroy(disp_vec);

      // permute back
      permute_int1d( nat, typ_tot, order_tot );
      permute_real2d( nat, &ftot[0][0], order_tot );
      permute_real2d( nat, &xtot[0][0], order_tot );

      // ...Comparison of push_step_size with dmax to don't be crazy
      if( !check_dmax_flag )Check_min_params( "dmax" );

    }
  memory->destroy(typ_tot);




  // ...Spread the ARTn_Step (DISP_CODE) & Convergence
  int iconv = int(lconv);
  if(MPI_Bcast(&iconv, 1, MPI_INT, 0, world)){
    err_write(__FILE__,__LINE__);
  }
  if(MPI_Bcast(&disp_code, 1, MPI_INT, 0, world)){
    err_write(__FILE__,__LINE__);
  }

  // ...Spread the new arrays
  Spread_Arrays(nloc, xtot, vtot, ftot, nat, tau, vel, f);
  // printf("before spread\n");
  // spread_name( "x", 1, 3, xtot );
  // spread_name( "v", 1, 3, vtot );
  // spread_name( "f", 1, 3, ftot );
  // printf("after spread\n");


  // ...Spread the FIRE parameters
  if( MPI_Bcast( &dt_curr,  1, MPI_DOUBLE, 0, world)){
    err_write(__FILE__,__LINE__);
  }
  if( MPI_Bcast( &alpha,    1, MPI_DOUBLE, 0, world)){
    err_write(__FILE__,__LINE__);
  }
  //if( MPI_Bcast( &nsteppos, 1, MPI_DOUBLE, 0, world)){
  if( MPI_Bcast( &nsteppos, 1, MPI_INT, 0, world)){
    err_write(__FILE__,__LINE__);
  }

  // ...Convert to the LAMMPS units
  if (!(disp_code == PERP || disp_code == RELX ) )
  {

    double *rmass = atom->rmass;
    double *mass = atom->mass;

    // Comvert the force Ry to LAMMPS units
    if (rmass)
    {
      for (int i(0); i < nloc[me]; i++)
      {
        f[i][0] *= rmass[i];
        f[i][1] *= rmass[i];
        f[i][2] *= rmass[i];
      }
    }
    else
    {
      for (int i(0); i < nloc[me]; i++)
      {
        f[i][0] *= mass[ityp[i]];
        f[i][1] *= mass[ityp[i]];
        f[i][2] *= mass[ityp[i]];
      }
    }
  }

  // // ---------------------------------------------------------------------- COMVERGENCE
  // if (iconv)
  //   {
  //     // ...Reset the energy force tolerence
  //     update->etol = 10.; // etol;
  //     update->ftol = 10.; // ftol;

  //     // ...Spread the force
  //     // Spread_Arrays(nloc, xtot, vtot, ftot, nat, tau, vel, f);

  //     MPI_Barrier(world);
  //     if (comm->me == 0)
  //       {
  //         if (screen)
  //           fprintf(screen, "     *************************lmp* ARTn CONVERGED\n");
  //         if (logfile)
  //           fprintf(logfile, "     *************************lmp* ARTn CONVERGED\n");
  //       }
  //     return;
  //   } // --------------------------------------------------------------------------------



  // ...Update the time
  // update->dt = dt_curr;
  string str;

  // ...Allocate/Deallocate word
  nword = 6;
  if (word)
    memory->destroy(word);
  memory->create(word, nword, 20, "fix:word");

  strcpy(word[0], "alpha0");
  str = to_string(alpha);
  strcpy(word[1], str.c_str());

  strcpy(word[2], "delaystep");
  if( nsteppos != 0 ) nsteppos = nsteppos0;
  str = to_string(nsteppos);
  strcpy(word[3], str.c_str());

  // ...RELAX step -> halfstepback = yes
  if (disp_code == RELX || disp_code == PERP ) {

    strcpy(word[4], "halfstepback");
    strcpy(word[5], "yes");

  } else {
    strcpy(word[4], "halfstepback");
    strcpy(word[5], "no");
  }

  // ...Launch modification of FIRE parameter
  void *cval;
  int iperp;
  int irelax;
  // obtain iperp and irelax from node=0
  if(!me)
    {
      if( get_runparam("iperp", &cval) ){
        err_write(__FILE__,__LINE__);
      }
      iperp = *(int *)cval;

      if( get_runparam("irelax", &cval) ){
        err_write(__FILE__,__LINE__);
      }
      irelax = *(int *)cval;
    }
  // bcast the values to all nodes
  if(MPI_Bcast(&iperp, 1, MPI_INT, 0, world)){
    err_write(__FILE__,__LINE__);
  }
  if(MPI_Bcast(&irelax, 1, MPI_INT, 0, world)){
    err_write(__FILE__,__LINE__);
  }


  // printf("me, iperp %d %d \n", comm->me, iperp);
  // printf("me, irelax %d %d \n", comm->me, irelax);
  if ((disp_code == PERP && iperp == 1) ||
      (disp_code != PERP && disp_code != RELX ) ||
      (disp_code == RELX && irelax == 1))
  {

    // ...Update the time
    update->dt = dt_curr;

    // ...Send the new parameter to minmize
    //printf("[%d] Communicate the new FIRE parameter to FIRE\n", universe->me);
    minimize->modify_params(nword, word);
    minimize->init();
  }

  // ...Compute V.F: Allow to know if the next call come from the vdotf < 0 condition
  // or as normally after the integration step
  vdotf = 0.0;
  for (int i(0); i < nloc[me]; i++)
    vdotf += vel[i][0] * f[i][0] + vel[i][1] * f[i][1] + vel[i][2] * f[i][2];
  if( MPI_Allreduce(&vdotf, &vdotfall, 1, MPI_DOUBLE, MPI_SUM, world)){
    err_write(__FILE__,__LINE__);
  }

  if (!(vdotfall > 0))
    nextblank = 1;
  if (istep == 0)
    nextblank = 0;

  // ...Store the actual force/velocity
  for (int i(0); i < nloc[me]; i++)
  {
    f_prev[i][0] = f[i][0];
    f_prev[i][1] = f[i][1];
    f_prev[i][2] = f[i][2];
  }

  if( iconv){
    // reset tolerance
    update->etol = 10.; // etol;
    update->ftol = 10.; // ftol;
  }
  // ...Increment & return
  istep++;
  return;
}

/* ---------------------------------------------------------------------- */
void FixARTn::Check_min_params( const char* param ){

  class Min *minimize = update->minimize;

  if( strcmp( param, "dmax") == 0 ){

    // .. For param="dmax":: if `dmax` of lammps is lower than `push_step_size` of pARTn,
    // .. then set `dmax` of lammps to equal `push_step_size`

    // ..Extract `push_step_size` from ARTn
    void *cval;
    if( get_param("push_step_size", &cval) )
       err_write(__FILE__, __LINE__);
    double push_step_size = *((double *)cval);

    // ... if dmax is larger than push_step_size can return
    check_dmax_flag = 1;
    if( dmax >= push_step_size )
      return;

    // ...Change dmax to push_step_size
    if (logfile)
      fprintf(logfile, "\t::fix_artn>> WARNING: dmax of FIRE (%lf) < push_step_size of ARTn (%lf)\n", dmax,push_step_size);
    if (screen)
      fprintf(screen, "\t::fix_artn>> WARNING: dmax of FIRE (%lf) < push_step_size of ARTn (%lf)\n", dmax,push_step_size);

    dmax = push_step_size;

    if(logfile)
      fprintf(logfile,"\t::fix_artn>> setting dmax = push_step_size = %lf\n",dmax );
    if(screen)
      fprintf(screen,"\t::fix_artn>> setting dmax = push_step_size = %lf\n",dmax );

    nword = 2;
    if( word )memory->destroy(word);
    memory->create(word, nword, 20, "fix:word");
    strcpy(word[0], "dmax");
    string str = to_string(dmax);
    strcpy(word[1], str.c_str());
    minimize->modify_params(nword, word);

  }else{
    // unknown "param"
    if(logfile)
      fprintf(logfile, "\t::Fix_artn>>WARNING: Unknown param: %s\n", param);
    if(screen)
      fprintf(screen, "\t::Fix_artn>>WARNING: Unknown param: %s\n", param);
  }
}


/* ---------------------------------------------------------------------- */

/**
 * @brief Finilize ARTn algorithm (clean_artn)
 */
void FixARTn::post_run()
{

  // End of the ARTn research - we reset the ARTn counters & flag
  if (!me){
    clean_artn(); // Only proc 0

    // void *cval;
    // if( get_param("forc_thr", &cval ) ) {
    //   err_write(__FILE__, __LINE__);
    // }
    // double forc_thr = *(double *)cval;
    // printf( "got value: %f\n", forc_thr );
    // free( cval );


    // int *csize;
    // int cerr;
    // int crank;
    // crank = get_artn_drank( "push_add_const" );
    // cerr = get_artn_dsize( "push_add_const", &csize );
    // printf( "crank %d\n", crank );
    // for( int i=0; i<crank;i++){
    //   printf( "csize %d %d\n",i, csize[i]);
    // }

    // // receive 2d array as void *
    // cerr = get_param( "push_add_const", &cval);
    // if( cerr ){
    //   err_write(__FILE__,__LINE__);
    // }
    // // cast void * into 1d double *
    // double * push_add_const = (double *)cval;

    // // reshape double* into double**, NOTE the transpose of size
    // double** pp;
    // memory->create(pp, csize[1], csize[0], "pp");
    // int n = 0;
    // for ( int i=0; i<csize[1]; i++ ){
    //   pp[i] = &push_add_const[n];
    //   n+=csize[0];
    // }

    // // printf("%lf\n", pp[0][0]);
    // // for( int i=0; i<csize[1]; i++){
    // //   for( int j=0; j<csize[0];j++){
    // //     printf( "%lf ", pp[i][j] );
    // //   }
    // //   printf("\n");
    // // }
    // free(cval);


    // // get str param
    // if( get_param("engine_units", &cval)){
    //   err_write(__FILE__,__LINE__);
    // }
    // char* eng_units;
    // eng_units = (char *)cval;
    // printf("units string: %s\n", eng_units );


    // cerr = get_param("prefix_min", &cval);
    // char *pm = (char *)cval;
    // printf( "prefix_min: %s\n", pm );


    // // get bool param
    // if( get_param("lpush_final", &cval)){
    //   err_write(__FILE__,__LINE__);
    // }
    // bool lpush_final = *(bool *)cval;
    // printf("bool: %d\n", lpush_final);




    // // call directly get_param_str, returns directly the value wanted
    // printf( "%s\n", get_param_str("engine_units", &cerr));



    // // get 1d int array
    // int psize;
    // int * pl = get_param_int1d("nperp_limitation", &psize, &cerr);
    // for( int i=0; i< psize; i++){
    //   printf( "%d ", pl[i] );
    // }
    // printf("\n");

    // // get 2d real as 1d array
    // int dim1, dim2;
    // double * r2 = get_param_real2d( "push_add_const", &dim1, &dim2, &cerr );
    // printf( "%d %d\n", dim1, dim2);



    // // set param int
    // double hj = 0.3;
    // int csz[1]={3};
    // set_param( "forc_thr", 0, &csz[0], &hj );
  }

  // double *xtest = nullptr;
  // memory->create(xtest, 3*343, "fix::xtest");
  // collect_name( (char *)"x", 1, 3, xtest );
  // if( !me){
  // for( int i=0; i < 343; i++ ){
  //   printf( "%f\n", xtest[i]);
  // }
  // }



}

/* ============================================================================ COMMUNICATION */

/**
 * @authors
 *   Matic Poberznic
 *   Miha Gunde
 *   Nicolas Salles
 *
 * @brief Collect distributed arrays
 *
 * @par Purpose
 * ============
 * Collect the distributed array, position, velicity, and force, trough the N processor.
 * Return uniq array for each quantities in order as it received
 *
 * @param[in]    nloc        number of element of the arrays is on the processor
 * @param[in]    x           2D array of Position
 * @param[in]    v           2D array of Velocity
 * @param[in]    f           2D array of Force
 * @param[in]    nat         Number total of element of arrays
 * @param[out]   xtot        2D array contains the distributed Position over the N procs
 * @param[out]   vtot        2D array contains the distributed Velocity over the N procs
 * @param[out]   ftot        2D array contains the distributed Forces over the N procs
 * @param[in]    order_tot   1D array contains the order of atoms over the N procs following the rank od the procs
 * @param[in]    typ_tot     1D array contains the type of each atoms
 *
 */
void FixARTn::Collect_Arrays(int *nloc, double **x, double **v, double **f, int nat, double **xtot, double **vtot, double **ftot, int *order_tot, int *typ_tot)
{

  // ...Alloc temporary memory
  memory->create(istart, nproc, "fix/artn:istart");
  memory->create(length, nproc, "fix/artn:length");

  // ...Starting point:
  for (int ipc(0); ipc < nproc; ipc++)
    istart[ipc] = (ipc > 0) ? istart[ipc - 1] + 3 * nloc[ipc - 1] : 0;

  // ...Length of receiv buffer
  for (int ipc(0); ipc < nproc; ipc++)
    length[ipc] = 3 * nloc[ipc];

  // ...Gatherv ftot, vtot, xtot
  if( MPI_Gatherv(&f[0][0], 3 * nloc[me], MPI_DOUBLE,
                   &ftot[0][0], length, istart, MPI_DOUBLE, 0, world) ) {
      err_write(__FILE__,__LINE__);
    }

  if( MPI_Gatherv(&v[0][0], 3 * nloc[me], MPI_DOUBLE,
                   &vtot[0][0], length, istart, MPI_DOUBLE, 0, world) ){
    err_write(__FILE__,__LINE__);
  }

  if( MPI_Gatherv(&x[0][0], 3 * nloc[me], MPI_DOUBLE,
                   &xtot[0][0], length, istart, MPI_DOUBLE, 0, world) ){
    err_write(__FILE__,__LINE__);
  }

  // ...Starting point:
  for (int ipc(0); ipc < nproc; ipc++)
    istart[ipc] = (ipc > 0) ? istart[ipc - 1] + nloc[ipc - 1] : 0;

  // ...Gatherv order
  if( MPI_Gatherv(order, nloc[me], MPI_INT,
                   order_tot, nloc, istart, MPI_INT, 0, world) ){
    err_write(__FILE__,__LINE__);
  }

  // ...Gatherv ityp
  int *ityp = atom->type;
  if( MPI_Gatherv(ityp, nloc[me], MPI_INT,
                   typ_tot, nloc, istart, MPI_INT, 0, world) ){
    err_write(__FILE__,__LINE__);
  }


  // void *data;
  // collect_name( "x", 1, 3, data );
  // xtot = (double *) data;

  memory->destroy(istart);
  memory->destroy(length);
}

// equivalent to lammps_gather_atoms from library.cpp
void FixARTn::collect_name( const char *name, int type, int count, void* data)
{
    int i,j,offset;

    printf("enter collect_name with type name %d\n", type);
    printf( "name: %s\n",name);
    // error if tags are not defined or not consecutive
    // NOTE: test that name = image or ids is not a 64-bit int in code?

    int flag = 0;
    if (atom->tag_enable == 0 || atom->tag_consecutive() == 0)
      flag = 1;
    if (atom->natoms > MAXSMALLINT) flag = 1;
    if (flag) {
      if (comm->me == 0)
        error->warning(FLERR,"Library error in lammps_gather_atoms");
      return;
    }

    int natoms = static_cast<int> (atom->natoms);

    void *vptr = atom->extract(name);
    if (vptr == nullptr) {
      if (comm->me == 0)
        error->warning(FLERR,"lammps_gather_atoms: unknown property name");
      return;
    }

    // copy = Natom length vector of per-atom values
    // use atom ID to insert each atom's values into copy
    // MPI_Allreduce with MPI_SUM to merge into data, ordered by atom ID

    if (type == 0) {
      int *vector = nullptr;
      int **array = nullptr;
      const int imgunpack = (count == 3) && (strcmp(name,"image") == 0);

      if ((count == 1) || imgunpack) vector = (int *) vptr;
      else array = (int **) vptr;

      int *copy;
      memory->create(copy,count*natoms,"lib/gather:copy");
      for (i = 0; i < count*natoms; i++) copy[i] = 0;

      tagint *tag = atom->tag;
      int nlocal = atom->nlocal;

      if (count == 1) {
        for (i = 0; i < nlocal; i++)
          copy[tag[i]-1] = vector[i];

      } else if (imgunpack) {
        for (i = 0; i < nlocal; i++) {
          offset = count*(tag[i]-1);
          const int image = vector[i];
          copy[offset++] = (image & IMGMASK) - IMGMAX;
          copy[offset++] = ((image >> IMGBITS) & IMGMASK) - IMGMAX;
          copy[offset++] = ((image >> IMG2BITS) & IMGMASK) - IMGMAX;
        }

      } else {
        for (i = 0; i < nlocal; i++) {
          offset = count*(tag[i]-1);
          for (j = 0; j < count; j++)
            copy[offset++] = array[i][j];
        }
      }

      MPI_Allreduce(copy,data,count*natoms,MPI_INT,MPI_SUM,world);
      memory->destroy(copy);

    } else if (type == 1) {
      double *vector = nullptr;
      double **array = nullptr;
      if (count == 1) vector = (double *) vptr;
      else array = (double **) vptr;

      double *copy;
      memory->create(copy,count*natoms,"lib/gather:copy");
      for (i = 0; i < count*natoms; i++) copy[i] = 0.0;

      tagint *tag = atom->tag;
      int nlocal = atom->nlocal;

      if (count == 1) {
        for (i = 0; i < nlocal; i++)
          copy[tag[i]-1] = vector[i];

      } else {
        for (i = 0; i < nlocal; i++) {
          offset = count*(tag[i]-1);
          for (j = 0; j < count; j++)
            copy[offset++] = array[i][j];
        }
      }

      printf("b4 allred\n");
      MPI_Allreduce(copy,data,count*natoms,MPI_DOUBLE,MPI_SUM,world);
      printf("after allred\n");
      memory->destroy(copy);
    } else {
      if (comm->me == 0)
        error->warning(FLERR,"lammps_gather_atoms: unsupported data type");
      return;
    }

}

// equivalent to lammps_scatter_atoms
// type=0 for int, type=1 for double
// count=1 for (1:nat) array, count=3 for (1:3,1:nat) array
void FixARTn::spread_name(const char *name, int type, int count, void* data )
{
      int i,j,m,offset;

    // error if tags are not defined or not consecutive or no atom map
    // NOTE: test that name = image or ids is not a 64-bit int in code?

    int flag = 0;
    if (atom->tag_enable == 0 || atom->tag_consecutive() == 0)
      flag = 1;
    printf("flag 1: %d\n",flag);
    if (atom->natoms > MAXSMALLINT) flag = 1;
    printf("flag 2: %d\n",flag);
    if (atom->map_style == Atom::MAP_NONE) flag = 1;
    printf("flag 3: %d\n",flag);
    if (flag) {
      if (comm->me == 0)
        error->warning(FLERR,"Library error in lammps_scatter_atoms: ids must exist, be consecutive, and be mapped");
      return;
    }

    int natoms = static_cast<int> (atom->natoms);

    void *vptr = atom->extract(name);
    if (vptr == nullptr) {
      if (comm->me == 0)
        error->warning(FLERR,
                            "lammps_scatter_atoms: unknown property name");
      return;
    }

    // copy = Natom length vector of per-atom values
    // use atom ID to insert each atom's values into copy
    // MPI_Allreduce with MPI_SUM to merge into data, ordered by atom ID

    if (type == 0) {
      int *vector = nullptr;
      int **array = nullptr;
      const int imgpack = (count == 3) && (strcmp(name,"image") == 0);

      if ((count == 1) || imgpack) vector = (int *) vptr;
      else array = (int **) vptr;
      int *dptr = (int *) data;

      if (count == 1) {
        for (i = 0; i < natoms; i++)
          if ((m = atom->map(i+1)) >= 0)
            vector[m] = dptr[i];

      } else if (imgpack) {
        for (i = 0; i < natoms; i++)
          if ((m = atom->map(i+1)) >= 0) {
            offset = count*i;
            int image = dptr[offset++] + IMGMAX;
            image += (dptr[offset++] + IMGMAX) << IMGBITS;
            image += (dptr[offset++] + IMGMAX) << IMG2BITS;
            vector[m] = image;
          }

      } else {
        for (i = 0; i < natoms; i++)
          if ((m = atom->map(i+1)) >= 0) {
            offset = count*i;
            for (j = 0; j < count; j++)
              array[m][j] = dptr[offset++];
          }
      }

    } else {
      double *vector = nullptr;
      double **array = nullptr;
      if (count == 1) vector = (double *) vptr;
      else array = (double **) vptr;
      auto dptr = (double *) data;

      if (count == 1) {
        for (i = 0; i < natoms; i++)
          if ((m = atom->map(i+1)) >= 0)
            vector[m] = dptr[i];

      } else {
        for (i = 0; i < natoms; i++) {
          if ((m = atom->map(i+1)) >= 0) {
            offset = count*i;
            for (j = 0; j < count; j++)
              array[m][j] = dptr[offset++];
          }
        }
      }
    }

}

/* --------------------------------------------------------------------------------------------------------------------------------- */

/**
 * @authors
 *   Matic Poberznic
 *   Miha Gunde
 *   Nicolas Salles
 *
 * @brief Spread distributed arrays
 *
 * @par Purpose
 * ============
 * Redistribut/Spread the distributed array, position, velicity, and force, trough the N processor.
 *
 * @param[in]   nloc        INT, number of element of the arrays is on the processor
 * @param[in]   xtot        DOUBLE, 2D array contains the distributed Position over the N procs
 * @param[in]   vtot        DOUBLE, 2D array contains the distributed Velocity over the N procs
 * @param[in]   ftot        DOUBLE 2D array contains the distributed Forces over the N procs
 * @param[in]   nat         INT, Number total of element of arrays
 * @param[out]  x           DOUBLE, 2D array of Position
 * @param[out]  v           DOUBLE, 2D array of Velocity
 * @param[out]  f           DOUBLE, 2D array of Force
 *
 */
void FixARTn::Spread_Arrays(int *nloc, double **xtot, double **vtot, double **ftot, int nat, double **x, double **v, double **f)
{

  // ...Alloc temporary memory
  memory->create(istart, nproc, "fix/artn:istart");
  memory->create(length, nproc, "fix/artn:length");

  // ...Starting point:
  for (int ipc(0); ipc < nproc; ipc++)
    istart[ipc] = (ipc > 0) ? istart[ipc - 1] + 3 * nloc[ipc - 1] : 0;

  // ...Length of receiv buffer
  for (int ipc(0); ipc < nproc; ipc++)
    length[ipc] = 3 * nloc[ipc];

  // ...Scatter ftot, vtot, xtot
  if( MPI_Scatterv(&ftot[0][0], length, istart, MPI_DOUBLE,
                    &f[0][0], 3 * nloc[me], MPI_DOUBLE, 0, world) ){
    err_write(__FILE__,__LINE__);
  }

  if( MPI_Scatterv(&vtot[0][0], length, istart, MPI_DOUBLE,
                    &v[0][0], 3 * nloc[me], MPI_DOUBLE, 0, world) ){
    err_write(__FILE__,__LINE__);
  }

  if( MPI_Scatterv(&xtot[0][0], length, istart, MPI_DOUBLE,
                    &x[0][0], 3 * nloc[me], MPI_DOUBLE, 0, world) ){
    err_write(__FILE__,__LINE__);
  }

  memory->destroy(istart);
  memory->destroy(length);
}

// ------------------------------------------------------------------- RESIZE total SYSTEM SIZE

/**
 * @authors
 *   Matic Poberznic
 *   Miha Gunde
 *   Nicolas Salles
 *
 * @brief Resize the global arrays
 *
 * @par Purpose
 * ============
 * Resize the 2D array containing the entire data of Position, Velocity and Forces
 *
 * @param[in]   ntot        INT, Total number of atoms in the system
 *
 */
void FixARTn::resize_total_system(int ntot)
{

  // ...Resize total system:
  //    The Total Number of Atom Change

  int lresize(0);
  if (natoms != ntot)
    lresize = 1;
  if (lresize)
  { // Resize
    // Deallocate arrays
    memory->destroy(ftot);
    memory->destroy(xtot);
    memory->destroy(vtot);
    memory->destroy(order_tot);
    natoms = atom->natoms;
    // Reallocate arrays
    memory->create(ftot, natoms, 3, "fix/artn:ftot");
    memory->create(xtot, natoms, 3, "fix/artn:xtot");
    memory->create(vtot, natoms, 3, "fix/artn:vtot");
    memory->create(order_tot, natoms, "fix/artn:order_tot");
  }
}

// ------------------------------------------------------------------- RESIZE local SYSTEM SIZE

/**
 * @authors
 *   Matic Poberznic
 *   Miha Gunde
 *   Nicolas Salles
 *
 * @brief Resize the local arrays
 *
 * @par Purpose
 * ============
 * Verify, resize and redistribut the data Position, Velocity and Forces through the N procs
 *
 * @param[in]   nlocal        INT, number of atoms on the proc
 *
 */
void FixARTn::resize_local_system(int nlocal /*new nloc */)
{

  // verification of local size
  // LRESIZE = logical(int) if number of local atom has been changed
  // -> Allgather it
  // -> sum them in ntot
  // -> if ntot > 0 => resize
  int lresize = (nloc[me] != oldnloc);

  // printf("enter resize_local, lresize: %d\n", lresize);

  for (int ipc(0); ipc < nproc; ipc++)
    nlresize[me] = 0;
  MPI_Allgather(&lresize, 1, MPI_INT, nlresize, 1, MPI_INT, world);
  int ntot(0);
  for (int ipc(0); ipc < nproc; ipc++)
    ntot += nlresize[ipc];

  int lresize_sum(0);
  MPI_Allreduce(&lresize, &lresize_sum, 1, MPI_INT, MPI_SUM, world);
  if (ntot != lresize_sum)
    printf("[%d] ntot %d | lresize_sum %d | %d \n ", me, ntot, lresize_sum, (ntot == lresize_sum));

  // ...One of the local size change
  if (lresize_sum > 0)
  {

    // ...Array of old local size
    int *oldloc;
    memory->create(oldloc, nproc, "fix/artn:oldloc");
    if( MPI_Allgather(&oldnloc, 1, MPI_INT, oldloc, 1, MPI_INT, world)){
      err_write(__FILE__,__LINE__);
    }

    // ...Create temporary Arrays
    int *inew;
    memory->create(inew, natoms, "fix/artn:inew");
    memory->create(istart, natoms, "fix/artn:istart");
    memory->create(length, natoms, "fix/artn:length");

    // ---------------------------------- Use AllGatherv for f_prev to ftot
    //                                                       v_prev to vtot
    // ...Starting point of 3N array:
    for (int ipc(0); ipc < nproc; ipc++)
      istart[ipc] = (ipc > 0) ? istart[ipc - 1] + 3 * oldloc[ipc - 1] : 0;

    // ...Length of receiv buffer
    for (int ipc(0); ipc < nproc; ipc++)
      length[ipc] = 3 * oldloc[ipc];

    if( MPI_Gatherv(&f_prev[0][0], 3 * oldnloc, MPI_DOUBLE,
                     &ftot[0][0], length, istart, MPI_DOUBLE, 0, world) ){
      err_write(__FILE__,__LINE__);
    }

    if( MPI_Gatherv(&v_prev[0][0], 3 * oldnloc, MPI_DOUBLE,
                     &vtot[0][0], length, istart, MPI_DOUBLE, 0, world)){
      err_write(__FILE__,__LINE__);
    }

    // --------------------------------- Use AllGatherv for order to order_tot
    // ...Starting point of old N array:
    for (int ipc(0); ipc < nproc; ipc++)
      istart[ipc] = (ipc > 0) ? istart[ipc - 1] + oldloc[ipc - 1] : 0;

    if( MPI_Gatherv(order, oldnloc, MPI_INT,
                     order_tot, oldloc, istart, MPI_INT, 0, world)){
      err_write(__FILE__,__LINE__);
    }

    // ...Resize order
    tagint *itag = atom->tag;
    memory->destroy(order);
    memory->create(order, nlocal, "fix/artn:order");

    // ...Fill new order
    for (int i(0); i < nlocal; i++)
      order[i] = itag[i];

    // --------------------------------- Use AllGatherv for order to inew
    // ...Starting point of new N array:
    for (int ipc(0); ipc < nproc; ipc++)
      istart[ipc] = (ipc > 0) ? istart[ipc - 1] + nloc[ipc - 1] : 0;

    if( MPI_Gatherv(order, nlocal, MPI_INT,
                     inew, nloc, istart, MPI_INT, 0, world)){
      err_write(__FILE__,__LINE__);
    }

    // ...Change the order of force
    if (!me)
    {
      if (!xtot)
        printf(" ERROR - *XTOT => NULL \n");
      if (!ftot)
        printf(" ERROR - *FTOT => NULL \n");
      for (int i(0); i < natoms; i++)
      {

        int j;
        for (j = 0; j < natoms; j++)
          if (order_tot[j] == inew[i])
          {
            xtot[i][0] = ftot[j][0];
            xtot[i][1] = ftot[j][1];
            xtot[i][2] = ftot[j][2];
            break;
          }
      }
    } // ::: ME = 0

    // ...Resize f_prev
    memory->destroy(f_prev);
    memory->create(f_prev, nlocal, 3, "fix/artn:f_prev");

    // ...Starting point:
    for (int ipc(0); ipc < nproc; ipc++)
      istart[ipc] = (ipc > 0) ? istart[ipc - 1] + 3 * nloc[ipc - 1] : 0;

    // ...Length of receiv buffer
    for (int ipc(0); ipc < nproc; ipc++)
      length[ipc] = 3 * nloc[ipc];

    if( MPI_Scatterv(&xtot[0][0], length, istart, MPI_DOUBLE,
                      &f_prev[0][0], 3 * nlocal, MPI_DOUBLE, 0, world)){
      err_write(__FILE__,__LINE__);
    }

    // ...Save the new value
    oldnloc = nloc[me];

    // ...Destroy temporary arrays
    memory->destroy(oldloc);
    memory->destroy(inew);
    memory->destroy(length);
    memory->destroy(istart);

  } // -------------------------------------------------------------------------- END RESIZE SYSTEM
}
