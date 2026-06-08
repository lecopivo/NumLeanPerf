#include <lean/lean.h>

lean_obj_res lean_float_array_gemm_ijk(size_t n, b_lean_obj_arg a, b_lean_obj_arg b, lean_obj_arg c) {
  lean_obj_res r = lean_is_exclusive(c) ? c : lean_copy_float_array(c);
  const double *restrict ap = lean_float_array_cptr(a);
  const double *restrict bp = lean_float_array_cptr(b);
  double *restrict cp = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++)
    for (size_t j = 0; j < n; j++) {
      double sum = cp[i * n + j];
      for (size_t k = 0; k < n; k++) sum += ap[i * n + k] * bp[k * n + j];
      cp[i * n + j] = sum;
    }
  return r;
}

lean_obj_res lean_float_array_gemm_ikj(size_t n, b_lean_obj_arg a, b_lean_obj_arg b, lean_obj_arg c) {
  lean_obj_res r = lean_is_exclusive(c) ? c : lean_copy_float_array(c);
  const double *restrict ap = lean_float_array_cptr(a);
  const double *restrict bp = lean_float_array_cptr(b);
  double *restrict cp = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++)
    for (size_t k = 0; k < n; k++) {
      double aik = ap[i * n + k];
      for (size_t j = 0; j < n; j++) cp[i * n + j] += aik * bp[k * n + j];
    }
  return r;
}
