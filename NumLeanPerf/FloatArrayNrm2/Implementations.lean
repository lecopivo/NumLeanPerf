import NumLeanPerf.Data.UIntRange

def floatArrayNrm2.usize_loop (xs : FloatArray) : Float := Id.run do
  let mut s := 0.0
  for i in 0...(xs.size.toUSize) do
    let x := xs[i]!
    s := s + x * x
  return Float.sqrt s

def floatArrayNrm2.usize_range_uget (xs : FloatArray) : Float := Id.run do
  let mut s := 0.0
  for i in NumLeanPerf.uSizeRange 0 xs.size.toUSize do
    let x := xs.uget i sorry
    s := s + x * x
  return Float.sqrt s

@[extern "lean_float_array_nrm2"]
opaque floatArrayNrm2.c_loop (xs : @& FloatArray) : Float
