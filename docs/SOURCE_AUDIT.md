# Source audit

Published article: Chandrasekhar et al. (2026), *PNAS* 123(28), e2534923123, DOI https://doi.org/10.1073/pnas.2534923123. Complete article and supplement PDFs were retrieved for visual checks of Table S2; checksums are in `docs/final_article_sources.json`. PDFs are not redistributed in this repository.

Computational inputs are pinned to commit `c3d9dbafafb2674cc7ca3fdca9bc4b4bca76c20f` of https://github.com/v-asu/multiplexing-and-diffusion-replication-package. Exact paths, sizes and SHA256 digests are in `docs/source_manifest.json` and `docs/network_sources.json`. Author scripts informed the reimplementation but are not bundled or executed here.

## Scope relative to the paper

The original study includes post-Puffer LASSO, PCA/backbone construction, layer comparisons, multiplexing interactions, simulations and theory. Table 1’s sequential model includes intersection and other constructed layers; the five-basic-layer predictive models in this repository are not that selected specification. The PCA backbone column in the Table S2 reproduction still uses the author-supplied measure.

## Related experiment archive

Banerjee, Chandrasekhar, Duflo and Jackson (2019), *Review of Economic Studies*, DOI https://doi.org/10.1093/restud/rdz008. The Stanford GossipFinalData.zip was inspected for provenance (`docs/gossip_source.json`) and is not required to run the current models.

Village 62 has no recorded seeds and is excluded from the centrality regressions, matching the 2026 sample. Seed-count discrepancies between assigned and recorded seeds are documented in the measurement-sensitivity outputs; no corrected dataset is asserted.

## Analysis documentation

The [prediction methods](ANALYSIS_PLAN_20261028.md) and [additional sensitivity methods](PUBLICATION_AMENDMENT.md) describe the implemented analyses. They were edited into public methods descriptions on 29 October 2026 after results were available, without changing the analytical specifications. They are not external preregistrations.

`run.py` verifies the current document checksums as well as the computational input checksums. The two document manifests retain the earlier local-plan checksums and timestamps separately from the current wording. A checksum establishes file identity; it does not by itself establish prospective registration.

## Optional source checks

`code/retrieve_final_sources.py` retrieves the article and supplement for source verification; these PDFs are not inputs to the numerical models. After the main pipeline has generated the network audit, `code/audit_original_archive.py` downloads the original experiment archive and calls `code/audit_original_archive.R` to compare its village outcomes and seed counts with the later author package. These source checks are separate from the main reproduction.

## Use and redistribution

- Original article: Chandrasekhar et al. (2026), DOI 10.1073/pnas.2534923123. Article metadata indicates CC BY-NC-ND; that does not automatically license separately deposited data or code. Author PDFs, copied figures and scripts are excluded from this repository.
- Author package: https://github.com/v-asu/multiplexing-and-diffusion-replication-package at `c3d9dbafafb2674cc7ca3fdca9bc4b4bca76c20f`. No explicit license was identified at that snapshot. Fetch scripts retrieve public files and verify hashes. Readers must observe applicable access and reuse terms. This project grants no rights over those sources.
- Earlier experiment: Banerjee et al. (2019), DOI 10.1093/restud/rdz008; Stanford GossipFinalData.zip used only for provenance auditing and is not redistributed.
- `renv/activate.R` is the upstream bootstrap from renv 1.3.1 (Posit Software, PBC / authors), under MIT. Dependencies keep their own licenses and are downloaded separately.
- `LICENSE` covers original project implementation and documentation only. Numerical targets are cited published facts. Source inspection informed the reimplementation; this is not a clean-room claim.
- Individual predictions include observed outcomes. Record-level predictions, centrality rebuild tables, folds and node audits are generated locally and are excluded from the tracked result set (see `.gitignore`).

No student solutions, private notes, other authors’ PDFs or credentials are bundled.
