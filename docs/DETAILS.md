# Detailed results

Numbers behind the summary in the [README](../README.md).

## Reproduction

- All 552 rebuilt adjacency matrices match the authors' matrices exactly; the 544 nonmissing seed-centrality values agree within about 9.4 × 10⁻¹³.
- All nine OLS models with HC2 standard errors match Table S2 at three decimals, with N = 68. Village 62 has no recorded seeds and is excluded, as in the author implementation.
- The PCA backbone measure is taken from the authors' files rather than rebuilt.
- Not reproduced: the theoretical results, simulations, Table 1's sequential model selection and construction of the PCA backbone.

[Regression comparison](../results/figure2_table_s2_comparison.csv) · [Verification record](VERIFICATION.md)

## Held-out prediction

| Model | Leave-one-village-out RMSE | MAE |
|---|---:|---:|
| Training-sample mean | 11.611 | 8.242 |
| Advice + controls | 11.376 | 8.316 |
| Five basic layers, OLS | 11.659 | 8.231 |
| Five basic layers, ridge | 11.227 | 8.032 |

Errors are in calls; lower is better. Ridge improves leave-one-village-out RMSE over advice by about 1.3%, but each five-layer model beats advice on RMSE in only two of ten repeated five-fold comparisons. Standardization and tuning use training data only. The models and evaluation rules are described in the [prediction methods](ANALYSIS_PLAN_20261028.md) and [additional sensitivity methods](PUBLICATION_AMENDMENT.md). These public descriptions were edited after the analyses and are not external preregistrations.

![Prediction comparisons across different data splits](../results/partition_sensitivity.png)

## Sensitivity checks

- Count (Poisson) models do not improve overall RMSE.
- Adding recorded seed count as a control leaves the OLS ordering similar; restricting to the 39 villages where assigned and recorded seed counts agree reverses it.
- In full refits after excluding each village, the original OLS ordering holds in 66 of 68 cases.
- Approximate corrected-resampling intervals include differences in either direction.

[Prediction scores](../results/prediction_metrics.csv) · [Seed-count checks](../results/measurement_sensitivity.csv) · [Uncertainty intervals](../results/corrected_resampling_intervals.csv)
