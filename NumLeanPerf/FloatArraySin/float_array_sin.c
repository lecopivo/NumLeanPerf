#include <lean/lean.h>
#include <math.h>

lean_obj_res lean_float_array_sin(lean_obj_arg xs) {
  lean_obj_res r = lean_is_exclusive(xs) ? xs : lean_copy_float_array(xs);
  size_t n = lean_sarray_size(r);
  double *restrict p = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++) p[i] = sin(p[i]);
  return r;
}
