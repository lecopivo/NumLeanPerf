import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayAdd.Implementations

def floatArrayAddBenchmarkId := "float-array-add"
def floatArrayAddBenchmarkName := "FloatArray add"
def floatArrayAddBenchmarkDescription := "Elementwise add two FloatArrays and return a new array."

def addImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → FloatArray)) := [
  {
    id := "lean.floatArrayAdd.nat_loop_get!"
    language := "lean"
    name := "Lean nat_loop_get!"
    sourceFile := "NumLeanPerf/FloatArrayAdd/Implementations.lean"
    symbol := "floatArrayAdd.nat_loop_get!"
    run := floatArrayAdd.nat_loop_get!
  },
  {
    id := "lean.floatArrayAdd.usize_loop_get!"
    language := "lean"
    name := "Lean usize_loop_get!"
    sourceFile := "NumLeanPerf/FloatArrayAdd/Implementations.lean"
    symbol := "floatArrayAdd.usize_loop_get!"
    run := floatArrayAdd.usize_loop_get!
  },
  {
    id := "lean.floatArrayAdd.foreach_zip"
    language := "lean"
    name := "Lean foreach_zip"
    sourceFile := "NumLeanPerf/FloatArrayAdd/Implementations.lean"
    symbol := "floatArrayAdd.foreach_zip"
    run := floatArrayAdd.foreach_zip
  },
  {
    id := "c.floatArrayAdd.malloc_loop"
    language := "c"
    name := "C loop via Lean FFI"
    sourceFile := "NumLeanPerf/FloatArrayAdd/float_array_add.c"
    symbol := "lean_float_array_add"
    run := floatArrayAdd.c_loop
  }
]

def addImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray) :=
  (addImplementations.find? (fun entry => entry.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayAddBenchmarkId floatArrayAddBenchmarkName floatArrayAddBenchmarkDescription addImplementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-add-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := addImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let xsInputs := mkFloatArrayInputs poolSize n
  let ysInputs := mkFloatArrayInputs poolSize n 1.0
  printTimingLines samples warmups batchSize (fun i => pure (fingerprintFloatArray (impl xsInputs[i % poolSize]! ysInputs[i % poolSize]!)))
  return 0
