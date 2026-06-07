import NumLeanPerf.FloatArraySum

def mkFloatArray (n : Nat) (offset : Float := 0.0) : FloatArray := Id.run do
  let mut xs := FloatArray.empty
  for i in [0:n] do
    xs := xs.push (Float.ofNat (i % 1024) + offset)
  return xs

def mkFloatArrayInputs (count n : Nat) (baseOffset : Float := 0.0) : Array FloatArray := Id.run do
  let mut inputs := #[]
  for k in [0:count] do
    inputs := inputs.push (mkFloatArray n (baseOffset + Float.ofNat (k % 251)))
  return inputs

def inputPoolSize (samples warmups : Nat) : Nat :=
  let total := samples + warmups
  if total == 0 then 1 else min total 2

def sumFloatArray (xs : FloatArray) : Float :=
  floatArraySum.foreach_loop xs

def runBatch (batchSize startIndex : Nat) (runOnce : Nat → IO Float) : IO Float := do
  let mut checksum := 0.0
  for k in [0:batchSize] do
    checksum := checksum + (← runOnce (startIndex + k))
  return checksum

def printTimingLines (samples warmups batchSize : Nat) (runOnce : Nat → IO Float) : IO Unit := do
  let mut checksum := 0.0
  for i in [0:warmups] do
    checksum := checksum + (← runBatch batchSize (i * batchSize) runOnce)
  for j in [0:samples] do
    let start ← IO.monoNanosNow
    checksum := checksum + (← runBatch batchSize ((warmups + j) * batchSize) runOnce)
    let stop ← IO.monoNanosNow
    IO.println (toString (stop - start))
  if checksum.isNaN then
    IO.eprintln "unexpected NaN checksum"

def parseNatArg? (args : List String) (idx : Nat) : Option Nat := do
  let s ← args[idx]?
  s.toNat?
