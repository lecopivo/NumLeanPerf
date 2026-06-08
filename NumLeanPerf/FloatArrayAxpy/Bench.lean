import NumLeanPerf.Benchmark.Common
import NumLeanPerf.FloatArrayAxpy.Implementations

def floatArrayAxpyBenchmarkId := "float-array-axpy"
def floatArrayAxpyBenchmarkName := "FloatArray axpy"
def floatArrayAxpyBenchmarkDescription := "BLAS operation axpy, `y <- y + a * x`."

def axpyImplementations : List (BenchmarkImplementation (FloatArray → FloatArray → FloatArray)) := [
  {
    id := "lean.floatArrayAxpy.loop_uset"
    language := "lean"
    name := "Lean loop_uset"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.loop_uset"
    run := floatArrayAxpy.loop_uset 1.234
  },
  {
    id := "lean.floatArrayAxpy.loop_fset"
    language := "lean"
    name := "Lean loop_fset"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.loop_fset"
    run := floatArrayAxpy.loop_fset 1.234
  },
  {
    id := "lean.floatArrayAxpy.loop_set"
    language := "lean"
    name := "Lean loop_set"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.loop_set"
    run := floatArrayAxpy.loop_set 1.234
  },
  {
    id := "lean.floatArrayAxpy.usize_range_uset"
    language := "lean"
    name := "Lean usize_range_uset"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.usize_range_uset"
    run := floatArrayAxpy.usize_range_uset 1.234
  },
  {
    id := "lean.floatArrayAxpy.usize_range_unsafe_set"
    language := "lean"
    name := "Lean usize_range_unsafe_set"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.usize_range_unsafe_set"
    run := floatArrayAxpy.usize_range_unsafe_set 1.234
  },
  {
    id := "lean.floatArrayAxpy.while_uset"
    language := "lean"
    name := "Lean while_uset"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.while_uset"
    run := floatArrayAxpy.while_uset 1.234
  },
  {
    id := "lean.floatArrayAxpy.while_custom_state"
    language := "lean"
    name := "Lean while_custom_state"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/Implementations.lean"
    symbol := "floatArrayAxpy.while_custom_state"
    run := floatArrayAxpy.while_custom_state 1.234
  },
  {
    id := "c.floatArrayAxpy.loop"
    language := "c"
    name := "C loop via Lean FFI"
    sourceFile := "NumLeanPerf/FloatArrayAxpy/float_array_axpy.c"
    symbol := "lean_float_array_axpy"
    run := floatArrayAxpy.c_loop 1.234
  }
]

def axpyImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray) :=
  (axpyImplementations.find? (fun entry => entry.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArrayAxpyBenchmarkId floatArrayAxpyBenchmarkName floatArrayAxpyBenchmarkDescription axpyImplementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-axpy-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := axpyImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let xsInputs := mkFloatArrayInputs poolSize n
  let ysInputs := mkFloatArrayInputs poolSize n 1.0
  printTimingLines samples warmups batchSize (fun i => pure (fingerprintFloatArray (impl xsInputs[i % poolSize]! ysInputs[i % poolSize]!)))
  return 0
