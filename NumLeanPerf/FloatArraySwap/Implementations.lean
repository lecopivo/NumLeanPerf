import NumLeanPerf.Data.FloatArray

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

partial def floatArraySwap.usize_rec_uget_bound (x y : FloatArray) : FloatArray × FloatArray :=
  go x.size.toUSize 0 x y
where
  go (n i : USize) (x y : FloatArray) : FloatArray × FloatArray :=
    if i < n then
      let xi := x.uget i sorry
      let yi := y.uget i sorry
      go n (i + 1) (x.uset i yi sorry) (y.uset i xi sorry)
    else
      (x, y)

def floatArraySwap.usize_range_uget (x y : FloatArray) : FloatArray × FloatArray := Id.run do
  let mut x := x
  let mut y := y
  for i in NumLeanPerf.uSizeRange 0 x.size.toUSize do
    let xi := x.uget i sorry
    let yi := y.uget i sorry
    x := x.uset i yi sorry
    y := y.uset i xi sorry
  return (x, y)

def floatArraySwap.usize_range_unsafe_set (x y : FloatArray) : FloatArray × FloatArray := Id.run do
  let mut x := x
  let mut y := y
  for i in NumLeanPerf.uSizeRange 0 x.size.toUSize do
    let xi := x.uget i sorry
    let yi := y.uget i sorry
    x := x.unsafeSet i yi
    y := y.unsafeSet i xi
  return (x, y)

@[extern "lean_float_array_swap"]
opaque floatArraySwap.c_loop (x y : FloatArray) : FloatArray × FloatArray
