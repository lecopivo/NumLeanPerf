-- A += x * yᵀ  (BLAS ger with alpha=1); A is n×n, x and y are n; n inferred from x.size
def floatArrayGer.usize_loop (a x y : FloatArray) : FloatArray := Id.run do
  let nU := x.size.toUSize
  let mut a' := a
  for i in 0...nU do
    for j in 0...nU do
      let idx := i * nU + j
      a' := a'.uset idx (a'[idx]! + x[i]! * y[j]!) sorry
  return a'

@[extern "lean_float_array_ger"]
opaque floatArrayGer.c_loop (a : FloatArray) (x : @& FloatArray) (y : @& FloatArray) : FloatArray
