def floatArraySum.nat_rec (xs : FloatArray) : Float :=
  go 0 0
where
  go (i : Nat) (s : Float) : Float :=
    if h : i < xs.size then
      go (i+1) (s + xs[i])
    else
      s

partial def floatArraySum.usize_rec (xs : FloatArray) : Float :=
  go 0 0
where
  go (i : USize) (s : Float) : Float :=
    if h : i.toNat < xs.size then
      go (i+1) (s + xs.uget i h)
    else
      s

def floatArraySum.foreach_loop (xs : FloatArray) : Float := Id.run do
  let mut s := 0
  for x in xs do
    s := s + x
  return s

def floatArraySum.nat_loop (xs : FloatArray) : Float := Id.run do
  let mut s := 0
  for h : i in 0...xs.size do
    s := s + xs[i]
  return s

def floatArraySum.usize_loop_get! (xs : FloatArray) : Float := Id.run do
  let mut s := 0
  for (i : USize) in 0...(xs.size.toUSize) do
    s := s + xs[i]!
  return s
