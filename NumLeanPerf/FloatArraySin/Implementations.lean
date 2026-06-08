import NumLeanPerf.Data.FloatArray

def floatArraySin.nat_loop (xs : FloatArray) : FloatArray := Id.run do
  let mut xs' := xs
  for i in [0:xs'.size] do
    xs' := xs'.set! i (Float.sin xs'[i]!)
  return xs'

def floatArraySin.usize_loop (xs : FloatArray) : FloatArray := Id.run do
  let n := xs.size.toUSize
  let mut xs' := xs
  for i in 0...n do
    xs' := xs'.uset i (Float.sin xs'[i]!) sorry
  return xs'

def floatArraySin.usize_range_uget (xs : FloatArray) : FloatArray := Id.run do
  let n := xs.size.toUSize
  let mut xs' := xs
  for i in NumLeanPerf.uSizeRange 0 n do
    xs' := xs'.uset i (Float.sin (xs'.uget i sorry)) sorry
  return xs'

def floatArraySin.usize_range_unsafe_set (xs : FloatArray) : FloatArray := Id.run do
  let n := xs.size.toUSize
  let mut xs' := xs
  for i in NumLeanPerf.uSizeRange 0 n do
    xs' := xs'.unsafeSet i (Float.sin (xs'.uget i sorry))
  return xs'

@[extern "lean_float_array_sin"]
opaque floatArraySin.c_loop (xs : FloatArray) : FloatArray
