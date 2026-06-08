def floatArraySwap.usize_loop (x y : FloatArray) : FloatArray × FloatArray := Id.run do
  let n := x.size.toUSize
  let mut xs := x
  let mut ys := y
  for i in 0...n do
    let tmp := xs[i]!
    xs := xs.uset i ys[i]! sorry
    ys := ys.uset i tmp sorry
  return (xs, ys)

@[extern "lean_float_array_swap"]
opaque floatArraySwap.c_loop (x y : FloatArray) : FloatArray × FloatArray
