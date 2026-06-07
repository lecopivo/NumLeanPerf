# NumLeanPerf

Benchmarks for comparing Lean numeric code with native C baselines.

## Layout

Each benchmark lives in its own directory under `NumLeanPerf/`:

```text
NumLeanPerf/FloatArraySum/
  Implementations.lean
  Bench.lean
  float_array_sum.c
  benchmark.json
```

Generic benchmark infrastructure lives outside benchmark directories:

```text
NumLeanPerf/Benchmark/Common.lean
NumLeanPerf/Benchmark/benchmark.h
benchmarks/run.py
benchmarks/site/
benchmarks/results/
```

`benchmarks/run.py` discovers benchmarks by reading `NumLeanPerf/*/benchmark.json`. New benchmarks should not require edits to `benchmarks/run.py` or the website.

## Build

Build the library, example executable, and benchmark executables:

```sh
lake build NumLeanPerf numleanperf float-array-sum-bench float-array-add-bench
```

## Run Benchmarks

Run all benchmark cases with the default sizes, samples, and warmups:

```sh
benchmarks/run.py
```

Run a smaller smoke test:

```sh
python3 benchmarks/run.py --sizes 1000 10000 --samples 5 --warmups 2
```

Run the large preset, which goes up to `1_000_000_000` elements:

```sh
python3 benchmarks/run.py --size-preset large --samples 3 --warmups 1
```

For very large sizes, run one benchmark case at a time if memory is tight:

```sh
python3 benchmarks/run.py --benchmark float-array-sum --sizes 100000000 1000000000 --samples 3 --warmups 1
python3 benchmarks/run.py --benchmark float-array-add --sizes 100000000 --samples 3 --warmups 1
```

`FloatArrayAdd` allocates an output array for each measured run. At `1_000_000_000` elements, the add benchmark can require tens of GB of memory, especially in Lean, so prefer running it separately on a machine with enough RAM.

Run one benchmark case:

```sh
python3 benchmarks/run.py --benchmark float-array-sum
python3 benchmarks/run.py --benchmark float-array-add
```

Each run writes a timestamped JSON file to `benchmarks/results/` and updates `benchmarks/results/index.json`. The JSON is versioned with `schemaVersion` and includes environment metadata such as OS, CPU, memory, Lean/Lake versions, C compiler, C flags, git commit, and dirty status.

Small inputs are measured in batches to avoid timer-resolution artifacts. The JSON stores per-call times in seconds and records the `batchSize` used for each result.

Measurement safeguards:

- Process startup and input construction are outside the timed region.
- Each sample times a batch and divides by `batchSize`, which avoids zero-duration samples for small inputs.
- Outputs are consumed so implementations cannot be eliminated as dead code.
- C benchmarks use compiler memory barriers around measured arrays to prevent hoisting or store elimination.
- `FloatArrayAdd` measures construction of the output array. It does not intentionally measure an extra full traversal of the output array.

## Add A Benchmark

Create a new directory under `NumLeanPerf/`, for example:

```text
NumLeanPerf/MyBenchmark/
  Implementations.lean
  Bench.lean
  my_benchmark.c
  benchmark.json
```

### Lean Implementations

Put all Lean versions in `Implementations.lean`:

```lean
def myBenchmark.version1 (xs : FloatArray) : Float :=
  -- implementation
  0.0

def myBenchmark.version2 (xs : FloatArray) : Float :=
  -- implementation
  0.0
```

### Lean Harness

Put the typed benchmark harness in `Bench.lean`. Reuse the generic helpers from `NumLeanPerf.Benchmark.Common`:

```lean
import NumLeanPerf.Benchmark.Common
import NumLeanPerf.MyBenchmark.Implementations

def myBenchmarkImplementations : List (String × (FloatArray → Float)) := [
  ("lean.myBenchmark.version1", myBenchmark.version1),
  ("lean.myBenchmark.version2", myBenchmark.version2)
]

def myBenchmarkImplementation? (name : String) : Option (FloatArray → Float) :=
  (myBenchmarkImplementations.find? (fun entry => entry.fst == name)).map Prod.snd

def main (args : List String) : IO UInt32 := do
  let some implName := args[0]?
    | IO.eprintln "usage: my-benchmark <implementation> <array-size> <samples> <warmups> <batch-size>"; return 2
  let some n := parseNatArg? args 1
    | IO.eprintln "invalid array-size"; return 2
  let some samples := parseNatArg? args 2
    | IO.eprintln "invalid samples"; return 2
  let some warmups := parseNatArg? args 3
    | IO.eprintln "invalid warmups"; return 2
  let some batchSize := parseNatArg? args 4
    | IO.eprintln "invalid batch-size"; return 2
  let some impl := myBenchmarkImplementation? implName
    | IO.eprintln s!"unknown implementation: {implName}"; return 2

  let poolSize := inputPoolSize samples warmups
  let inputs := mkFloatArrayInputs poolSize n
  printTimingLines samples warmups batchSize (fun i => pure (impl inputs[i % poolSize]!))
  return 0
```

The small `Bench.lean` file is benchmark-specific because Lean implementation types differ between tests. The timing loop, batching, input generation, parsing, and output protocol are generic.

Add a Lake executable stanza for the new harness:

```toml
[[lean_exe]]
name = "my-benchmark"
root = "NumLeanPerf.MyBenchmark.Bench"
```

### C Implementation

Put the C baseline in the same benchmark directory and include the shared helper header:

```c
#include "NumLeanPerf/Benchmark/benchmark.h"
```

The C executable must accept the same protocol as Lean:

```text
<implementation> <array-size> <samples> <warmups> <batch-size>
```

For each measured sample, print one integer line: elapsed nanoseconds for the whole batch. `benchmarks/run.py` divides by `batchSize` and converts to seconds.

Use `numleanperf_now_nanos`, `numleanperf_parse_size`, and `numleanperf_black_box_array` from `benchmark.h` to keep timing and optimization barriers consistent.

### benchmark.json

Describe the benchmark in `benchmark.json`:

```json
{
  "id": "my-benchmark",
  "name": "My benchmark",
  "description": "What this benchmark measures.",
  "leanExe": "my-benchmark",
  "cSource": "NumLeanPerf/MyBenchmark/my_benchmark.c",
  "cExeName": "my-benchmark-c",
  "inputAxes": [
    { "id": "arraySize", "name": "Array size", "unit": "elements" }
  ],
  "implementations": [
    {
      "id": "lean.myBenchmark.version1",
      "language": "lean",
      "name": "Lean version1",
      "sourceFile": "NumLeanPerf/MyBenchmark/Implementations.lean",
      "symbol": "myBenchmark.version1"
    },
    {
      "id": "c.myBenchmark.loop",
      "language": "c",
      "name": "C loop",
      "sourceFile": "NumLeanPerf/MyBenchmark/my_benchmark.c",
      "symbol": "my_benchmark_loop"
    }
  ]
}
```

After that, the generic runner can discover it:

```sh
python3 benchmarks/run.py --benchmark my-benchmark
```

## View Results

The static viewer is in `benchmarks/site/`. It uses Chart.js from a CDN, so it needs internet access unless Chart.js is vendored locally later.

Serve the repository over HTTP and open the site:

```sh
python3 -m http.server 8000
```

Then visit `http://localhost:8000/benchmarks/site/`.

The viewer loads `benchmarks/results/index.json`, lets you choose a run and benchmark, plots mean time against array size for each implementation, and shows implementation code/details when hovering graph points or table rows.

## GitHub Pages

The GitHub workflow builds the Lean project on pushes, pull requests, and manual runs. On pushes to `main` or `master`, it publishes the committed static site and committed result JSON files to GitHub Pages.

Benchmarks are not run in CI. Run benchmarks manually on the target machine, commit the generated files under `benchmarks/results/`, and push. The next Pages deployment will publish those results.

After enabling GitHub Pages for Actions in the repository settings, the site is available at:

```text
https://lecopivo.github.io/NumLeanPerf/benchmarks/site/
```

The viewer stores the selected benchmark, run/date, size, and table sort in the URL. You can share a specific view by copying the browser URL, for example:

```text
https://lecopivo.github.io/NumLeanPerf/benchmarks/site/?benchmark=float-array-sum&run=2026-06-07T194105Z&size=1000&sort=mean&dir=asc&errors=1
```

The graph can show error bars for `mean ± stddev`. Toggle them with the **Error bars** checkbox. The checkbox state is also stored in the URL as `errors=1` or `errors=0`.
