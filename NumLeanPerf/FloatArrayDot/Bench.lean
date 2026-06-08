import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayDot.Implementations

def floatArrayDotBenchmarkId := "float-array-dot"
def floatArrayDotBenchmarkName := "FloatArray dot"
def floatArrayDotBenchmarkDescription := "Dot product of two FloatArrays."

def dotImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → Float)) := [
  { id := "lean.floatArrayDot.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArrayDot/Implementations.lean"
    symbol := "floatArrayDot.usize_loop"
    run := floatArrayDot.usize_loop },
  { id := "c.floatArrayDot.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArrayDot/float_array_dot.c"
    symbol := "lean_float_array_dot"
    run := floatArrayDot.c_loop }
]

def dotImplementation? (name : String) : Option (FloatArray → FloatArray → Float) :=
  (dotImplementations.find? (fun e => e.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayDotBenchmarkId floatArrayDotBenchmarkName floatArrayDotBenchmarkDescription dotImplementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-dot-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := dotImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let xInputs := mkFloatArrayInputs poolSize n
  let yInputs := mkFloatArrayInputs poolSize n 1.0
  printTimingLines samples warmups batchSize
    (fun i => pure (impl xInputs[i % poolSize]! yInputs[i % poolSize]!))
  return 0
