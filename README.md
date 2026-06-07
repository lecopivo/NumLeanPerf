# NumLeanPerf

Benchmarks for comparing Lean numeric code with native C baselines.

## Layout

Each benchmark lives in its own directory under `NumLeanPerf/`:

```text
NumLeanPerf/FloatArraySum/
  Implementations.lean
  Bench.lean
  float_array_sum.c
```

Generic benchmark infrastructure lives outside benchmark directories:

```text
NumLeanPerf/Benchmark/Common.lean
benchmarks/run.py
benchmarks/site/
benchmarks/results/
```

`benchmarks/run.py` discovers benchmarks by finding `NumLeanPerf/*/Bench.lean`. New benchmarks should not require edits to `benchmarks/run.py` or the website.

Lake recursively compiles every `.c` file under `NumLeanPerf/` into one static library and links it into the Lean executables. C implementations are called directly from Lean using `@[extern]`; there is no separate C benchmark executable or C harness.

## Build

Build the library, example executable, and benchmark executables:

```sh
lake build
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
- C implementations are called through Lean FFI and timed by the same Lean harness as Lean implementations.
- `FloatArrayAdd` measures construction of the output array. It does not intentionally measure an extra full traversal of the output array.

## Add A Benchmark

Create a new directory under `NumLeanPerf/`, for example:

```text
NumLeanPerf/MyBenchmark/
  Implementations.lean
  Bench.lean
  my_benchmark.c
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

def myBenchmarkId := "my-benchmark"
def myBenchmarkName := "My benchmark"
def myBenchmarkDescription := "What this benchmark measures."

def myBenchmarkImplementations : List (BenchmarkImplementation (FloatArray → Float)) := [
  { id := "lean.myBenchmark.version1", language := "lean", name := "Lean version1", sourceFile := "NumLeanPerf/MyBenchmark/Implementations.lean", symbol := "myBenchmark.version1", run := myBenchmark.version1 },
  { id := "lean.myBenchmark.version2", language := "lean", name := "Lean version2", sourceFile := "NumLeanPerf/MyBenchmark/Implementations.lean", symbol := "myBenchmark.version2", run := myBenchmark.version2 }
]

def myBenchmarkImplementation? (name : String) : Option (FloatArray → Float) :=
  (myBenchmarkImplementations.find? (fun entry => entry.id == name)).map (·.run)

def main (args : List String) : IO UInt32 := do
  if args[0]? == some "--metadata" then
    IO.println (renderBenchmarkMetadata myBenchmarkId myBenchmarkName myBenchmarkDescription myBenchmarkImplementations)
    return 0

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

The small `Bench.lean` file is benchmark-specific because Lean implementation types differ between tests. The timing loop, batching, input generation, parsing, metadata rendering, and output protocol are generic.

Add a Lake executable stanza for the new harness in `lakefile.lean`:

```lean
lean_exe «my-benchmark» where
  root := `NumLeanPerf.MyBenchmark.Bench
```

### C Implementation Via Lean FFI

Put the C baseline in the same benchmark directory. Lake automatically compiles `.c` files under `NumLeanPerf/` and links them into the Lean benchmark executables.

In Lean, declare the C function as another implementation:

```lean
@[extern "lean_my_benchmark_loop"]
opaque myBenchmark.c_loop (xs : @& FloatArray) : Float
```

For an implementation returning a `FloatArray`, use Lean ownership annotations to match the C calling convention. A borrowed input uses `@&`; an owned/mutable input omits it:

```lean
@[extern "lean_my_benchmark_axpy"]
opaque myBenchmark.c_axpy (a : Float) (x : @& FloatArray) (y : FloatArray) : FloatArray
```

Then include it in the implementation list in `Bench.lean`:

```lean
def myBenchmarkImplementations : List (BenchmarkImplementation (FloatArray → Float)) := [
  { id := "lean.myBenchmark.version1", language := "lean", name := "Lean version1", sourceFile := "NumLeanPerf/MyBenchmark/Implementations.lean", symbol := "myBenchmark.version1", run := myBenchmark.version1 },
  { id := "c.myBenchmark.loop", language := "c", name := "C loop", sourceFile := "NumLeanPerf/MyBenchmark/my_benchmark.c", symbol := "lean_my_benchmark_loop", run := myBenchmark.c_loop }
]
```

In C, include Lean's runtime header directly:

```c
#include <lean/lean.h>
```

For a borrowed `FloatArray` returning `Float`:

```c
double lean_my_benchmark_loop(b_lean_obj_arg xs) {
  size_t n = lean_sarray_size(xs);
  const double *xp = lean_float_array_cptr(xs);
  double s = 0.0;
  for (size_t i = 0; i < n; i++) {
    s += xp[i];
  }
  return s;
}
```

For an operation that mutates or copies an owned `FloatArray` result:

```c
lean_obj_res lean_my_benchmark_axpy(double a, b_lean_obj_arg x, lean_obj_arg y) {
  lean_obj_res r;
  if (lean_is_exclusive(y)) {
    r = y;
  } else {
    r = lean_copy_float_array(y);
  }

  size_t n = lean_sarray_size(r);
  const double *xp = lean_float_array_cptr(x);
  double *rp = lean_float_array_cptr(r);
  for (size_t i = 0; i < n; i++) {
    rp[i] = rp[i] + a * xp[i];
  }
  return r;
}
```

Useful Lean runtime APIs from `lean.h`:

- `lean_sarray_size(a)` gets the length of a `FloatArray`.
- `lean_float_array_cptr(a)` gets the raw `double*` data pointer.
- `lean_is_exclusive(a)` checks whether destructive update is safe.
- `lean_copy_float_array(a)` copies a non-exclusive `FloatArray`.

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

Click a graph legend item or measurement table row to use that implementation as a relative baseline. The graph then displays every implementation as a multiple of the baseline at the same array size. Click the same implementation again or **Clear baseline** to return to absolute time. The selected baseline is stored in the URL as `baseline=<implementation-id>`.
