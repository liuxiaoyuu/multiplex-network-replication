# Methods: predicting village information diffusion

This exploratory analysis asks whether additional relationship types improve predictions of village registration-call totals compared with advice relationships alone. It uses different subsets of the same 68 villages, so it evaluates prediction within this dataset rather than a causal effect or performance in a newly collected sample.

This public methods description was edited on 29 October 2026, after the results were available. The analytical specifications below are unchanged from the local plan dated 28 October. The document is not an external preregistration.

## Data and network measures

The reproduction follows the authors' 69-village preprocessing convention. Village 62 has no recorded seed households and is omitted from the regressions, leaving 68 villages. The outcome is `CallsReceived`. The five basic relationship types are social interaction, material exchange, advice, decision assistance and shared subcaste.

Network measures are reconstructed from household relationships and compared with the authors' measures. Diffusion centrality includes the identity term, uses the inverse spectral radius for q, and uses the maximum finite undirected distance for T, matching the deposited implementation. Network construction uses relationships and seed records within each village, without tuning graphs against village outcomes.

The PCA backbone is supplied by the authors for the original regression comparison. It is excluded from the predictive extension.

## Models

The following models are evaluated:

- **Mean reference:** the mean outcome in the training villages.
- **A, controls:** an intercept, an indicator for assignment to three seeds, and household count to powers one, two and three.
- **B, advice:** model A plus advice seed centrality.
- **C, five-layer OLS:** model A plus centrality for all five basic relationship types.
- **D, five-layer ridge:** the same predictors as model C, with a penalty on the five network coefficients only.

For ridge, the objective is the mean squared training residual plus lambda times the sum of squared standardized network coefficients. The intercept and control coefficients are unpenalized. This is a separately specified ridge model, not a reproduction of the paper's Puffer LASSO procedure.

## Training and evaluation

The primary evaluation leaves out one complete village at a time. Each of the 68 villages receives equal weight. The primary comparison is RMSE(C) minus RMSE(B); a negative value favours five-layer OLS. Secondary comparisons report MAE, improvement relative to the training-mean reference, and results for all models.

Each training set supplies the means and standard deviations for its nonbinary continuous predictors. Household-count powers are constructed before standardization. Test observations use the training transformations. Outcomes are not standardized, and there is no feature selection using the whole sample. Singular fits stop with a diagnostic. Predictions are retained even when negative, and outlying villages remain in the evaluation.

Ridge tuning uses 41 values on the grid `10^seq(-4, 4, length.out=41)`. Five inner folds are constructed by permuting the training village indices and assigning repeated labels 1 to 5. For leave-one-village-out evaluation, the seed is 20261028 plus the held-out village ID. Standardization is fitted again within each inner training fold. Lambda minimizes pooled inner-validation MSE; ties within a relative tolerance of 1e-12 select the larger penalty. The selected model is then fitted on the outer training set.

Partition sensitivity uses ten repetitions of five-fold outer validation. Each village is tested once per repetition. The outer seed is 20261028 plus the repetition number; the inner ridge seed is 20261028 + 1000 × repetition + outer-fold number. The models, penalty grid and evaluation rules remain the same across repetitions. All ten sets of scores and paired C–B and D–B differences are reported.

## Uncertainty and numerical checks

The primary comparison is descriptive. The ten partitions are not independent replications, and leave-one-out errors share training observations. The original comparison therefore does not use an ordinary independent-observation significance test to declare a winning model. Subsequent uncertainty calculations are described in the [additional sensitivity methods](PUBLICATION_AMENDMENT.md).

OLS leave-one-out predictions are checked against the analytic leverage/PRESS identity. Ridge predictions are checked by residualizing the unpenalized controls and using an independent singular-value-decomposition calculation. Perturbing held-out outcomes checks that those outcomes cannot affect fitting or tuning. Input checksums, numerical validation results and the software environment are recorded separately.

The authors' published regressions were already known when the advice benchmark was selected. These comparisons assess that specified benchmark; they do not remove the influence of prior knowledge of the published findings.
