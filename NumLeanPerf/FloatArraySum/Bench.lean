import NumLeanPerf.Benchmark.Common

def floatArraySumBenchmarkId := "float-array-sum"
def floatArraySumBenchmarkName := "FloatArray sum"
def floatArraySumBenchmarkDescription := "Sum all elements of one FloatArray."

def sumImplementations : List (BenchmarkImplementation (FloatArray → Float)) := [
  {
    id := "lean.floatArraySum.nat_rec"
    language := "lean"
    name := "Lean nat_rec"
    sourceFile := "NumLeanPerf/FloatArraySum/Implementations.lean"
    symbol := "floatArraySum.nat_rec"
    run := floatArraySum.nat_rec
  },
  {
    id := "lean.floatArraySum.usize_rec"
    language := "lean"
    name := "Lean usize_rec"
    sourceFile := "NumLeanPerf/FloatArraySum/Implementations.lean"
    symbol := "floatArraySum.usize_rec"
    run := floatArraySum.usize_rec
  },
  {
    id := "lean.floatArraySum.foreach_loop"
    language := "lean"
    name := "Lean foreach_loop"
    sourceFile := "NumLeanPerf/FloatArraySum/Implementations.lean"
    symbol := "floatArraySum.foreach_loop"
    run := floatArraySum.foreach_loop
  },
  {
    id := "lean.floatArraySum.nat_loop"
    language := "lean"
    name := "Lean nat_loop"
    sourceFile := "NumLeanPerf/FloatArraySum/Implementations.lean"
    symbol := "floatArraySum.nat_loop"
    run := floatArraySum.nat_loop
  },
  {
    id := "lean.floatArraySum.usize_loop_get!"
    language := "lean"
    name := "Lean usize_loop_get!"
    sourceFile := "NumLeanPerf/FloatArraySum/Implementations.lean"
    symbol := "floatArraySum.usize_loop_get!"
    run := floatArraySum.usize_loop_get!
  },
  {
    id := "c.floatArraySum.loop"
    language := "c"
    name := "C double loop"
    sourceFile := "NumLeanPerf/FloatArraySum/float_array_sum.c"
    symbol := "lean_float_array_sum"
    run := floatArraySum.c_loop
  }
]

def sumImplementation? (name : String) : Option (FloatArray → Float) :=
  (sumImplementations.find? (fun entry => entry.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata floatArraySumBenchmarkId floatArraySumBenchmarkName floatArraySumBenchmarkDescription sumImplementations)
    return 0
  let some implName := args[0]?
    | IO.eprintln "usage: float-array-sum-bench <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := sumImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let inputs := mkFloatArrayInputs poolSize n
  printTimingLines samples warmups batchSize (fun i => pure (impl inputs[i % poolSize]!))
  return 0
