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
  int err = 0;

  artn_version_semantic(&major, &minor, &patch);
  assert(major >= 0);
  assert(minor >= 0);
  assert(patch >= 0);

  artn_gitinfo(&gitinfo);
  assert(gitinfo != NULL);
  assert(strchr(gitinfo, ':') != NULL);

  dtype = artn_get_dtype_str(artn_get_dtype_val("ARTN_DTYPE_REAL"));
  assert(dtype != NULL);
  assert(strcmp(dtype, "real") == 0);

  reset_error();
  err = get_error(&errmsg);
  assert(err == 0);
  assert(errmsg == NULL);

  puts("c_api_smoke: ok");
  return EXIT_SUCCESS;
}
