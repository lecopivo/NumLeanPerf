#include <lean/lean.h>

lean_obj_res lean_float_array_unsafe_set(lean_obj_arg xs, size_t i, double x) {
    lean_float_array_cptr(xs)[i] = x;
    return xs;
}
