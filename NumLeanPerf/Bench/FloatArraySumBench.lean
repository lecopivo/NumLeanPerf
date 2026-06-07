import NumLeanPerf.Bench.FloatArrayCommon

def sumImplementation? (name : String) : Option (FloatArray → Float) :=
  match name with
  | "lean.floatArraySum.nat_rec" => some floatArraySum.nat_rec
  | "lean.floatArraySum.usize_rec" => some floatArraySum.usize_rec
  | "lean.floatArraySum.foreach_loop" => some floatArraySum.foreach_loop
  | "lean.floatArraySum.nat_loop" => some floatArraySum.nat_loop
  | "lean.floatArraySum.usize_loop_get!" => some floatArraySum.usize_loop_get!
  | _ => none

def main (args : List String) : IO UInt32 := do
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
