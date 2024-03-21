
#ifndef ARTN_H
#define ARTN_H

/*!
  @file artn.h
  @brief Routines from the library pARTn
*/

extern "C"
{
  void artn(const double *f,
            const double *etot,
            const int nat,
            int const *ityp,
            double *const tau,
            const int *order,
            const double *lat,
            const int *if_pos,
            int *disp,
            double *disp_vec,
            bool *lconv);

  void move_mode(const int nat,
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

  void clean_artn();

  int get_iperp_();
  int get_perp_();
  int get_relx_();
  int get_irelx_();

  int set_param_int ( const char *name, const int    cval );
  int set_param_real( const char *name, const double cval );
  int set_param_bool( const char *name, const bool   cval );
  int set_param_str ( const char *name, const char  *cval );

  int    get_param_int ( const char *name, int* cerr );
  double get_param_real( const char *name, int* cerr );
  bool   get_param_bool( const char *name, int* cerr );
  char*  get_param_str ( const char *name, int* cerr );

  int get_param ( const char *name, void* cval );

  void err_write( const char *file, const int line );

  int get_param_dtype( const char *name );

  int get_param_dsize( const char *name, int *c );
}

#endif
