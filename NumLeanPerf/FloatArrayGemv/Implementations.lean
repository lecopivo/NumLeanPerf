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

partial def floatArrayGemv.usize_rec_uget (a x y : FloatArray) : FloatArray :=
  let n := x.size.toUSize
  goI n 0 y
where
  goI (n i : USize) (y : FloatArray) : FloatArray :=
    if h : i.toNat < y.size then
      let row := i * n
      let sum := goJ n row 0 (y.uget i h)
      goI n (i + 1) (y.uset i sum h)
    else
      y

  goJ (n row j : USize) (sum : Float) : Float :=
    if h : j.toNat < x.size then
      let aij := a.uget (row + j) sorry
      let xj := x.uget j h
      goJ n row (j + 1) (sum + aij * xj)
    else
      sum

@[extern "lean_float_array_gemv"]
opaque floatArrayGemv.c_loop (a : @& FloatArray) (x : @& FloatArray) (y : FloatArray) : FloatArray
