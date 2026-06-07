def floatArrayAxpy.loop_uset (a : Float) (x y : FloatArray) : FloatArray := Id.run do
  let mut y := y
  for i in 0...(y.size.toUSize) do
    let yi := y[i]!
    let xi := x[i]!
    y := y.uset i (yi + a * xi) sorry
  return y

def floatArrayAxpy.loop_fset (a : Float) (x y : FloatArray) : FloatArray := Id.run do
  let mut y := y
  for i in 0...(y.size.toUSize) do
    let yi := y[i]!
    let xi := x[i]!
    y := y.set i.toNat (yi + a * xi) sorry
  return y

def floatArrayAxpy.loop_set (a : Float) (x y : FloatArray) : FloatArray := Id.run do
  let mut y := y
  for i in 0...(y.size.toUSize) do
    let yi := y[i]!
    let xi := x[i]!
    y := y.set! i.toNat (yi + a * xi)
  return y

def floatArrayAxpy.while_uset (a : Float) (x y : FloatArray) : FloatArray := Id.run do
  let mut y := y
  let mut i : USize := 0
  while i < y.size.toUSize do
    let yi := y[i]!
    let xi := x[i]!
    y := y.uset i (yi + a * xi) sorry
    i := i + 1
  return y


@[extern "lean_float_array_axpy"]
opaque floatArrayAxpy.c_loop (a : Float) (x : @& FloatArray) (y : FloatArray) : FloatArray
