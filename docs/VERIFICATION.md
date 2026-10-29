# Verification

Checked on 29 October 2026 (Asia/Shanghai) with a restored project library from `renv.lock`.

- 552 adjacency matrices exact; 544 nonmissing centralities agree within about 9.4×10⁻¹³.
- Nine coefficients, HC2 SEs, *p* values, R² and all N targets match published Table S2 to three decimals.
- Nested OLS LOO predictions match PRESS within about 7.5×10⁻¹³; ridge matches an independent FWL/SVD check within about 3.9×10⁻¹¹.
- Count-model fits converge; held-out outcome perturbations do not change predictions.
- Base-R BFS distances match the earlier igraph outputs on all 552 graphs. Data-free checks: `Rscript code/test_models.R`.
- Eleven deterministic result files were byte-identical after a clean rerun (`docs/clean_rerun_checks.json`).

The GitHub Actions workflow runs numerical tests on push; a full data download is optional via `workflow_dispatch`. Numerical agreement is rounded to the paper’s printed precision, not a claim of bit-for-bit identity with every author internal object.
