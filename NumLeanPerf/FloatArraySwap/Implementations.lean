def floatArraySwap.nat_loop (x y : FloatArray) : FloatArray × FloatArray := Id.run do
  let n := x.size
  let mut xs : FloatArray := .empty
  let mut ys : FloatArray := .empty
  for i in [0:n] do
    xs := xs.push y[i]!
    ys := ys.push x[i]!
  return (xs, ys)

@[extern "lean_float_array_swap"]
opaque floatArraySwap.c_loop (x y : FloatArray) : FloatArray × FloatArray
