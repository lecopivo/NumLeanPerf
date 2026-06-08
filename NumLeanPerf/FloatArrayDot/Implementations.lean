def floatArrayDot.usize_loop (x y : FloatArray) : Float := Id.run do
  let mut s := 0.0
  for i in 0...(x.size.toUSize) do
    s := s + x[i]! * y[i]!
  return s

@[extern "lean_float_array_dot"]
opaque floatArrayDot.c_loop (x : @& FloatArray) (y : @& FloatArray) : Float
