#include <lean/lean.h>

lean_obj_res lean_float_array_add(b_lean_obj_arg xs, lean_obj_arg ys) {
  lean_obj_res r;
  if (lean_is_exclusive(ys)) {
    r = ys;
  } else {
    r = lean_copy_float_array(ys);
  }

  size_t n = lean_sarray_size(r);
  const double *restrict xp = lean_float_array_cptr(xs);
  double *restrict rp = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++) {
    rp[i] = xp[i] + rp[i];
  }
  return r;
}
