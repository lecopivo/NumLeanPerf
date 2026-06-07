import Lake
open Lake DSL System

package «NumLeanPerf» where
  version := v!"0.1.0"

lean_lib «NumLeanPerf»

def sanitizeObjectName (path : FilePath) : String :=
  path.toString.map fun c =>
    if c.isAlphanum then c else '_'

def isCSource (path : FilePath) : Bool :=
  path.extension == some "c"

extern_lib leanffi pkg := do
  let srcJob ← inputDir (pkg.dir / "NumLeanPerf") true isCSource
  srcJob.bindM fun srcs => do
    let mut objJobs := #[]
    for src in srcs do
      let srcFileJob ← inputFile src true
      let objFile := pkg.buildDir / "c" / s!"{sanitizeObjectName src}.o"
      let lean ← getLeanInstall
      let objJob ← buildO objFile srcFileJob
        #["-I", lean.includeDir.toString, "-I", pkg.dir.toString]
        #["-O3", "-march=native"]
      objJobs := objJobs.push objJob
    buildStaticLib (pkg.staticLibDir / nameToStaticLib "leanffi") objJobs

lean_exe «numleanperf» where
  root := `Main

lean_exe «float-array-sum-bench» where
  root := `NumLeanPerf.FloatArraySum.Bench

lean_exe «float-array-add-bench» where
  root := `NumLeanPerf.FloatArrayAdd.Bench

lean_exe «float-array-axpy-bench» where
  root := `NumLeanPerf.FloatArrayAxpy.Bench
