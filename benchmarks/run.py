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


def load_benchmarks():
    benchmarks = {}
    for bench_path in sorted((ROOT / "NumLeanPerf").glob("*/Bench.lean")):
        module_dir = bench_path.parent.name
        bench_id = camel_to_kebab(module_dir)
        benchmarks[bench_id] = {
            "id": bench_id,
            "moduleDir": module_dir,
            "leanExe": f"{bench_id}-bench",
            "benchFile": str(bench_path.relative_to(ROOT)),
        }
    if not benchmarks:
        raise SystemExit("no benchmarks found under NumLeanPerf/*/Bench.lean")
    return benchmarks


def camel_to_kebab(name):
    parts = []
    start = 0
    for i, ch in enumerate(name):
        if i > 0 and ch.isupper() and (not name[i - 1].isupper()):
            parts.append(name[start:i].lower())
            start = i
    parts.append(name[start:].lower())
    return "-".join(parts)


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
    decl = r"(?:partial\s+)?(?:def|opaque)"
    decl_pattern = re.compile(rf"^{decl}\s+{re.escape(symbol)}(?:\s|\(|:)")
    any_decl_pattern = re.compile(rf"^{decl}\s+")
    attr_pattern = re.compile(r"^@\[")

    decl_start = None
    for idx, line in enumerate(lines):
        if decl_pattern.match(line):
            decl_start = idx
            break
    if decl_start is None:
        return source

    start = decl_start
    while start > 0 and attr_pattern.match(lines[start - 1]):
        start -= 1

    end = len(lines)
    for idx in range(decl_start + 1, len(lines)):
        if attr_pattern.match(lines[idx]) or any_decl_pattern.match(lines[idx]):
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


def build_targets(benchmarks, selected):
    for bench_id in selected:
        bench = benchmarks[bench_id]
        run(["lake", "build", bench["leanExe"]])


def load_metadata(benchmarks, selected):
    for bench_id in selected:
        bench = benchmarks[bench_id]
        exe = ROOT / ".lake" / "build" / "bin" / bench["leanExe"]
        metadata = json.loads(run([str(exe), "--metadata"]))
        metadata["leanExe"] = bench["leanExe"]
        metadata["benchFile"] = bench["benchFile"]
        benchmarks[bench_id] = metadata


def executable_for(bench, impl):
    return ROOT / ".lake" / "build" / "bin" / bench["leanExe"]


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


def batch_size_for(size, exponent=1):
    if size <= 0:
        return 1
    return max(1, min(10000, math.ceil(10_000_000 / (size ** exponent))))


def safe_timestamp(value):
    return re.sub(r"[^0-9A-Za-z-]", "", value.replace(":", ""))


def sizes_for_bench(bench, explicit_sizes, default_sizes):
    if explicit_sizes is not None:
        return explicit_sizes
    return bench.get("sizes") or default_sizes


def run_benchmarks(benchmarks, selected, explicit_sizes, default_sizes, samples, warmups):
    results = []
    implementation_records = []

    for bench_id in selected:
        bench = benchmarks[bench_id]
        for impl in bench["implementations"]:
            impl_record = dict(impl)
            impl_record["benchmarkId"] = bench_id
            impl_record["code"] = implementation_code(impl)
            implementation_records.append(impl_record)

        exponent = bench.get("batchSizeExponent", 1)
        for size in sizes_for_bench(bench, explicit_sizes, default_sizes):
            batch_size = batch_size_for(size, exponent)
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
    benchmarks = load_benchmarks()
    parser = argparse.ArgumentParser(description="Run NumLeanPerf benchmarks and write versioned JSON results.")
    parser.add_argument("--benchmark", action="append", choices=sorted(benchmarks), help="Benchmark id to run. Defaults to all.")
    parser.add_argument("--size-preset", choices=sorted(SIZE_PRESETS), default="default")
    parser.add_argument("--sizes", nargs="+", type=int, help="Array sizes. Overrides --size-preset.")
    parser.add_argument("--samples", type=int, default=20)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--no-build", action="store_true", help="Skip Lean and C builds.")
    args = parser.parse_args()

    selected = args.benchmark or sorted(benchmarks)
    explicit_sizes = args.sizes
    default_sizes = SIZE_PRESETS[args.size_preset]
    if args.samples <= 0:
        raise SystemExit("--samples must be positive")
    if args.warmups < 0:
        raise SystemExit("--warmups must be non-negative")
    if explicit_sizes is not None and any(size <= 0 for size in explicit_sizes):
        raise SystemExit("all sizes must be positive")

    command = " ".join(["benchmarks/run.py", *os.sys.argv[1:]])
    if not args.no_build:
        build_targets(benchmarks, selected)
    load_metadata(benchmarks, selected)

    created_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    run_id = safe_timestamp(created_at)
    implementation_records, results = run_benchmarks(benchmarks, selected, explicit_sizes, default_sizes, args.samples, args.warmups)

    benchmark_records = []
    for bench_id in selected:
        bench = benchmarks[bench_id]
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
