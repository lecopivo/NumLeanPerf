#include <lean/lean.h>

lean_obj_res lean_float_array_swap(lean_obj_arg x, lean_obj_arg y) {
  lean_obj_res rx = lean_is_exclusive(x) ? x : lean_copy_float_array(x);
  lean_obj_res ry = lean_is_exclusive(y) ? y : lean_copy_float_array(y);
  size_t n = lean_sarray_size(rx);
  double *restrict xp = lean_float_array_cptr(rx);
  double *restrict yp = lean_float_array_cptr(ry);
  for (size_t i = 0; i < n; i++) {
    double tmp = xp[i];
    xp[i] = yp[i];
    yp[i] = tmp;
  }
  lean_obj_res pair = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(pair, 0, rx);
  lean_ctor_set(pair, 1, ry);
  return pair;
}
