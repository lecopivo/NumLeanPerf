import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayGemm.Implementations

def floatArrayGemmBenchmarkId := "float-array-gemm"
def floatArrayGemmBenchmarkName := "FloatArray gemm"
def floatArrayGemmBenchmarkDescription :=
  "C <- A*B + C (BLAS gemm, alpha=1, beta=1) for square n×n matrices. Sizes are the matrix dimension n."

def gemmImplementations : List (BenchmarkImplementation (USize → FloatArray → FloatArray → FloatArray → FloatArray)) := [
  { id := "lean.floatArrayGemm.usize_loop_ijk"
    language := "lean"
    name := "Lean usize ijk"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_loop_ijk"
    run := floatArrayGemm.usize_loop_ijk },
  { id := "lean.floatArrayGemm.usize_loop_ikj"
    language := "lean"
    name := "Lean usize ikj"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_loop_ikj"
    run := floatArrayGemm.usize_loop_ikj },
  { id := "lean.floatArrayGemm.usize_rec_ijk_uget"
    language := "lean"
    name := "Lean usize rec ijk uget"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_rec_ijk_uget"
    run := floatArrayGemm.usize_rec_ijk_uget },
  { id := "lean.floatArrayGemm.usize_rec_ikj_uget"
    language := "lean"
    name := "Lean usize rec ikj uget"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_rec_ikj_uget"
    run := floatArrayGemm.usize_rec_ikj_uget },
  { id := "lean.floatArrayGemm.usize_range_ijk_uget"
    language := "lean"
    name := "Lean usize range ijk uget"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_range_ijk_uget"
    run := floatArrayGemm.usize_range_ijk_uget },
  { id := "lean.floatArrayGemm.usize_range_ikj_uget"
    language := "lean"
    name := "Lean usize range ikj uget"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_range_ikj_uget"
    run := floatArrayGemm.usize_range_ikj_uget },
  { id := "lean.floatArrayGemm.usize_range_ijk_unsafe_set"
    language := "lean"
    name := "Lean usize range ijk unsafe_set"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_range_ijk_unsafe_set"
    run := floatArrayGemm.usize_range_ijk_unsafe_set },
  { id := "lean.floatArrayGemm.usize_range_ikj_unsafe_set"
    language := "lean"
    name := "Lean usize range ikj unsafe_set"
    sourceFile := "NumLeanPerf/FloatArrayGemm/Implementations.lean"
    symbol := "floatArrayGemm.usize_range_ikj_unsafe_set"
    run := floatArrayGemm.usize_range_ikj_unsafe_set },
  { id := "c.floatArrayGemm.loop_ijk"
    language := "c"
    name := "C ijk"
    sourceFile := "NumLeanPerf/FloatArrayGemm/float_array_gemm.c"
    symbol := "lean_float_array_gemm_ijk"
    run := floatArrayGemm.c_loop_ijk },
  { id := "c.floatArrayGemm.loop_ikj"
    language := "c"
    name := "C ikj"
    sourceFile := "NumLeanPerf/FloatArrayGemm/float_array_gemm.c"
    symbol := "lean_float_array_gemm_ikj"
    run := floatArrayGemm.c_loop_ikj }
]

def gemmImplementation? (name : String) : Option (USize → FloatArray → FloatArray → FloatArray → FloatArray) :=
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
    pure (fingerprintFloatArray (impl n.toUSize aInputs[p]! bInputs[p]! cInputs[p]!)))
  return 0
