import NumLeanPerf.FloatArraySum.Implementations

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

def fingerprintFloatArray (xs : FloatArray) : Float :=
  if h : 0 < xs.size then
    let last := xs.size - 1
    let mid := xs.size / 2
    xs[0] + xs[mid]! + xs[last]!
  else
    0.0

structure BenchmarkImplementation (α : Type) where
  id : String
  language : String
  name : String
  sourceFile : String
  symbol : String
  run : α

def jsonEscape (s : String) : String := Id.run do
  let mut out := ""
  for c in s.toList do
    out := out ++ match c with
      | '"' => "\\\""
      | '\\' => "\\\\"
      | '\n' => "\\n"
      | '\r' => "\\r"
      | '\t' => "\\t"
      | c => c.toString
  return out

def jsonString (s : String) : String :=
  "\"" ++ jsonEscape s ++ "\""

def renderImplementationMetadata {α : Type} (impl : BenchmarkImplementation α) : String :=
  "{" ++
  "\"id\":" ++ jsonString impl.id ++ "," ++
  "\"language\":" ++ jsonString impl.language ++ "," ++
  "\"name\":" ++ jsonString impl.name ++ "," ++
  "\"sourceFile\":" ++ jsonString impl.sourceFile ++ "," ++
  "\"symbol\":" ++ jsonString impl.symbol ++
  "}"

def renderBenchmarkMetadata {α : Type} (id name description : String) (impls : List (BenchmarkImplementation α)) : String :=
  let implementations := String.intercalate "," (impls.map renderImplementationMetadata)
  "{" ++
  "\"id\":" ++ jsonString id ++ "," ++
  "\"name\":" ++ jsonString name ++ "," ++
  "\"description\":" ++ jsonString description ++ "," ++
  "\"inputAxes\":[{\"id\":\"arraySize\",\"name\":\"Array size\",\"unit\":\"elements\"}]," ++
  "\"implementations\":[" ++ implementations ++ "]" ++
  "}"

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
