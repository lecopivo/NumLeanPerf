import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArraySwap.Implementations

def floatArraySwapBenchmarkId := "float-array-swap"
def floatArraySwapBenchmarkName := "FloatArray swap"
def floatArraySwapBenchmarkDescription := "Swap two FloatArrays element-wise."

def swapImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → FloatArray × FloatArray)) := [
  { id := "lean.floatArraySwap.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArraySwap/Implementations.lean"
    symbol := "floatArraySwap.usize_loop"
    run := floatArraySwap.usize_loop },
  { id := "lean.floatArraySwap.usize_rec_uget"
    language := "lean"
    name := "Lean usize_rec_uget"
    sourceFile := "NumLeanPerf/FloatArraySwap/Implementations.lean"
    symbol := "floatArraySwap.usize_rec_uget"
    run := floatArraySwap.usize_rec_uget },
  { id := "c.floatArraySwap.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArraySwap/float_array_swap.c"
    symbol := "lean_float_array_swap"
    run := floatArraySwap.c_loop }
]

def swapImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray × FloatArray) :=
  (swapImplementations.find? (fun e => e.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArraySwapBenchmarkId floatArraySwapBenchmarkName floatArraySwapBenchmarkDescription swapImplementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-swap-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := swapImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let xInputs := mkFloatArrayInputs poolSize n
  let yInputs := mkFloatArrayInputs poolSize n 1.0
  printTimingLines samples warmups batchSize (fun i =>
    let p := i % poolSize
    let (xs', ys') := impl xInputs[p]! yInputs[p]!
    pure (fingerprintFloatArray xs' + fingerprintFloatArray ys'))
  return 0
