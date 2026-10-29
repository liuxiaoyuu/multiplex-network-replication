# Methods: additional sensitivity analyses

These exploratory analyses follow the initial leave-one-village-out and ten repeated five-fold comparisons. The original prediction results were already known when the additional analyses were specified. The primary comparison remains five-layer OLS minus advice OLS in held-out RMSE. All analyses reuse the same source dataset.

This public methods description was edited on 29 October 2026, after the results were available. The analytical specifications are unchanged from the local amendment dated 28 October. The document is not an external preregistration.

## Source verification

The complete final article and supplement were obtained from NIH/NLM PMC's open-data distribution. Advertised MD5 checksums and local SHA256 checksums were recorded. The original 2019 experimental archive was also examined to clarify seed-variable definitions. Missing seed records were not imputed, and discrepancies in recorded and assigned seed counts are not treated as proof of an error in the authors' data.

## Count outcomes

Two ridge-penalized Poisson mean models use:

`log(mu) = log(households) + intercept + three-seed indicator + standardized centrality predictors`.

The advice model uses advice centrality; the five-layer model uses all five basic centralities. The intercept and seed-assignment coefficient are unpenalized. Only the network slopes receive the penalty.

The objective is mean Poisson negative log likelihood, omitting constants, plus lambda/2 times the sum of squared network coefficients. The tuning grid is `10^seq(-4, 2, length.out=25)`. Pooled inner-five-fold Poisson deviance selects the penalty. Outer and inner fold seeds are the same as in the [initial analysis](ANALYSIS_PLAN_20261028.md), and scaling is fitted within each training fold.

The evaluation reports deviance, RMSE, MAE, convergence diagnostics and predictions for leave-one-village-out and the same ten five-fold repetitions. A training-wide per-household rate provides an additional untuned reference. These models assess a positive count mean with household exposure; they do not use a Poisson variance assumption to make inferential claims. Predictions are not clipped, and the tuning grid is not expanded in response to the results.

## Seed-count measurement

Advice and five-layer OLS are compared again under two specifications: adding recorded seed count as a control, and restricting the sample to villages where assigned and recorded seed counts agree. The restricted comparison concerns a different subset of villages. It does not correct nonrandom missingness. Village selection is based on the seed records, not on the outcome.

## Influence of individual villages

Each of the 68 villages is removed in turn. The complete advice-versus-five-layer leave-one-out comparison is recomputed in the remaining 67 villages using analytic PRESS. The excluded village participates in neither fitting nor evaluation. All differences, their range and their signs are reported.

## Approximate uncertainty

For the 50 paired five-fold mean-squared-error differences, the calculation is:

`mean(d) +/- t(49, .975) × sqrt((1/50 + mean(n_test/n_train)) × var(d))`.

It is applied separately to five-layer OLS minus advice and five-layer ridge minus advice. These are Nadeau–Bengio-style corrected-resampling approximations, without a guarantee of exact coverage. Unequal fold sizes make the calculation an equal-fold comparison rather than exactly equal-village pooling.

The 50 folds are not treated as independent. Intervals are reported with both endpoints, alongside per-repetition and deletion ranges. The analysis does not use these intervals to claim equivalence between models.

## Validation and interpretation

Poisson coefficient gradients are checked numerically, selected fitted means are compared with an independent BFGS optimizer, and held-out outcomes are perturbed to check that they cannot affect fitting or tuning. Numerical failures stop the analysis rather than silently substituting a different model. The original reproduction outputs remain reference values for validation.

The extension does not search across forests, boosting, additional feature engineering or outcome-selected exclusions. Its conclusions concern the tested models and the available villages; they establish neither a causal effect of a network layer nor predictive performance in an independent population.
