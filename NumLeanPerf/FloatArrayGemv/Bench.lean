import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayGemv.Implementations

def floatArrayGemvBenchmarkId := "float-array-gemv"
def floatArrayGemvBenchmarkName := "FloatArray gemv"
def floatArrayGemvBenchmarkDescription :=
  "y <- A*x + y (BLAS gemv, alpha=1, beta=1) for a square n×n matrix. Sizes are the matrix dimension n."

def gemvImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → FloatArray → FloatArray)) := [
  { id := "lean.floatArrayGemv.nat_loop"
    language := "lean"
    name := "Lean nat_loop"
    sourceFile := "NumLeanPerf/FloatArrayGemv/Implementations.lean"
    symbol := "floatArrayGemv.nat_loop"
    run := floatArrayGemv.nat_loop },
  { id := "lean.floatArrayGemv.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArrayGemv/Implementations.lean"
    symbol := "floatArrayGemv.usize_loop"
    run := floatArrayGemv.usize_loop },
  { id := "c.floatArrayGemv.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArrayGemv/float_array_gemv.c"
    symbol := "lean_float_array_gemv"
    run := floatArrayGemv.c_loop }
]

def gemvImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray → FloatArray) :=
  (gemvImplementations.find? (fun e => e.id == name)).map (·.run)

-- Sizes are matrix dimensions n; batchSizeExponent=2 calibrates batch for O(n²) work per call
def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayGemvBenchmarkId floatArrayGemvBenchmarkName
      floatArrayGemvBenchmarkDescription gemvImplementations
      [64, 128, 256, 512, 1024, 2048] 2)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-gemv-bench <implementation> <matrix-elements> <samples> <warmups> <batch-size>"; return 2
  let some sizeArg := parseNatArg? args 1
    | IO.eprintln "invalid matrix-elements"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := gemvImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let n := sizeArg
  let poolSize := inputPoolSize samples warmups
  let matInputs := mkFloatArrayInputs poolSize (n * n)
  let xInputs   := mkFloatArrayInputs poolSize n
  let yInputs   := mkFloatArrayInputs poolSize n 2.0
  printTimingLines samples warmups batchSize (fun i =>
    let p := i % poolSize
    pure (fingerprintFloatArray (impl matInputs[p]! xInputs[p]! yInputs[p]!)))
  return 0
