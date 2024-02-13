
void *artn_create();
void artn_destroy( void *handle );
int artn_get_datatype( void *handle, void *cname, int *cerr );
int artn_get_datarank( void *handle, void *cname, int *cerr );
void artn_set( void *handle, void *cname, int ctyp, int crank, int** csize, void* cval, int* cerr );
int artn_extract( void *handle, void *cname, int *ctyp, int *crank, int* csize, void *cval );
int artn_dump_input( void *handle, void *filename );
void artn_read_generated( void *handle);
void artn_serialize_input( void *handle);
