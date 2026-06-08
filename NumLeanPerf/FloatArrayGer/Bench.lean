import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayGer.Implementations

def floatArrayGerBenchmarkId := "float-array-ger"
def floatArrayGerBenchmarkName := "FloatArray ger"
def floatArrayGerBenchmarkDescription :=
  "Rank-1 update A += x*yᵀ (BLAS ger, alpha=1) for a square n×n matrix. Sizes are the matrix dimension n."

def gerImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → FloatArray → FloatArray)) := [
  { id := "lean.floatArrayGer.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArrayGer/Implementations.lean"
    symbol := "floatArrayGer.usize_loop"
    run := floatArrayGer.usize_loop },
  { id := "lean.floatArrayGer.usize_rec_uget"
    language := "lean"
    name := "Lean usize_rec_uget"
    sourceFile := "NumLeanPerf/FloatArrayGer/Implementations.lean"
    symbol := "floatArrayGer.usize_rec_uget"
    run := floatArrayGer.usize_rec_uget },
  { id := "lean.floatArrayGer.usize_rec_uget_bound"
    language := "lean"
    name := "Lean usize_rec_uget_bound"
    sourceFile := "NumLeanPerf/FloatArrayGer/Implementations.lean"
    symbol := "floatArrayGer.usize_rec_uget_bound"
    run := floatArrayGer.usize_rec_uget_bound },
  { id := "lean.floatArrayGer.usize_range_uget"
    language := "lean"
    name := "Lean usize_range_uget"
    sourceFile := "NumLeanPerf/FloatArrayGer/Implementations.lean"
    symbol := "floatArrayGer.usize_range_uget"
    run := floatArrayGer.usize_range_uget },
  { id := "lean.floatArrayGer.usize_range_unsafe_set"
    language := "lean"
    name := "Lean usize_range_unsafe_set"
    sourceFile := "NumLeanPerf/FloatArrayGer/Implementations.lean"
    symbol := "floatArrayGer.usize_range_unsafe_set"
    run := floatArrayGer.usize_range_unsafe_set },
  { id := "c.floatArrayGer.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArrayGer/float_array_ger.c"
    symbol := "lean_float_array_ger"
    run := floatArrayGer.c_loop }
]

def gerImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray → FloatArray) :=
  (gerImplementations.find? (fun e => e.id == name)).map (·.run)

-- Sizes are matrix dimensions n; batchSizeExponent=2 calibrates batch for O(n²) work per call
def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayGerBenchmarkId floatArrayGerBenchmarkName
      floatArrayGerBenchmarkDescription gerImplementations
      [64, 128, 256, 512, 1024, 2048] 2)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-ger-bench <implementation> <matrix-elements> <samples> <warmups> <batch-size>"; return 2
  let some sizeArg := parseNatArg? args 1
    | IO.eprintln "invalid matrix-elements"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := gerImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let n := sizeArg
  let poolSize := inputPoolSize samples warmups
  let matInputs := mkFloatArrayInputs poolSize (n * n)
  let xInputs := mkFloatArrayInputs poolSize n
  let yInputs := mkFloatArrayInputs poolSize n 1.0
  printTimingLines samples warmups batchSize (fun i =>
    let p := i % poolSize
    pure (fingerprintFloatArray (impl matInputs[p]! xInputs[p]! yInputs[p]!)))
  return 0
