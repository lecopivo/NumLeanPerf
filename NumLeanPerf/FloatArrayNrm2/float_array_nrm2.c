#include <lean/lean.h>
#include <math.h>

double lean_float_array_nrm2(b_lean_obj_arg xs) {
  size_t n = lean_sarray_size(xs);
  const double *xp = lean_float_array_cptr(xs);
  double s = 0.0;
  for (size_t i = 0; i < n; i++) {
    s += xp[i] * xp[i];
  }
  return sqrt(s);
}
