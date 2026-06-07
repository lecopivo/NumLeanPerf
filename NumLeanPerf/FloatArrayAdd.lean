def floatArrayAdd.nat_loop_get! (xs ys : FloatArray) : FloatArray := Id.run do
  let mut out := FloatArray.empty
  for h : i in 0...xs.size do
    out := out.push (xs[i] + ys[i]!)
  return out

def floatArrayAdd.usize_loop_get! (xs ys : FloatArray) : FloatArray := Id.run do
  let mut out := FloatArray.empty
  for (i : USize) in 0...(xs.size.toUSize) do
    out := out.push (xs[i]! + ys[i]!)
  return out

def floatArrayAdd.foreach_zip (xs ys : FloatArray) : FloatArray := Id.run do
  let mut out := FloatArray.empty
  let mut i := 0
  for x in xs do
    out := out.push (x + ys[i]!)
    i := i + 1
  return out
