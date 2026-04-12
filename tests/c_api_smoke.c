#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "artn.h"

int main(void) {
  int major = 0;
  int minor = 0;
  int patch = 0;
  char *gitinfo = NULL;
  char *dtype = NULL;
  char *errmsg = (char *)0x1;
  char *fire_infile = NULL;
  char *bad_fire = NULL;
  int err = 0;
  int fire_err = 0;
  const char *fire_name = "fire-test.nml";

  artn_version_semantic(&major, &minor, &patch);
  assert(major >= 0);
  assert(minor >= 0);
  assert(patch >= 0);

  artn_gitinfo(&gitinfo);
  assert(gitinfo != NULL);
  assert(strchr(gitinfo, ':') != NULL);
  free(gitinfo);

  dtype = artn_get_dtype_str(artn_get_dtype_val("ARTN_DTYPE_REAL"));
  assert(dtype != NULL);
  assert(strcmp(dtype, "real") == 0);
  free(dtype);

  reset_error();
  err = get_error(&errmsg);
  assert(err == 0);
  assert(errmsg == NULL);
  free(errmsg);

  fire_err = fire_set("infile", (void *)fire_name);
  assert(fire_err == 0);

  fire_err = fire_get("infile", (void **)&fire_infile);
  assert(fire_err == 0);
  assert(fire_infile != NULL);
  assert(strcmp(fire_infile, fire_name) == 0);
  free(fire_infile);

  fire_err = fire_get("definitely_missing", (void **)&bad_fire);
  assert(fire_err != 0);
  assert(bad_fire == NULL);
  free(bad_fire);
  reset_error();

  puts("c_api_smoke: ok");
  return EXIT_SUCCESS;
}
