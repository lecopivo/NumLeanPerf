private def gemmDim (n : Nat) : Nat := Id.run do
  let mut s : Nat := 0
  while (s + 1) * (s + 1) <= n do
    s := s + 1
  return s

-- C <- A*B + C  (alpha=1, beta=1); A, B, C are n×n (row-major); n = gemmDim a.size
def floatArrayGemm.nat_loop (a b c : FloatArray) : FloatArray := Id.run do
  let n := gemmDim a.size
  let mut c' := c
  for i in [0:n] do
    for j in [0:n] do
      let mut sum := c'[i * n + j]!
      for k in [0:n] do
        sum := sum + a[i * n + k]! * b[k * n + j]!
      c' := c'.set! (i * n + j) sum
  return c'

def floatArrayGemm.usize_loop (a b c : FloatArray) : FloatArray := Id.run do
  let n := gemmDim a.size
  let nU := n.toUSize
  let mut c' := c
  for i in 0...nU do
    for j in 0...nU do
      let mut sum := c'[i * nU + j]!
      for k in 0...nU do
        sum := sum + a[i * nU + k]! * b[k * nU + j]!
      c' := c'.uset (i * nU + j) sum sorry
  return c'

@[extern "lean_float_array_gemm"]
opaque floatArrayGemm.c_loop (a : @& FloatArray) (b : @& FloatArray) (c : FloatArray) : FloatArray
