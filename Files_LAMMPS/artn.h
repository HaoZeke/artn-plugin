
#ifndef ARTN_H
#define ARTN_H

/*!
  @file artn.h
  @brief Routines from the library pARTn
*/

extern "C"
{
  void artn_c(const double *f,
              const double *etot,
              const int nat,
              int const *ityp,
              /* const char *elt, */
              double *const tau,
              const int *order,
              const double *lat,
              const int *if_pos,
              int *disp,
              double *disp_vec,
              bool *lconv);

  void move_mode_c(const int nat,
                   const int *order,
                   double *const f,
                   double *const vel,
                   double *etot,
                   int *nsteppos,
                   double *dt_curr,
                   double *alpha,
                   const double *alpha_init,
                   const double *dt_init,
                   int *disp,
                   double *disp_vec );

  void clean_artn_c();

  int get_iperp_();
  int get_perp_();
  int get_relx_();
  int get_irelx_();
}

#endif
