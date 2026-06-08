#include <lean/lean.h>
#include <math.h>

lean_obj_res lean_float_array_gemm(b_lean_obj_arg a, b_lean_obj_arg b, lean_obj_arg c) {
  lean_obj_res r = lean_is_exclusive(c) ? c : lean_copy_float_array(c);
  size_t nn = lean_sarray_size(a);
  size_t n = (size_t)sqrt((double)nn);
  const double *restrict ap = lean_float_array_cptr(a);
  const double *restrict bp = lean_float_array_cptr(b);
  double *restrict cp = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++) {
    for (size_t k = 0; k < n; k++) {
      double aik = ap[i * n + k];
      for (size_t j = 0; j < n; j++) {
        cp[i * n + j] += aik * bp[k * n + j];
      }
    }
  }
  return r;
}
