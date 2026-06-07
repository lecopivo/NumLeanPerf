import NumLeanPerf.Bench.FloatArrayCommon
import NumLeanPerf.FloatArrayAdd

def addImplementation? (name : String) : Option (FloatArray → FloatArray → FloatArray) :=
  match name with
  | "lean.floatArrayAdd.nat_loop_get!" => some floatArrayAdd.nat_loop_get!
  | "lean.floatArrayAdd.usize_loop_get!" => some floatArrayAdd.usize_loop_get!
  | "lean.floatArrayAdd.foreach_zip" => some floatArrayAdd.foreach_zip
  | _ => none

def main (args : List String) : IO UInt32 := do
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
  printTimingLines samples warmups batchSize (fun i => pure (sumFloatArray (impl xsInputs[i % poolSize]! ysInputs[i % poolSize]!)))
  return 0
