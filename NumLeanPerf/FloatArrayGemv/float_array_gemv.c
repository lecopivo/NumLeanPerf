#include <lean/lean.h>

lean_obj_res lean_float_array_gemv(b_lean_obj_arg a, b_lean_obj_arg x, lean_obj_arg y) {
  lean_obj_res r = lean_is_exclusive(y) ? y : lean_copy_float_array(y);
  size_t n = lean_sarray_size(x);
  const double *restrict ap = lean_float_array_cptr(a);
  const double *restrict xp = lean_float_array_cptr(x);
  double *restrict rp = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++) {
    double sum = rp[i];
    for (size_t j = 0; j < n; j++) {
      sum += ap[i * n + j] * xp[j];
    }
    rp[i] = sum;
  }
  return r;
}
