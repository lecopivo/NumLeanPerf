-- C <- A*B + C  (alpha=1, beta=1); A, B, C are n×n (row-major)

def floatArrayGemm.usize_loop_ijk (n : USize) (a b c : FloatArray) : FloatArray := Id.run do
  let mut c' := c
  for i in 0...n do
    for j in 0...n do
      let mut sum := c'[i * n + j]!
      for k in 0...n do
        sum := sum + a[i * n + k]! * b[k * n + j]!
      c' := c'.uset (i * n + j) sum sorry
  return c'

def floatArrayGemm.usize_loop_ikj (n : USize) (a b c : FloatArray) : FloatArray := Id.run do
  let mut c' := c
  for i in 0...n do
    for k in 0...n do
      let aik := a[i * n + k]!
      for j in 0...n do
        let idx := i * n + j
        c' := c'.uset idx (c'[idx]! + aik * b[k * n + j]!) sorry
  return c'

@[extern "lean_float_array_gemm_ijk"]
opaque floatArrayGemm.c_loop_ijk (n : USize) (a : @& FloatArray) (b : @& FloatArray) (c : FloatArray) : FloatArray

@[extern "lean_float_array_gemm_ikj"]
opaque floatArrayGemm.c_loop_ikj (n : USize) (a : @& FloatArray) (b : @& FloatArray) (c : FloatArray) : FloatArray
