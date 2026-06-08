-- A += x * yᵀ  (BLAS ger with alpha=1); A is n×n, x and y are n; n inferred from x.size
def floatArrayGer.usize_loop (a x y : FloatArray) : FloatArray := Id.run do
  let nU := x.size.toUSize
  let mut a' := a
  for i in 0...nU do
    for j in 0...nU do
      let idx := i * nU + j
      a' := a'.uset idx (a'[idx]! + x[i]! * y[j]!) sorry
  return a'

partial def floatArrayGer.usize_rec_uget (a x y : FloatArray) : FloatArray :=
  let n := x.size.toUSize
  goI n 0 a
where
  goI (n i : USize) (a : FloatArray) : FloatArray :=
    if h : i.toNat < x.size then
      let row := i * n
      let xi := x.uget i h
      goI n (i + 1) (goJ n row xi 0 a)
    else
      a

  goJ (n row : USize) (xi : Float) (j : USize) (a : FloatArray) : FloatArray :=
    if h : j.toNat < y.size then
      let idx := row + j
      let aij := a.uget idx sorry
      let yj := y.uget j h
      goJ n row xi (j + 1) (a.uset idx (aij + xi * yj) sorry)
    else
      a

@[extern "lean_float_array_ger"]
opaque floatArrayGer.c_loop (a : FloatArray) (x : @& FloatArray) (y : @& FloatArray) : FloatArray
