#!/usr/bin/env python3
import argparse
import json
import math
import os
import platform
import re
import statistics
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "benchmarks" / "results"
BIN_DIR = ROOT / "benchmarks" / "bin"
CFLAGS = ["-O3", "-march=native"]
SIZE_PRESETS = {
    "default": [1000, 10000, 100000, 1000000, 10000000],
    "large": [1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000],
}


BENCHMARKS = {
    "float-array-sum": {
        "name": "FloatArray sum",
        "description": "Sum all elements of one FloatArray.",
        "leanExe": "float-array-sum-bench",
        "cSource": ROOT / "benchmarks" / "c" / "float_array_sum.c",
        "cExe": BIN_DIR / "float-array-sum-c-bench",
        "inputAxes": [{"id": "arraySize", "name": "Array size", "unit": "elements"}],
        "implementations": [
            {
                "id": "lean.floatArraySum.nat_rec",
                "language": "lean",
                "name": "Lean nat_rec",
                "sourceFile": "NumLeanPerf/FloatArraySum.lean",
                "symbol": "floatArraySum.nat_rec",
            },
            {
                "id": "lean.floatArraySum.usize_rec",
                "language": "lean",
                "name": "Lean usize_rec",
                "sourceFile": "NumLeanPerf/FloatArraySum.lean",
                "symbol": "floatArraySum.usize_rec",
            },
            {
                "id": "lean.floatArraySum.foreach_loop",
                "language": "lean",
                "name": "Lean foreach_loop",
                "sourceFile": "NumLeanPerf/FloatArraySum.lean",
                "symbol": "floatArraySum.foreach_loop",
            },
            {
                "id": "lean.floatArraySum.nat_loop",
                "language": "lean",
                "name": "Lean nat_loop",
                "sourceFile": "NumLeanPerf/FloatArraySum.lean",
                "symbol": "floatArraySum.nat_loop",
            },
            {
                "id": "lean.floatArraySum.usize_loop_get!",
                "language": "lean",
                "name": "Lean usize_loop_get!",
                "sourceFile": "NumLeanPerf/FloatArraySum.lean",
                "symbol": "floatArraySum.usize_loop_get!",
            },
            {
                "id": "c.floatArraySum.loop",
                "language": "c",
                "name": "C double loop",
                "sourceFile": "benchmarks/c/float_array_sum.c",
                "symbol": "float_array_sum_loop",
            },
        ],
    },
    "float-array-add": {
        "name": "FloatArray add",
        "description": "Elementwise add two FloatArrays and return a new array.",
        "leanExe": "float-array-add-bench",
        "cSource": ROOT / "benchmarks" / "c" / "float_array_add.c",
        "cExe": BIN_DIR / "float-array-add-c-bench",
        "inputAxes": [{"id": "arraySize", "name": "Array size", "unit": "elements"}],
        "implementations": [
            {
                "id": "lean.floatArrayAdd.nat_loop_get!",
                "language": "lean",
                "name": "Lean nat_loop_get!",
                "sourceFile": "NumLeanPerf/FloatArrayAdd.lean",
                "symbol": "floatArrayAdd.nat_loop_get!",
            },
            {
                "id": "lean.floatArrayAdd.usize_loop_get!",
                "language": "lean",
                "name": "Lean usize_loop_get!",
                "sourceFile": "NumLeanPerf/FloatArrayAdd.lean",
                "symbol": "floatArrayAdd.usize_loop_get!",
            },
            {
                "id": "lean.floatArrayAdd.foreach_zip",
                "language": "lean",
                "name": "Lean foreach_zip",
                "sourceFile": "NumLeanPerf/FloatArrayAdd.lean",
                "symbol": "floatArrayAdd.foreach_zip",
            },
            {
                "id": "c.floatArrayAdd.malloc_loop",
                "language": "c",
                "name": "C double malloc_loop",
                "sourceFile": "benchmarks/c/float_array_add.c",
                "symbol": "float_array_add_malloc_loop",
            },
        ],
    },
}


def run(cmd, *, check=True):
    completed = subprocess.run(
        cmd,
        cwd=ROOT,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def run_optional(cmd):
    try:
        return run(cmd)
    except Exception:
        return None


def first_line(text):
    if not text:
        return None
    return text.splitlines()[0]


def cpu_model():
    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.exists():
        for line in cpuinfo.read_text(errors="replace").splitlines():
            if line.lower().startswith("model name"):
                return line.split(":", 1)[1].strip()
    return platform.processor() or None


def memory_total():
    meminfo = Path("/proc/meminfo")
    if meminfo.exists():
        for line in meminfo.read_text(errors="replace").splitlines():
            if line.startswith("MemTotal:"):
                parts = line.split()
                if len(parts) >= 2:
                    return {"bytes": int(parts[1]) * 1024, "text": line.split(":", 1)[1].strip()}
    return None


def environment(command):
    return {
        "os": platform.platform(),
        "kernel": platform.release(),
        "machine": platform.machine(),
        "cpu": cpu_model(),
        "cpuLogicalCores": os.cpu_count(),
        "memory": memory_total(),
        "lean": first_line(run_optional(["lean", "--version"])),
        "lake": first_line(run_optional(["lake", "--version"])),
        "cCompiler": first_line(run_optional(["cc", "--version"])),
        "cFlags": " ".join(CFLAGS),
        "gitCommit": run_optional(["git", "rev-parse", "HEAD"]),
        "gitDirty": (run_optional(["git", "status", "--porcelain"]) or "") != "",
        "command": command,
    }


def source_code(source_file):
    path = ROOT / source_file
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return None


def extract_lean_definition(source, symbol):
    lines = source.splitlines()
    start = None
    pattern = re.compile(rf"^(?:partial\s+)?def\s+{re.escape(symbol)}(?:\s|\(|:)")
    for idx, line in enumerate(lines):
        if pattern.match(line):
            start = idx
            break
    if start is None:
        return source

    end = len(lines)
    next_decl = re.compile(r"^(?:partial\s+)?def\s+")
    for idx in range(start + 1, len(lines)):
        if next_decl.match(lines[idx]):
            end = idx
            break
    return "\n".join(lines[start:end]).rstrip() + "\n"


def extract_c_function(source, symbol):
    lines = source.splitlines()
    start = None
    for idx, line in enumerate(lines):
        if re.search(rf"\b{re.escape(symbol)}\s*\(", line):
            start = idx
            break
    if start is None:
        return source

    brace_depth = 0
    seen_open = False
    end = len(lines)
    for idx in range(start, len(lines)):
        brace_depth += lines[idx].count("{")
        if "{" in lines[idx]:
            seen_open = True
        brace_depth -= lines[idx].count("}")
        if seen_open and brace_depth == 0:
            end = idx + 1
            break
    return "\n".join(lines[start:end]).rstrip() + "\n"


def implementation_code(impl):
    source = source_code(impl["sourceFile"])
    if source is None:
        return None
    symbol = impl.get("symbol")
    if not symbol:
        return source
    if impl["language"] == "lean":
        return extract_lean_definition(source, symbol)
    if impl["language"] == "c":
        return extract_c_function(source, symbol)
    return source


def build_targets(selected):
    BIN_DIR.mkdir(parents=True, exist_ok=True)
    for bench_id in selected:
        bench = BENCHMARKS[bench_id]
        run(["lake", "build", bench["leanExe"]])
        run(["cc", *CFLAGS, "-std=c11", str(bench["cSource"]), "-lm", "-o", str(bench["cExe"])])


def executable_for(bench, impl):
    if impl["language"] == "lean":
        return ROOT / ".lake" / "build" / "bin" / bench["leanExe"]
    if impl["language"] == "c":
        return bench["cExe"]
    raise ValueError(f"unsupported language: {impl['language']}")


def parse_timings(stdout, expected_count, batch_size):
    values = []
    for line in stdout.splitlines():
      line = line.strip()
      if line:
          values.append(float(line) / 1_000_000_000.0 / batch_size)
    if len(values) != expected_count:
        raise RuntimeError(f"expected {expected_count} timing lines, got {len(values)}")
    return values


def summarize(values):
    return {
        "mean": statistics.fmean(values),
        "stddev": statistics.stdev(values) if len(values) > 1 else 0.0,
        "min": min(values),
        "max": max(values),
    }


def batch_size_for(size):
    if size <= 0:
        return 1
    return max(1, min(10000, math.ceil(10_000_000 / size)))


def safe_timestamp(value):
    return re.sub(r"[^0-9A-Za-z-]", "", value.replace(":", ""))


def run_benchmarks(selected, sizes, samples, warmups):
    results = []
    implementation_records = []

    for bench_id in selected:
        bench = BENCHMARKS[bench_id]
        for impl in bench["implementations"]:
            impl_record = dict(impl)
            impl_record["benchmarkId"] = bench_id
            impl_record["code"] = implementation_code(impl)
            implementation_records.append(impl_record)

        for size in sizes:
            batch_size = batch_size_for(size)
            for impl in bench["implementations"]:
                exe = executable_for(bench, impl)
                stdout = run([str(exe), impl["id"], str(size), str(samples), str(warmups), str(batch_size)])
                timings = parse_timings(stdout, samples, batch_size)
                summary = summarize(timings)
                results.append(
                    {
                        "benchmarkId": bench_id,
                        "implementationId": impl["id"],
                        "inputs": {"arraySize": size},
                        "unit": "seconds",
                        **summary,
                        "samples": samples,
                        "warmups": warmups,
                        "batchSize": batch_size,
                        "rawSamples": timings,
                    }
                )
                print(f"{bench_id} {impl['id']} n={size} batch={batch_size} mean={summary['mean']:.6g}s")

    return implementation_records, results


def write_index(entry):
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    index_path = RESULTS_DIR / "index.json"
    if index_path.exists():
        index = json.loads(index_path.read_text())
    else:
        index = {"schemaVersion": 1, "runs": []}
    index["schemaVersion"] = 1
    runs = [run for run in index.get("runs", []) if run.get("file") != entry["file"]]
    runs.append(entry)
    runs.sort(key=lambda run: run.get("createdAt", ""), reverse=True)
    index["runs"] = runs
    index_path.write_text(json.dumps(index, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Run NumLeanPerf benchmarks and write versioned JSON results.")
    parser.add_argument("--benchmark", action="append", choices=sorted(BENCHMARKS), help="Benchmark id to run. Defaults to all.")
    parser.add_argument("--size-preset", choices=sorted(SIZE_PRESETS), default="default")
    parser.add_argument("--sizes", nargs="+", type=int, help="Array sizes. Overrides --size-preset.")
    parser.add_argument("--samples", type=int, default=20)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--no-build", action="store_true", help="Skip Lean and C builds.")
    args = parser.parse_args()

    selected = args.benchmark or sorted(BENCHMARKS)
    command = " ".join(["benchmarks/run.py", *os.sys.argv[1:]])
    if not args.no_build:
        build_targets(selected)

    created_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    run_id = safe_timestamp(created_at)
    sizes = args.sizes or SIZE_PRESETS[args.size_preset]
    implementation_records, results = run_benchmarks(selected, sizes, args.samples, args.warmups)

    benchmark_records = []
    for bench_id in selected:
        bench = BENCHMARKS[bench_id]
        benchmark_records.append(
            {
                "id": bench_id,
                "name": bench["name"],
                "description": bench["description"],
                "inputAxes": bench["inputAxes"],
            }
        )

    document = {
        "schemaVersion": 1,
        "runId": run_id,
        "createdAt": created_at,
        "benchmarks": benchmark_records,
        "environment": environment(command),
        "implementations": implementation_records,
        "results": results,
    }

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    stem = "all" if len(selected) > 1 else selected[0]
    file_name = f"{run_id}-{stem}.json"
    output_path = RESULTS_DIR / file_name
    output_path.write_text(json.dumps(document, indent=2) + "\n")

    write_index(
        {
            "runId": run_id,
            "createdAt": created_at,
            "file": file_name,
            "benchmarks": selected,
            "schemaVersion": 1,
        }
    )
    print(f"wrote {output_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
