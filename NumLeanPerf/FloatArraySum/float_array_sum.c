#include <lean/lean.h>

double lean_float_array_sum(b_lean_obj_arg xs) {
  size_t n = lean_sarray_size(xs);
  const double *xp = lean_float_array_cptr(xs);
  double s = 0.0;
  for (size_t i = 0; i < n; i++) {
    s += xp[i];
  }
  return s;
}
