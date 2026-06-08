#include <lean/lean.h>

double lean_float_array_dot(b_lean_obj_arg x, b_lean_obj_arg y) {
  size_t n = lean_sarray_size(x);
  const double *restrict xp = lean_float_array_cptr(x);
  const double *restrict yp = lean_float_array_cptr(y);
  double s = 0.0;
  for (size_t i = 0; i < n; i++) {
    s += xp[i] * yp[i];
  }
  return s;
}
