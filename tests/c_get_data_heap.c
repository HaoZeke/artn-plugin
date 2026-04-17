#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "artn.h"

static void check_real_array(const double *actual, const double *expected,
                             size_t count) {
  for (size_t i = 0; i < count; ++i) {
    if (fabs(actual[i] - expected[i]) >= 1e-12) {
      fprintf(stderr, "mismatch at %zu: got %.17g expected %.17g\n", i,
              actual[i], expected[i]);
      abort();
    }
  }
}

int main(void) {
  const int nat = 2;
  const int rank0 = 0;
  const int dims2[2] = {3, nat};
  const char *engine_units = "lammps/metal";
  const double tau_sad[6] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0};
  const double eigen_sad[6] = {-1.0, -2.0, -3.0, -4.0, -5.0, -6.0};
  const double eigval_sad = -0.125;
  const bool has_sad = true;
  const bool has_error = false;
  bool setup_error = false;
  int ierr = 0;

  bool *has_sad_out = NULL;
  bool *has_error_out = NULL;
  double *eigval_out = NULL;
  double *tau_sad_out = NULL;
  double *eigen_sad_out = NULL;

  assert(artn_create() == 0);
  ierr = set_param("engine_units", rank0, NULL, engine_units);
  assert(ierr == 0);
  setup_artn(nat, &setup_error);
  assert(!setup_error);

  ierr = set_data("tau_sad", 2, dims2, tau_sad);
  assert(ierr == 0);
  ierr = set_data("eigen_sad", 2, dims2, eigen_sad);
  assert(ierr == 0);
  ierr = set_data("eigval_sad", rank0, NULL, &eigval_sad);
  assert(ierr == 0);
  ierr = set_data("has_sad", rank0, NULL, &has_sad);
  assert(ierr == 0);
  ierr = set_data("has_error", rank0, NULL, &has_error);
  assert(ierr == 0);

  ierr = get_data("has_sad", (void **)&has_sad_out);
  assert(ierr == 0);
  assert(has_sad_out != NULL);
  assert(*has_sad_out == has_sad);
  free(has_sad_out);

  ierr = get_data("has_error", (void **)&has_error_out);
  assert(ierr == 0);
  assert(has_error_out != NULL);
  assert(*has_error_out == has_error);
  free(has_error_out);

  ierr = get_data("eigval_sad", (void **)&eigval_out);
  assert(ierr == 0);
  assert(eigval_out != NULL);
  assert(fabs(*eigval_out - eigval_sad) < 1e-12);
  free(eigval_out);

  ierr = get_data("tau_sad", (void **)&tau_sad_out);
  assert(ierr == 0);
  assert(tau_sad_out != NULL);
  check_real_array(tau_sad_out, tau_sad, 6);
  free(tau_sad_out);

  ierr = get_data("eigen_sad", (void **)&eigen_sad_out);
  assert(ierr == 0);
  assert(eigen_sad_out != NULL);
  check_real_array(eigen_sad_out, eigen_sad, 6);
  free(eigen_sad_out);

  clean_artn();
  artn_destroy();

  puts("c_get_data_heap: ok");
  return EXIT_SUCCESS;
}
