# NumLeanPerf

Benchmarks for comparing Lean numeric code with native C baselines.

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

After enabling GitHub Pages for Actions in the repository settings, the site will be available at:

```text
https://<owner>.github.io/<repo>/benchmarks/site/
```
