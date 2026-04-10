
#ifndef ARTN_H
#define ARTN_H

/*!
  @file artn.h
  @brief Routines from the library pARTn
*/

extern "C"
{

  //defined in: src/h_artn_info.f90
  void artn_version_semantic( int* major, int* minor, int* patch );
  void artn_gitinfo( char** cstr );

  // defined in: src/artn_api.f90
  int artn_create();
  void artn_destroy();
  void artn_merr( const char *file, const int line );

  // defined in: src/m_artn_error.f90
  void err_write( const char *file, const int line );
  int get_error( char ** cerrmsg ); // NOTE: the returned string is a c_loc(), so might not be ok to free();
  void reset_error();

  // defined in: src/m_setup_artn.f90
  void print_caller();

  // defined in: src/artn_c_wrappers.f90
  void setup_artn( const int nat,
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

  int artn_get_dtype( const char *name );
  int artn_get_dtype_val( const char *name );
  char* artn_get_dtype_str( int val );
  int artn_get_drank( const char *name );
  int artn_get_dsize( const char *name, int **csize );
  int get_param ( const char *name, void **cval );
  int set_param( const char * const name, const int crank, const int* csize, const void *cval );
  int get_runparam( const char *name, void **cval );
  int set_runparam( const char * const name, const int crank, const int* csize, const void *cval );
  int get_data( const char *name, void **cval );
  int set_data( const char * const name, const int crank, const int* csize, const void *cval );

  void permute_int1d( const int dim1, int *const array, const int* order );
  void unpermute_int1d( const int dim1, int *const array, const int* order );
  void permute_real2d( const int dim1, double * const array, const int * order );
  void unpermute_real2d( const int dim1, double * const array, const int * order );

  // defined in: src/artn_step.f90
  void artn_step(const int nat,
                 const double etot,
                 double *const force,
                 int const *ityp,
                 double *const pos,
                 const double *box,
                 const int *if_pos,
                 double *displ_vec,
                 bool *lconv);
  void artn_step_reset();


  // defined in: src/m_artn_fire.f90
  int fire_init();
  int fire_dtype( const char *name );
  int fire_get( const char * const name, void **cval );
  int fire_set( const char *name, void *cval );
  void fire_step( const int nat,
                  double *const cforce,
                  int *cnsteppos,
                  double *const vel,
                  double *cdt,
                  double* calpha,
                  double *cdispl_vec );

}

#endif
