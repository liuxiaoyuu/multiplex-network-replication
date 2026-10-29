# Environment

Tested: Apple Silicon macOS; R 4.6.0; Python 3.13.3. The project `.Rprofile` activates renv. `renv.lock` pins packages including renv 1.3.1. Direct analysis dependencies: R.matlab, haven, jsonlite, ggplot2. Python fetch/orchestration uses the standard library only.

Network reconstruction and nested analyses each take on the order of seconds on the tested Mac after packages are installed. renv activation can add about 15–20 seconds per R process. No paid API, GPU or Stata license is required. The final lockfile does not require igraph or a Fortran compiler; graph distances use base-R BFS in `code/graph_distances.R`.

Windows/Linux full-pipeline compatibility is not yet validated. CI is configured for macOS with R 4.6.0 (`.github/workflows/verify.yml`).
