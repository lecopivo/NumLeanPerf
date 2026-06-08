-- A += x * yᵀ  (BLAS ger with alpha=1); A is n×n, x and y are n; n inferred from x.size
def floatArrayGer.nat_loop (a x y : FloatArray) : FloatArray := Id.run do
  let n := x.size
  let mut a' := a
  for i in [0:n] do
    for j in [0:n] do
      let idx := i * n + j
      a' := a'.set! idx (a'[idx]! + x[i]! * y[j]!)
  return a'

def floatArrayGer.usize_loop (a x y : FloatArray) : FloatArray := Id.run do
  let n := x.size
  let nU := n.toUSize
  let mut a' := a
  for i in 0...nU do
    for j in 0...nU do
      let idx := i * nU + j
      a' := a'.uset idx (a'[idx]! + x[i]! * y[j]!) sorry
  return a'

@[extern "lean_float_array_ger"]
opaque floatArrayGer.c_loop (a : FloatArray) (x : @& FloatArray) (y : @& FloatArray) : FloatArray
