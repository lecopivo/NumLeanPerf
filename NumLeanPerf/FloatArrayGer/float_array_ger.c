#include <lean/lean.h>

lean_obj_res lean_float_array_ger(lean_obj_arg a, b_lean_obj_arg x, b_lean_obj_arg y) {
  lean_obj_res r = lean_is_exclusive(a) ? a : lean_copy_float_array(a);
  size_t n = lean_sarray_size(x);
  double *restrict ap = lean_float_array_cptr(r);
  const double *restrict xp = lean_float_array_cptr(x);
  const double *restrict yp = lean_float_array_cptr(y);
  for (size_t i = 0; i < n; i++) {
    for (size_t j = 0; j < n; j++) {
      ap[i * n + j] += xp[i] * yp[j];
    }
  }
  return r;
}
