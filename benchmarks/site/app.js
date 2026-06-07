const indexUrl = "../results/index.json";
const state = {
  index: null,
  documents: new Map(),
  currentDocument: null,
  chart: null,
  tableSort: { key: "mean", direction: "asc" },
  pendingSize: null,
};

const runSelect = document.querySelector("#runSelect");
const benchmarkSelect = document.querySelector("#benchmarkSelect");
const sizeSelect = document.querySelector("#sizeSelect");
const errorBarsToggle = document.querySelector("#errorBarsToggle");
const fileInput = document.querySelector("#fileInput");
const implementationTitle = document.querySelector("#implementationTitle");
const implementationMeta = document.querySelector("#implementationMeta");
const implementationCode = document.querySelector("#implementationCode");
const resultsBody = document.querySelector("#resultsBody");
const environmentList = document.querySelector("#environmentList");

async function loadJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to load ${url}: ${response.status}`);
  }
  return response.json();
}

function formatSeconds(value) {
  if (!Number.isFinite(value)) return "";
  if (value < 1e-6) return `${(value * 1e9).toFixed(2)} ns`;
  if (value < 1e-3) return `${(value * 1e6).toFixed(2)} us`;
  if (value < 1) return `${(value * 1e3).toFixed(2)} ms`;
  return `${value.toFixed(3)} s`;
}

function color(index) {
  const colors = ["#83d4ff", "#f7c873", "#9be282", "#f28fb3", "#b49cff", "#67e8d4", "#ff9f7a"];
  return colors[index % colors.length];
}

function implementationsFor(document, benchmarkId) {
  return document.implementations.filter((impl) => impl.benchmarkId === benchmarkId);
}

function resultsFor(document, benchmarkId) {
  return document.results.filter((result) => result.benchmarkId === benchmarkId);
}

function availableSizes(document, benchmarkId) {
  return [...new Set(resultsFor(document, benchmarkId).map((result) => result.inputs.arraySize))].sort((a, b) => a - b);
}

function implementationById(document) {
  return new Map(document.implementations.map((impl) => [impl.id, impl]));
}

function benchmarkName(id) {
  return id
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function readUrlState() {
  const params = new URLSearchParams(window.location.search);
  return {
    benchmark: params.get("benchmark"),
    run: params.get("run"),
    size: params.get("size"),
    sort: params.get("sort"),
    dir: params.get("dir"),
    errors: params.get("errors"),
  };
}

function selectedRunEntry() {
  return (state.index?.runs || []).find((run) => run.file === runSelect.value) || null;
}

function updateUrl() {
  if (!state.index || !benchmarkSelect.value || !runSelect.value) return;
  const params = new URLSearchParams();
  const run = selectedRunEntry();
  params.set("benchmark", benchmarkSelect.value);
  params.set("run", run?.runId || runSelect.value);
  if (sizeSelect.value) params.set("size", sizeSelect.value);
  params.set("sort", state.tableSort.key);
  params.set("dir", state.tableSort.direction);
  params.set("errors", errorBarsToggle.checked ? "1" : "0");
  const next = `${window.location.pathname}?${params.toString()}`;
  window.history.replaceState(null, "", next);
}

const errorBarsPlugin = {
  id: "numleanperfErrorBars",
  afterDatasetsDraw(chart) {
    if (!errorBarsToggle.checked) return;
    const yScale = chart.scales.y;
    const capWidth = 8;
    const ctx = chart.ctx;
    chart.data.datasets.forEach((dataset, datasetIndex) => {
      const meta = chart.getDatasetMeta(datasetIndex);
      if (meta.hidden) return;
      ctx.save();
      ctx.strokeStyle = dataset.borderColor;
      ctx.globalAlpha = 0.65;
      ctx.lineWidth = 1;
      dataset.data.forEach((point, pointIndex) => {
        const result = point.result;
        if (!result || !Number.isFinite(result.stddev) || result.stddev <= 0) return;
        const element = meta.data[pointIndex];
        if (!element) return;
        const low = Math.max(result.mean - result.stddev, yScale.min || 0);
        const high = result.mean + result.stddev;
        if (high <= 0) return;
        const x = element.x;
        const yLow = yScale.getPixelForValue(low);
        const yHigh = yScale.getPixelForValue(high);
        ctx.beginPath();
        ctx.moveTo(x, yHigh);
        ctx.lineTo(x, yLow);
        ctx.moveTo(x - capWidth / 2, yHigh);
        ctx.lineTo(x + capWidth / 2, yHigh);
        ctx.moveTo(x - capWidth / 2, yLow);
        ctx.lineTo(x + capWidth / 2, yLow);
        ctx.stroke();
      });
      ctx.restore();
    });
  },
};

function updateImplementationPanel(document, implId, result) {
  const impl = implementationById(document).get(implId);
  if (!impl) return;
  implementationTitle.textContent = impl.name;
  const timing = result
    ? `n=${result.inputs.arraySize}, mean=${formatSeconds(result.mean)}, stddev=${formatSeconds(result.stddev)}, samples=${result.samples}, batch=${result.batchSize || 1}`
    : `${impl.language}, ${impl.sourceFile}`;
  implementationMeta.textContent = `${impl.id} | ${timing}`;
  implementationCode.textContent = impl.code || "Source code was not embedded in this result file.";
}

function updateChart(document, benchmarkId) {
  const canvas = window.document.querySelector("#chart");
  const impls = implementationsFor(document, benchmarkId);
  const allResults = resultsFor(document, benchmarkId);
  const grouped = new Map(impls.map((impl) => [impl.id, []]));
  for (const result of allResults) {
    grouped.get(result.implementationId)?.push(result);
  }

  const datasets = impls.map((impl, index) => {
    const data = (grouped.get(impl.id) || [])
      .slice()
      .sort((a, b) => a.inputs.arraySize - b.inputs.arraySize)
      .map((result) => ({ x: result.inputs.arraySize, y: result.mean, result }));
    return {
      label: impl.name,
      data,
      borderColor: color(index),
      backgroundColor: color(index),
      tension: 0.18,
    };
  });
  const yScaleType = allResults.some((result) => result.mean <= 0) ? "linear" : "logarithmic";

  if (state.chart) {
    state.chart.destroy();
  }

  state.chart = new Chart(canvas, {
    type: "line",
    data: { datasets },
    plugins: [errorBarsPlugin],
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: false,
      animations: false,
      transitions: {
        active: { animation: { duration: 0 } },
        resize: { animation: { duration: 0 } },
        show: { animation: { duration: 0 } },
        hide: { animation: { duration: 0 } },
      },
      parsing: false,
      interaction: { mode: "nearest", intersect: false },
      scales: {
        x: {
          type: "logarithmic",
          title: { display: true, text: "Array size" },
          grid: { color: "#30384a" },
          ticks: { color: "#99a4b8" },
        },
        y: {
          type: yScaleType,
          title: { display: true, text: "Mean time" },
          grid: { color: "#30384a" },
          ticks: { color: "#99a4b8", callback: (value) => formatSeconds(Number(value)) },
        },
      },
      plugins: {
        legend: {
          labels: { color: "#edf1f7" },
          onHover: (_event, item) => updateImplementationPanel(document, impls[item.datasetIndex].id),
        },
        tooltip: {
          callbacks: {
            label: (context) => `${context.dataset.label}: ${formatSeconds(context.raw.y)}`,
          },
        },
      },
      onHover: (_event, elements) => {
        if (!elements.length) return;
        const element = elements[0];
        const dataset = datasets[element.datasetIndex];
        const point = dataset.data[element.index];
        const impl = impls[element.datasetIndex];
        updateImplementationPanel(document, impl.id, point.result);
      },
    },
  });
  requestAnimationFrame(() => state.chart?.resize());
}

function updateSizeOptions(document, benchmarkId) {
  const previous = Number(sizeSelect.value);
  const pending = state.pendingSize === null ? null : Number(state.pendingSize);
  const sizes = availableSizes(document, benchmarkId);
  sizeSelect.innerHTML = "";
  for (const size of sizes) {
    const option = window.document.createElement("option");
    option.value = String(size);
    option.textContent = String(size);
    sizeSelect.appendChild(option);
  }
  if (pending !== null && sizes.includes(pending)) {
    sizeSelect.value = String(pending);
    state.pendingSize = null;
  } else if (sizes.includes(previous)) {
    sizeSelect.value = String(previous);
  } else if (sizes.length > 0) {
    sizeSelect.value = String(sizes[sizes.length - 1]);
  }
}

function valueForSort(result, impl, key) {
  if (key === "implementation") return impl?.name || result.implementationId;
  if (key === "arraySize") return result.inputs.arraySize;
  return result[key];
}

function updateSortHeaders() {
  for (const button of window.document.querySelectorAll("[data-sort]")) {
    const key = button.dataset.sort;
    const active = key === state.tableSort.key;
    button.classList.toggle("activeSort", active);
    const label = button.textContent.replace(/ [↑↓]$/, "");
    button.textContent = active ? `${label} ${state.tableSort.direction === "asc" ? "↑" : "↓"}` : label;
  }
}

function updateTable(document, benchmarkId) {
  const impls = implementationById(document);
  const selectedSize = Number(sizeSelect.value);
  const rows = resultsFor(document, benchmarkId)
    .filter((result) => result.inputs.arraySize === selectedSize)
    .slice()
    .sort((a, b) => {
      const implA = impls.get(a.implementationId);
      const implB = impls.get(b.implementationId);
      const valueA = valueForSort(a, implA, state.tableSort.key);
      const valueB = valueForSort(b, implB, state.tableSort.key);
      const direction = state.tableSort.direction === "asc" ? 1 : -1;
      if (typeof valueA === "string" || typeof valueB === "string") {
        return direction * String(valueA).localeCompare(String(valueB));
      }
      return direction * ((valueA ?? 0) - (valueB ?? 0));
    });
  updateSortHeaders();
  resultsBody.innerHTML = "";
  for (const result of rows) {
    const impl = impls.get(result.implementationId);
    const row = window.document.createElement("tr");
    row.innerHTML = `
      <td>${impl?.name || result.implementationId}</td>
      <td>${result.inputs.arraySize}</td>
      <td>${formatSeconds(result.mean)}</td>
      <td>${formatSeconds(result.stddev)}</td>
      <td>${formatSeconds(result.min)}</td>
      <td>${formatSeconds(result.max)}</td>
      <td>${result.samples}</td>
      <td>${result.batchSize || 1}</td>
    `;
    row.addEventListener("mouseenter", () => updateImplementationPanel(document, result.implementationId, result));
    resultsBody.appendChild(row);
  }
}

function updateEnvironment(document) {
  environmentList.innerHTML = "";
  const env = document.environment || {};
  const entries = [
    ["Created", document.createdAt],
    ["OS", env.os],
    ["Kernel", env.kernel],
    ["Machine", env.machine],
    ["CPU", env.cpu],
    ["Logical cores", env.cpuLogicalCores],
    ["Memory", env.memory?.text],
    ["Lean", env.lean],
    ["Lake", env.lake],
    ["C compiler", env.cCompiler],
    ["C flags", env.cFlags],
    ["Git commit", env.gitCommit],
    ["Git dirty", String(env.gitDirty)],
    ["Command", env.command],
  ];
  for (const [key, value] of entries) {
    if (value === undefined || value === null || value === "") continue;
    const dt = window.document.createElement("dt");
    const dd = window.document.createElement("dd");
    dt.textContent = key;
    dd.textContent = value;
    environmentList.append(dt, dd);
  }
}

function updateBenchmarkOptionsFromDocument(document) {
  benchmarkSelect.innerHTML = "";
  for (const benchmark of document.benchmarks) {
    const option = window.document.createElement("option");
    option.value = benchmark.id;
    option.textContent = benchmark.name;
    benchmarkSelect.appendChild(option);
  }
}

function updateBenchmarkOptionsFromIndex() {
  benchmarkSelect.innerHTML = "";
  const seen = new Set();
  for (const run of state.index.runs || []) {
    for (const benchmarkId of run.benchmarks || []) {
      if (seen.has(benchmarkId)) continue;
      seen.add(benchmarkId);
      const option = window.document.createElement("option");
      option.value = benchmarkId;
      option.textContent = benchmarkName(benchmarkId);
      benchmarkSelect.appendChild(option);
    }
  }
}

function updateRunOptionsForBenchmark(benchmarkId) {
  runSelect.innerHTML = "";
  const runs = (state.index?.runs || []).filter((run) => (run.benchmarks || []).includes(benchmarkId));
  for (const run of runs) {
    const option = window.document.createElement("option");
    option.value = run.file;
    option.textContent = run.createdAt;
    runSelect.appendChild(option);
  }
}

function renderCurrent() {
  const document = state.currentDocument;
  if (!document) return;
  const benchmarkId = benchmarkSelect.value || document.benchmarks[0]?.id;
  updateChart(document, benchmarkId);
  updateSizeOptions(document, benchmarkId);
  updateTable(document, benchmarkId);
  updateEnvironment(document);
  const firstImpl = implementationsFor(document, benchmarkId)[0];
  if (firstImpl) updateImplementationPanel(document, firstImpl.id);
  updateUrl();
}

async function loadRun(fileName) {
  if (!state.documents.has(fileName)) {
    state.documents.set(fileName, await loadJson(`../results/${fileName}`));
  }
  state.currentDocument = state.documents.get(fileName);
  renderCurrent();
}

async function initFromIndex() {
  const urlState = readUrlState();
  if (urlState.sort) state.tableSort.key = urlState.sort;
  if (urlState.dir === "asc" || urlState.dir === "desc") state.tableSort.direction = urlState.dir;
  if (urlState.errors === "0") errorBarsToggle.checked = false;
  state.pendingSize = urlState.size;

  state.index = await loadJson(indexUrl);
  updateBenchmarkOptionsFromIndex();
  if (urlState.benchmark && [...benchmarkSelect.options].some((option) => option.value === urlState.benchmark)) {
    benchmarkSelect.value = urlState.benchmark;
  }
  updateRunOptionsForBenchmark(benchmarkSelect.value);
  if (urlState.run) {
    const match = (state.index.runs || []).find((run) =>
      run.file === urlState.run || run.runId === urlState.run || run.createdAt === urlState.run
    );
    if (match && [...runSelect.options].some((option) => option.value === match.file)) {
      runSelect.value = match.file;
    }
  }
  if (runSelect.value) {
    await loadRun(runSelect.value);
  }
}

runSelect.addEventListener("change", () => loadRun(runSelect.value));
sizeSelect.addEventListener("change", renderCurrent);
errorBarsToggle.addEventListener("change", () => {
  state.chart?.draw();
  updateUrl();
});
for (const button of window.document.querySelectorAll("[data-sort]")) {
  button.addEventListener("click", () => {
    const key = button.dataset.sort;
    if (state.tableSort.key === key) {
      state.tableSort.direction = state.tableSort.direction === "asc" ? "desc" : "asc";
    } else {
      state.tableSort = { key, direction: key === "implementation" ? "asc" : "asc" };
    }
    renderCurrent();
  });
}
benchmarkSelect.addEventListener("change", async () => {
  if (state.index) {
    updateRunOptionsForBenchmark(benchmarkSelect.value);
    if (runSelect.value) {
      await loadRun(runSelect.value);
      return;
    }
  }
  renderCurrent();
});
fileInput.addEventListener("change", async () => {
  const file = fileInput.files[0];
  if (!file) return;
  const text = await file.text();
  state.currentDocument = JSON.parse(text);
  updateBenchmarkOptionsFromDocument(state.currentDocument);
  renderCurrent();
});

initFromIndex().catch((error) => {
  implementationTitle.textContent = "No indexed results loaded";
  implementationMeta.textContent = `${error.message}. Run benchmarks/run.py, serve benchmarks/site over HTTP, or use Load JSON.`;
});
