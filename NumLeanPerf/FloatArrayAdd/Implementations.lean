def floatArrayAdd.nat_loop_get (xs ys : FloatArray) : FloatArray := Id.run do
  let mut out := FloatArray.emptyWithCapacity xs.size
  for h : i in 0...(min xs.size ys.size) do
    out := out.push (xs[i] + ys[i])
  return out

def floatArrayAdd.usize_loop_uget (xs ys : FloatArray) : FloatArray := Id.run do
  let mut out := FloatArray.emptyWithCapacity xs.size
  for (i : USize) in 0...(xs.size.toUSize) do
    out := out.push (xs.uget i sorry + ys.uget i sorry)
  return out

@[extern "lean_float_array_add"]
opaque floatArrayAdd.c_loop (xs : @& FloatArray) (ys : FloatArray) : FloatArray
