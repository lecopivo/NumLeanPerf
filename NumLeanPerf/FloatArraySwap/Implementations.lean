def floatArraySwap.usize_loop (x y : FloatArray) : FloatArray × FloatArray := Id.run do
  let n := x.size.toUSize
  let mut xs := x
  let mut ys := y
  for i in 0...n do
    let tmp := xs[i]!
    xs := xs.uset i ys[i]! sorry
    ys := ys.uset i tmp sorry
  return (xs, ys)

partial def floatArraySwap.usize_rec_uget (x y : FloatArray) : FloatArray × FloatArray :=
  go 0 x y
where
  go (i : USize) (x y : FloatArray) : FloatArray × FloatArray :=
    if h : i.toNat < x.size then
      let xi := x.uget i h
      let yi := y.uget i sorry
      go (i + 1) (x.uset i yi h) (y.uset i xi sorry)
    else
      (x, y)

@[extern "lean_float_array_swap"]
opaque floatArraySwap.c_loop (x y : FloatArray) : FloatArray × FloatArray
