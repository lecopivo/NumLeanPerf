def floatArrayDot.usize_loop (x y : FloatArray) : Float := Id.run do
  let mut s := 0.0
  for i in 0...(x.size.toUSize) do
    s := s + x[i]! * y[i]!
  return s

partial def floatArrayDot.usize_rec_uget (x y : FloatArray) : Float :=
  go 0 0.0
where
  go (i : USize) (s : Float) : Float :=
    if h : i.toNat < x.size then
      go (i + 1) (s + x.uget i h * y.uget i sorry)
    else
      s

@[extern "lean_float_array_dot"]
opaque floatArrayDot.c_loop (x : @& FloatArray) (y : @& FloatArray) : Float
