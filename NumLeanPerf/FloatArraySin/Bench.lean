import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArraySin.Implementations

def floatArraySinBenchmarkId := "float-array-sin"
def floatArraySinBenchmarkName := "FloatArray sin"
def floatArraySinBenchmarkDescription := "In-place sin of each element of a FloatArray."

def sinImplementations : List (BenchmarkImplementation (FloatArray → FloatArray)) := [
  { id := "lean.floatArraySin.nat_loop"
    language := "lean"
    name := "Lean nat_loop"
    sourceFile := "NumLeanPerf/FloatArraySin/Implementations.lean"
    symbol := "floatArraySin.nat_loop"
    run := floatArraySin.nat_loop },
  { id := "lean.floatArraySin.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArraySin/Implementations.lean"
    symbol := "floatArraySin.usize_loop"
    run := floatArraySin.usize_loop },
  { id := "c.floatArraySin.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArraySin/float_array_sin.c"
    symbol := "lean_float_array_sin"
    run := floatArraySin.c_loop }
]

def sinImplementation? (name : String) : Option (FloatArray → FloatArray) :=
  (sinImplementations.find? (fun e => e.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArraySinBenchmarkId floatArraySinBenchmarkName
      floatArraySinBenchmarkDescription sinImplementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-sin-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := sinImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let inputs := mkFloatArrayInputs poolSize n
  printTimingLines samples warmups batchSize
    (fun i => pure (fingerprintFloatArray (impl inputs[i % poolSize]!)))
  return 0
