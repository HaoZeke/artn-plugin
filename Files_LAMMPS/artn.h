
#ifndef ARTN_H
#define ARTN_H

/*!
  @file artn.h
  @brief Routines from the library pARTn
*/

extern "C"
{

  void setup_artn2( const int nat,
                    bool *cerr);

  void artn(const int nat,
            const double *etot,
            const double *f,
            int const *ityp,
            double *const tau,
            const int *order,
            const double *lat,
            const int *if_pos,
            int *disp_code,
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
                 int *disp_code,
                 double *disp_vec );

  void clean_artn();

  int set_param_int ( const char *name, const int    cval );
  int set_param_real( const char *name, const double cval );
  int set_param_bool( const char *name, const bool   cval );
  int set_param_str ( const char *name, const char  *cval );
  int set_param( const char * const name, const int crank, const int* csize, const void *cval );

  int    get_param_int ( const char *name, int* cerr );
  double get_param_real( const char *name, int* cerr );
  bool   get_param_bool( const char *name, int* cerr );
  char*  get_param_str ( const char *name, int* cerr );
  int* get_param_int1d( const char *name, int* dim, int* cerr );
  double * get_param_real2d( const char *name, int* dim1, int* dim2, int* cerr );


  void err_write( const char *file, const int line );

  int get_artn_dtype( const char *name );
  int get_artn_drank( const char *name );
  int get_artn_dsize( const char *name, int **csize );

  int get_param ( const char *name, void* cval );

  int get_runparam( const char *name, void *cval );

  void print_caller();

  void permute_int1d( const int dim1, int *const array, const int* order );
  void unpermute_int1d( const int dim1, int *const array, const int* order );
  void permute_real2d( const int dim1, double * const array, const int * order );
  void unpermute_real2d( const int dim1, double * const array, const int * order );

}

#endif
