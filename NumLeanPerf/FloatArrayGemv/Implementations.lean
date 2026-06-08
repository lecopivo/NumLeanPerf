-- y <- A*x + y  (alpha=1, beta=1); A is n×n (row-major), x and y are n; n inferred from x.size
def floatArrayGemv.usize_loop (a x y : FloatArray) : FloatArray := Id.run do
  let nU := x.size.toUSize
  let mut y' := y
  for i in 0...nU do
    let mut sum := y'[i]!
    for j in 0...nU do
      sum := sum + a[i * nU + j]! * x[j]!
    y' := y'.uset i sum sorry
  return y'

@[extern "lean_float_array_gemv"]
opaque floatArrayGemv.c_loop (a : @& FloatArray) (x : @& FloatArray) (y : FloatArray) : FloatArray
