#include <lean/lean.h>

lean_obj_res lean_float_array_axpy(double a, b_lean_obj_arg x, lean_obj_arg y) {
  lean_obj_res r;
  if (lean_is_exclusive(y)) {
    r = y;
  } else {
    r = lean_copy_float_array(y);
  }

  size_t n = lean_sarray_size(r);
  double *restrict rp = lean_float_array_cptr(r);
  const double *restrict xp = lean_float_array_cptr(x);
  for (size_t i = 0; i < n; i++) {
    rp[i] = rp[i] + a * xp[i];
  }
  return r;
}
