-- C <- A*B + C  (alpha=1, beta=1); A, B, C are n×n (row-major)

def floatArrayGemm.usize_loop_ijk (n : USize) (a b c : FloatArray) : FloatArray := Id.run do
  let mut c' := c
  for i in 0...n do
    for j in 0...n do
      let mut sum := c'[i * n + j]!
      for k in 0...n do
        sum := sum + a[i * n + k]! * b[k * n + j]!
      c' := c'.uset (i * n + j) sum sorry
  return c'

def floatArrayGemm.usize_loop_ikj (n : USize) (a b c : FloatArray) : FloatArray := Id.run do
  let mut c' := c
  for i in 0...n do
    for k in 0...n do
      let aik := a[i * n + k]!
      for j in 0...n do
        let idx := i * n + j
        c' := c'.uset idx (c'[idx]! + aik * b[k * n + j]!) sorry
  return c'

partial def floatArrayGemm.usize_rec_ijk_uget (n : USize) (a b c : FloatArray) : FloatArray :=
  goI 0 c
where
  goI (i : USize) (c : FloatArray) : FloatArray :=
    if i < n then
      let row := i * n
      goI (i + 1) (goJ row 0 c)
    else
      c

  goJ (row j : USize) (c : FloatArray) : FloatArray :=
    if j < n then
      let idx := row + j
      let sum := goK row j 0 (c.uget idx sorry)
      goJ row (j + 1) (c.uset idx sum sorry)
    else
      c

  goK (row j k : USize) (sum : Float) : Float :=
    if k < n then
      let aik := a.uget (row + k) sorry
      let bkj := b.uget (k * n + j) sorry
      goK row j (k + 1) (sum + aik * bkj)
    else
      sum

partial def floatArrayGemm.usize_rec_ikj_uget (n : USize) (a b c : FloatArray) : FloatArray :=
  goI 0 c
where
  goI (i : USize) (c : FloatArray) : FloatArray :=
    if i < n then
      let row := i * n
      goI (i + 1) (goK row 0 c)
    else
      c

  goK (row k : USize) (c : FloatArray) : FloatArray :=
    if k < n then
      let brow := k * n
      let aik := a.uget (row + k) sorry
      goK row (k + 1) (goJ row brow aik 0 c)
    else
      c

  goJ (row brow : USize) (aik : Float) (j : USize) (c : FloatArray) : FloatArray :=
    if j < n then
      let idx := row + j
      let cij := c.uget idx sorry
      let bkj := b.uget (brow + j) sorry
      goJ row brow aik (j + 1) (c.uset idx (cij + aik * bkj) sorry)
    else
      c

@[extern "lean_float_array_gemm_ijk"]
opaque floatArrayGemm.c_loop_ijk (n : USize) (a : @& FloatArray) (b : @& FloatArray) (c : FloatArray) : FloatArray

@[extern "lean_float_array_gemm_ikj"]
opaque floatArrayGemm.c_loop_ikj (n : USize) (a : @& FloatArray) (b : @& FloatArray) (c : FloatArray) : FloatArray
