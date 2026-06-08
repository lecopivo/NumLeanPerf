import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayNrm2.Implementations

def floatArrayNrm2BenchmarkId := "float-array-nrm2"
def floatArrayNrm2BenchmarkName := "FloatArray nrm2"
def floatArrayNrm2BenchmarkDescription := "Euclidean norm (BLAS nrm2) of a FloatArray."

def nrm2Implementations : List (BenchmarkImplementation (FloatArray → Float)) := [
  { id := "lean.floatArrayNrm2.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArrayNrm2/Implementations.lean"
    symbol := "floatArrayNrm2.usize_loop"
    run := floatArrayNrm2.usize_loop },
  { id := "c.floatArrayNrm2.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArrayNrm2/float_array_nrm2.c"
    symbol := "lean_float_array_nrm2"
    run := floatArrayNrm2.c_loop }
]

def nrm2Implementation? (name : String) : Option (FloatArray → Float) :=
  (nrm2Implementations.find? (fun e => e.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayNrm2BenchmarkId floatArrayNrm2BenchmarkName floatArrayNrm2BenchmarkDescription nrm2Implementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-nrm2-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := nrm2Implementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let inputs := mkFloatArrayInputs poolSize n
  printTimingLines samples warmups batchSize
    (fun i => pure (impl inputs[i % poolSize]!))
  return 0
