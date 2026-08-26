# IRTC 1.1.2

Correctness release for the multidimensional streaming estimation path,
prompted by a production survey analysis (85,035 respondents, 10 dichotomous
items, three content dimensions, sampling weights). Three of the fixes change
reported numbers; see "Numerical changes" below. The `irtc()` / `irtc.mml()` /
`irtc.mml.2pl()` signatures are unchanged and no argument changes meaning.

## Bug fixes

* The streaming engine no longer crashes the R session when the response
  matrix contains `NA`. The C++ E-step indexed the category probability array
  with the raw response code, so a missing value (`NA_INTEGER`) produced an
  out-of-bounds read and a segmentation fault. Missing responses are now
  handled natively, exactly as the grid engine handles them: the item
  contributes a likelihood factor of 1 and no expected counts. Complete-case
  deletion before a multidimensional fit is no longer necessary, and persons
  with no responses at all are kept at the prior mean.

* The streaming engine's `deviance`, `loglike`, `AIC`, `BIC`, `aBIC`, `CAIC`
  and `AICc` were offset by `n * ndim * log(1 / h)`, where `h` is the
  quadrature node spacing. The quadrature weights were the multivariate
  normal *density* at the nodes rather than probability *mass*, and a density
  summed over a grid of spacing `h` is about `h^-ndim` instead of 1. The
  weights are now normalised to sum to one. The reported log-likelihood is
  again a genuine log-probability, and it is comparable across the two
  engines, across dimensionalities and across `control$nodes` settings. This
  silently invalidated any comparison that crossed `ndim` or engines --
  including `anova()` and `logLik()` -- so results from earlier versions that
  relied on such a comparison should be recomputed.

* Log-likelihoods no longer turn positive (and deviances negative) when the
  estimated latent covariance degenerates. As correlations approach the
  boundary the normal density grows like `1 / sqrt(det(Sigma))`, which the
  missing mass normalisation passed straight into the reported value. The
  quadrature weights are additionally computed on the log scale, so a
  near-singular covariance can no longer overflow or underflow.

* Reaching the boundary now raises a warning (code `W427`) instead of passing
  silently. It usually carries a substantive finding -- the dimensions are
  not separable in these data and the model has degenerated to a
  lower-dimensional one -- and it also flags that the information criteria and
  EAP reliabilities of that fit rest on a grid which can no longer resolve the
  collapsed covariance.

* `irtc_param_table()`, and hence `irtc_results()` and the item-parameter
  workbook of `irtc_excel()`, read the slope from dimension 1 regardless of
  which dimension an item actually loaded on. In a multidimensional model
  every item that did not load on the first dimension was reported with
  `slope_a = 0` and `difficulty_b = NA`. Parameters are now read from the
  item's own loading dimension. The same fix applies to the `item_irt` table
  of the grid engine. Since the item-parameter workbook is the documented
  interface for cross-year linking, banks built from a multidimensional fit
  with an earlier version should be regenerated.

* The streaming path lost the person identifiers passed through `irtc(id=)` /
  `irtc.mml.2pl(pid=)`, returning row numbers instead, so person-level output
  could not be joined back to the sample by id. It also reported
  `person$pweight` as 1 for every case even though the weights were used in
  estimation. Both are now carried through.

* `irtc_ctt()`, `irtc_itemfit()` and `irtc_quality()` ignored the sampling
  weights, so a single `irtc()` results table mixed weighted IRT parameters
  with unweighted classical difficulties, discriminations, fit statistics and
  the quality ratings derived from them. In the survey that prompted this
  release one item's pass rate differed by 7.8 percentage points between the
  two bases, enough to change its difficulty label.

## New features

* `irtc_ctt()`, `irtc_itemfit()`, `irtc_quality()` and `irtc_param_table()`
  gain a `weights=` argument. `irtc()` passes the sampling weights it already
  forwards to the estimation, so the whole results table now rests on one
  population. `irtc_itemfit()`, `irtc_quality()` and `irtc_param_table()`
  default to the case weights stored on the model. Constant weights reproduce
  the unweighted statistics exactly, so unweighted analyses are unaffected.
  `irtc_ctt()` reports an `N_weighted` column and a `weighted` flag.

* The streaming engine now returns posterior standard errors. The person
  table gains `SD.EAP.Dim1`, ..., so `irtc_results()` and `irtc_excel()`
  produce the `se_*` columns for multidimensional fits that previously only
  the grid engine could supply.

* `irtc_param_table()` gains a `dimension` column for multidimensional models,
  naming the dimension each item loads on (using the Q-matrix column headers
  when available), plus `n_loadings`. An item loading on several dimensions at
  once has no single slope; `slope_a` is then the sum of its loadings and
  `n_loadings` is above 1, marking the value as a composite.

* Choosing `method = "grid"` for a model whose posterior matrix cannot fit in
  memory now fails immediately with a structured error (code `E409`) naming
  the predicted size and pointing at `method = "streaming"`, instead of an
  opaque `vector memory limit ... reached` from inside the E-step.
  `method = "auto"` already routed such models to the streaming engine and is
  unaffected.

## Numerical changes

Item parameters, latent covariances and EAP estimates are unchanged: the
quadrature weight normalisation cancels out of every posterior quantity. What
changes is what gets reported.

* `deviance` / `loglike` and all information criteria from the streaming
  engine shift by the constant described above; the grid engine is unchanged
  and was already correct.

* The streaming engine's `EAP.rel` now uses the same definition as the grid
  engine -- the case-weighted ratio of true-score variance to total variance
  -- instead of an unweighted `var(EAP) / diag(Sigma)` proxy that ignored both
  the case weights and the posterior error variance. In the degenerate fit
  that prompted this, the three collapsed dimensions reported 0.63 where the
  equivalent unidimensional model reported 0.72; they now agree.

* Weighted analyses see the classical statistics, item fit and quality
  ratings move to the weighted basis, as described above.

## Documentation

* `?irtc.mml.2pl` documents the missing-response handling, which comparisons
  the `ic` values support, the memory guard, and that `irtmodel = "GPCM"` is
  mathematically equivalent to `"2PL"` for strictly dichotomous items -- so
  switching to GPCM does not by itself change the model, only `ndim` / `Q` do.

* `?irtc_itemfit` states that the residuals are evaluated at the EAP person
  estimates, for comparison against software that uses WLE estimates.

* `?irtc_excel` notes that the person-level `percentile` and `t_score`
  columns are always computed on the unweighted sample, so they describe the
  respondents rather than the weighted population.

* `inst/llms.txt` gains a section on how the sampling weights propagate.

* Upgrading from 0.1.0: the estimation core (`irtc.mml()`, `irtc.mml.2pl()`)
  is unchanged and no 0.1.0 script needs editing. Everything added since is
  the optional usability layer on top -- `irtc()`, `irtc_results()`,
  `irtc_report()`, `irtc_quality()`, `irtc_excel()` and friends -- described
  under 1.0.0 and 1.1.0 below.

## Schema versions

* `irtc_results()` advances to schema 1.2 and the `irtc_excel()` linking
  workbook to 1.1. Both are additive: existing column names and meanings are
  unchanged, and the new `dimension` / `n_loadings` columns appear only for
  multidimensional models.

## Internal

* `ic` is now a one-row data frame from both engines; the streaming engine
  previously returned a plain list, so code reading `mod$ic` had to branch on
  the engine.

* New regression tests in `tests/testthat/test-streaming-quadrature.R` lock
  down each of the findings above: node-count invariance of the reported
  log-likelihood, agreement between the grid and streaming deviance on the
  same model, `NA` handling, the degenerate-covariance behaviour, the
  id/weight round trip, multidimensional parameter extraction, and the
  weighted statistics reducing to the unweighted ones under constant weights.

# IRTC 1.1.1

Packaging-only release addressing the CRAN incoming pre-test results for
1.1.0. No user-visible behaviour, no API and no estimation results change.

## Documentation

* The Rd sources reaching LaTeX are now ASCII, so the PDF reference manual
  builds without errors. Chinese column-name aliases are still documented:
  the new `\zh` Rd macro shows the Chinese characters in the HTML and text
  help and the equivalent `\uxxxx` escape in the PDF manual.

* DESCRIPTION gains a `Date` field, so the package banner reads
  `IRTC 1.1.1 (2026-07-17)` instead of `IRTC 1.1.1 ()`.

## Internal

* `tests/testthat/test-print-session.R` no longer assumes the released R
  wording `"R version"`, which does not hold on r-devel
  (`"R Under development (unstable)"`). It now compares against
  `R.version.string`.

# IRTC 1.1.0

Usability release focused on the GPCM / multidimensional workflow. The
estimation core (`irtc.mml` / `irtc.mml.2pl`) is unchanged; all new
behaviour lives in the usability layer and is backward compatible. New
optional dependencies: none.

## New features

* `irtc_read()` gains sampling-weight import: a `weights=` argument plus
  automatic detection of common weight column names (English and
  Chinese). Weights are validated (positive numbers; missing set to 1
  with a warning), kept aligned when empty rows are dropped, and shown by
  the print method. `irtc()` forwards them as `pweights`.
* `irtc_read_q()` and `irtc_align_q()`: read a Q (item-by-dimension)
  matrix from any supported file format or an R object, with an optional
  partial-credit / maximum-score declaration column. Dimension column
  headers become the dimension names used in all person-level output.
  Alignment against the response data warns on item mismatches and keeps
  the shared items by default, or stops with `on_mismatch = "error"`.
* `irtc(q = , on_mismatch = )`: supply a Q matrix to `irtc()` directly;
  it is aligned and passed to the estimation.
* `irtc_score()` / `irtc()`: `key` and `rules` now also accept file
  paths in any supported format. Answer-key files may carry a
  partial-answer column, giving partial-credit scoring (full = 2,
  partial = 1, other = 0). Consistency between the Q-matrix
  partial-credit declaration and the applied scoring is checked.
* `irtc(rare_categories = )`: robust handling of score categories that
  nobody reached. `"collapse"` (default) merges unobserved categories
  and annotates the mapping; `"prior"` keeps the category structure by
  stabilising the affected thresholds. Items nobody answered keep an
  annotated row in `irtc_results()` instead of silently disappearing.
* GPCM item output now labels the partial-correct and full-correct
  difficulties (`b_partial` / `b_full`, or `b_step1..b_stepK`). Person
  output uses the Q dimension names for ability / standard-error headers.
  `irtc_results()` schema advances to 1.1 (additive only).
* `irtc_report()` gains a Model-diagnostics section (convergence,
  information criteria, EAP reliability bands, item-fit reading) and a
  Data-processing-transparency section (weights, Q alignment, category
  collapses, dropped items, scoring summary, cleaning log).

## Refinements

* `irtc_report()` now creates any missing parent directories of the
  output file, matching `irtc_excel()`.
* Automatic sampling-weight detection no longer treats a bare `w` column
  as weights; it was an undocumented alias that could silently consume a
  binary item column named `w`. Explicit `weights = "w"` still works.

# IRTC 1.0.0

First CRAN release. The estimation core is unchanged from 0.1.0; this
release adds a usability layer for four audiences: survey staff without
statistical training, professional statisticians, AI agents / automated
pipelines, and decision makers receiving the results.

## New features

* `irtc()`: one-stop estimation. Accepts a file path (`.xlsx`, `.xls`,
  `.csv`, `.tsv`, `.txt`, `.dat`, `.sav`, `.por`, `.dta`, `.sas7bdat`,
  `.xpt`) or a data frame/matrix; cleans, optionally scores raw responses
  against an answer key, checks the data, estimates the requested model
  (`model` is required: `"1PL"`/`"Rasch"`, `"2PL"`, `"PCM"`, `"PCM2"`,
  `"RSM"`, `"GPCM"`) and attaches classical statistics, item fit and
  quality ratings. All extra arguments pass through to `irtc.mml()` /
  `irtc.mml.2pl()`, which are unchanged.
* `irtc_read()`: unified import with automatic delimiter and UTF-8/GBK
  encoding detection, person-ID detection (English and Chinese column
  names), missing-code recoding with a range guard, category recoding to
  consecutive 0-based scores, and a bilingual cleaning log.
* `irtc_score()`: answer-key (0/1) and partial-credit rules scoring with
  normalisation of case, whitespace and full-width characters.
* `irtc_check_data()`: pre-estimation diagnostics; returns a
  machine-readable issue table (code / severity / where / bilingual
  message / fix).
* `irtc_ctt()`: item difficulty, corrected item-total correlations,
  Cronbach's alpha and alpha-if-item-deleted.
* `irtc_itemfit()`: infit/outfit mean squares with Wilson-Hilferty t
  statistics, for both the grid and the streaming engine.
* `irtc_quality()`: four-level plain-language item quality ratings
  (good / acceptable / review / revise) with bilingual reasons and advice;
  thresholds are configurable via `irtc_quality_thresholds()`.
* `plain_summary()`: layered plain-language summary (conclusion first).
* `irtc_excel()`: writes three separate Excel workbooks - a plain-language
  item quality table (colour-coded), an item difficulty/discrimination
  table with a frozen schema for cross-year anchor linking, and a flat,
  paste-ready person ability table. Requires the optional 'openxlsx'.
* `irtc_report()`: audience-specific reports (`decision`, `survey`,
  `stat`) as self-contained HTML or Word (optional 'officer'), with
  Wright map, ability distribution, quality summary and ICC figures.
* `plot.irtc()`: `wright`, `ability`, `quality` and `icc` plot types.
* `irtc_results()` / `irtc_json()`: machine-readable results with a
  stable documented schema (see `inst/llms.txt`); JSON export via the
  optional 'jsonlite'.
* Structured conditions: all errors/warnings of the usability layer carry
  classes (`irtc_error`, domain classes) and fields `code`, `reason`,
  `fix`, `data`, enabling programmatic recovery.
* Bilingual output (Chinese default, English via
  `options(irtc.lang = "en")`); machine-readable schemas are
  language-independent.
* `inst/llms.txt`: compact API and schema reference for AI agents.

## Notes

* All new dependencies are optional (Suggests) and requested with an
  actionable installation hint when needed; the estimation core adds no
  hard dependencies beyond 0.1.0 (only 'tools', 'graphics', 'grDevices'
  from base R).

# IRTC 0.1.0

* Initial version: MML estimation for Rasch/1PL, PCM, PCM2, RSM, 2PL and
  GPCM models, unidimensional and between-item multidimensional, with
  latent regression, multiple groups, case weights, EAP person estimates,
  parallel grid engine, bounded-memory streaming engine and an opt-in
  controlled-accuracy quadrature mode with a measured error report.
