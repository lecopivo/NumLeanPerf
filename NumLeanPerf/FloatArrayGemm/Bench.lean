import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayGemm.Implementations

def floatArrayGemmBenchmarkId := "float-array-gemm"
def floatArrayGemmBenchmarkName := "FloatArray gemm"
def floatArrayGemmBenchmarkDescription :=
  "C <- A*B + C (BLAS gemm, alpha=1, beta=1) for square n×n matrices. Sizes are the matrix dimension n."

def gemmImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → FloatArray → FloatArray)) := [
  { id := "lean.floatArrayGemm.nat_loop"
    language := "lean"
    name := "Lean nat_loop"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.nat_loop"
    run := floatArrayGemm.nat_loop },
  { id := "lean.floatArrayGemm.usize_loop"
    language := "lean"
    name := "Lean usize_loop"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_loop"
    run := floatArrayGemm.usize_loop },
  { id := "c.floatArrayGemm.loop"
    language := "c"
    name := "C loop"
    sourceFile := "NumLeanPerf/FloatArrayGemm/float_array_gemm.c"
    symbol := "lean_float_array_gemm"
    run := floatArrayGemm.c_loop }
]

def gemmImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray → FloatArray) :=
  (gemmImplementations.find? (fun e => e.id == name)).map (·.run)

-- Sizes are matrix dimensions n; batchSizeExponent=3 calibrates batch for O(n³) work per call
def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayGemmBenchmarkId floatArrayGemmBenchmarkName
      floatArrayGemmBenchmarkDescription gemmImplementations
      [16, 32, 64, 128, 256] 3)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-gemm-bench <implementation> <matrix-elements> <samples> <warmups> <batch-size>"; return 2
  let some sizeArg := parseNatArg? args 1
    | IO.eprintln "invalid matrix-elements"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := gemmImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let n := sizeArg
  let poolSize := inputPoolSize samples warmups
  let aInputs := mkFloatArrayInputs poolSize (n * n)
  let bInputs := mkFloatArrayInputs poolSize (n * n) 1.0
  let cInputs := mkFloatArrayInputs poolSize (n * n) 2.0
  printTimingLines samples warmups batchSize (fun i =>
    let p := i % poolSize
    pure (fingerprintFloatArray (impl aInputs[p]! bInputs[p]! cInputs[p]!)))
  return 0
