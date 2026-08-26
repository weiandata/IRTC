# Changelog

All notable changes to this repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add future changes here before release.

## [1.1.2] - 2026-08-27

Correctness release for the multidimensional streaming estimation path,
prompted by a production survey analysis (85,035 respondents, 10 dichotomous
items, three content dimensions, sampling weights). Item parameters, latent
covariances and EAP estimates are unchanged; reported fit measures and the
weighted classical statistics move. See `NEWS.md` for the user-facing detail
and `docs/internal/1.1.2-field-report-disposition-zh.md` for the
finding-by-finding disposition.

### Fixed

- Streaming engine: `NA` in the response matrix caused an out-of-bounds read in
  the C++ E-step and a segmentation fault. Missing responses are now handled
  natively, as the grid engine handles them.
- Streaming engine: the quadrature weights were the normal density at the nodes
  rather than probability mass, offsetting every reported log-likelihood by
  `n * ndim * log(1 / h)` and invalidating comparisons across dimensionalities,
  engines and node settings.
- Streaming engine: the log-likelihood turned positive (deviance negative) when
  the latent covariance degenerated. Same root cause; reaching the correlation
  boundary now warns with code `W427`.
- Streaming engine: `EAP.rel` ignored the case weights and the posterior error
  variance; it now uses the grid engine's definition.
- `irtc_param_table()` (and `irtc_results()`, `irtc_excel()`) read slopes from
  dimension 1 regardless of the item's loading dimension, reporting
  `slope_a = 0` and `difficulty_b = NA` for most items of a multidimensional
  model. Same fix applied to the grid engine's `item_irt` table.
- Streaming engine: person identifiers passed via `id=` / `pid=` were replaced
  by row numbers, and `person$pweight` was reported as 1 for every case.
- `irtc_ctt()`, `irtc_itemfit()` and `irtc_quality()` ignored the sampling
  weights, mixing weighted IRT parameters with unweighted classical statistics
  in one results table.
- The norm-referenced person columns `percentile` and `t_score` were computed
  unweighted; they now follow the sampling weights, so a percentile reports the
  share of the represented population below that person.
- `irtc_score()` applied the answer key to the wrong option when `irtc_read()`
  had renumbered an item's categories (1..5 to 0..4). The original categories
  are kept and the key is translated, so a key is written in the coding of the
  user's own data file.
- An answer that never occurs among an item's responses is reported (`W205`)
  instead of scoring everyone wrong.
- A numeric person ID could reach `irtc_results()` and the ability workbook in
  scientific notation (`266000000` as `"2.66e+08"`), corrupting the join key.
- Streaming-engine fits stored neither their response data nor their item
  names, so item tables were keyed on generic `I1`..`In` with `p_value = NA`,
  and `irtc_quality()` / `irtc_itemfit()` needed `resp=` passed back in.
- `irtc_param_table()` did not fall back to the model's stored response data,
  so `irtc_excel(mod)` wrote a parameter workbook with no `p_value`.

### Added

- `weights=` on `irtc_ctt()`, `irtc_itemfit()`, `irtc_quality()`,
  `irtc_param_table()`, `irtc_person_table()` and `irtc_results()`; `irtc()`
  propagates the sampling weights to all of them.
- Posterior standard errors from the streaming engine (`SD.EAP.Dim*`), so
  multidimensional fits get the `se_*` columns in `irtc_results()`.
- `dimension` and `n_loadings` columns in the item parameter table for
  multidimensional models.
- Structured error `E409` when the grid path's predicted allocation exceeds the
  session's memory, replacing an opaque `vector memory limit ... reached`.
- `rid` and other respondent/record ID column names are recognised by
  `irtc_read()`'s automatic person-ID detection.
- Regression tests in `tests/testthat/test-streaming-quadrature.R`.

### Changed

- `ic` is a one-row data frame from both engines; the streaming engine
  previously returned a plain list.
- `irtc_results()` schema advances to 1.2 and the `irtc_excel()` linking
  workbook to 1.1. Both additive.

## [1.1.1] - 2026-07-17

Packaging-only release addressing the CRAN incoming pre-test results for
1.1.0. No API and no estimation results change.

### Added

- Add a `Date` field to DESCRIPTION. Without it the package banner printed an
  empty date, as in `IRTC 1.1.0 ()`.

### Fixed

- Build the PDF reference manual without LaTeX errors. Literal CJK
  characters in `irtc_read.Rd`, `irtc_read_q.Rd` and `irtc_score.Rd` have no
  definition in the LaTeX encoding used for the manual. `\usage` now writes
  the affected defaults as `\uxxxx` escapes (identical R strings), and prose
  uses the new `\zh` macro (`man/macros/irtc.Rd`), which renders the Chinese
  characters in HTML/text help and the ASCII escape in the PDF.
- Stop assuming the released R version wording in
  `tests/testthat/test-print-session.R`: `R.version.string` begins
  `"R Under development (unstable)"` on r-devel, which failed the r-devel
  check flavors. The assertions now compare against `R.version.string`.

## [1.1.0] - 2026-07-17

Usability release for the GPCM / multidimensional workflow. The estimation
core (`irtc.mml` / `irtc.mml.2pl`) is unchanged; all new behaviour is in the
usability layer and is backward compatible. No new dependencies.

### Added

- Sampling-weight import in `irtc_read()` / `irtc()`: a `weights =` argument
  plus auto-detection of common weight column names (English and Chinese),
  validated and forwarded as `pweights`.
- Q-matrix (item-by-dimension) import and alignment: `irtc_read_q()`,
  `irtc_align_q()` and `irtc(q = , on_mismatch = )`. Dimension column names
  become the dimension names in all person-level output.
- `key` and `rules` for `irtc_score()` / `irtc()` also accept file paths;
  answer-key files may carry a `partial_answer` column for partial-credit
  scoring (full = 2, partial = 1, other = 0), with a consistency check
  against the Q-matrix partial-credit declaration.
- `rare_categories` handling of unobserved score categories: `"collapse"`
  (default) merges and annotates them, `"prior"` keeps the structure by
  stabilising the affected thresholds. Items nobody answered keep an
  annotated row in `irtc_results()`.
- Semantic GPCM difficulty labels in the item parameter table
  (`b_partial` / `b_full`, or `b_step1..b_stepK`) and Q dimension names in
  the person output. `irtc_results()` schema advances to 1.1 (additive).
- `irtc_report()` gains Model-diagnostics and Data-processing-transparency
  sections, and now creates missing parent directories of the output file.

### Changed

- Automatic sampling-weight detection no longer treats a bare `w` column as
  weights (it could silently consume a binary item named `w`); pass
  `weights = "w"` explicitly for that case.

## [1.0.0] - 2026-07-16

### Added

- Usability layer for four audiences (survey staff, statisticians, AI
  agents, decision makers): one-stop `irtc()` estimation entry point with
  pass-through to the unchanged expert API.
- Multi-format data import `irtc_read()` (Excel, CSV/TSV with delimiter and
  UTF-8/GBK detection, SPSS/Stata/SAS, R objects) with automatic cleaning
  and a bilingual cleaning log.
- Answer-key and partial-credit scoring `irtc_score()`.
- Pre-estimation diagnostics `irtc_check_data()` with machine-readable
  issue table.
- Classical statistics `irtc_ctt()`, item fit `irtc_itemfit()` and
  plain-language quality ratings `irtc_quality()`.
- Layered plain-language summary `plain_summary()`.
- Three-workbook Excel export `irtc_excel()`: item quality (colour-coded),
  item parameters (frozen cross-year linking schema v1.0), person ability
  (flat, paste-ready).
- Audience-specific Word/HTML reports `irtc_report()` and diagnostic plots
  `plot.irtc()` (Wright map, ability, quality, ICC).
- Machine-readable results `irtc_results()` / `irtc_json()` (schema v1.0),
  structured error conditions with code/reason/fix, and `inst/llms.txt`
  for AI agents.
- Bilingual (zh/en) user-facing output via `options(irtc.lang=)`.
- New optional dependencies (Suggests): readxl, writexl, haven, openxlsx,
  officer, jsonlite. New base-R Imports: tools, graphics, grDevices.
- Expanded `inst/COPYRIGHTS` to document the copyright boundary for all direct
  runtime, linking, and optional dependencies.
- Standardized the repository owner identity as WEIAN DATA.

## [0.1.0] - 2026-07-10

### Added

- Import the IRTC R package: marginal maximum likelihood (MML) estimation for
  Rasch/1PL, PCM, RSM, 2PL and GPCM models, unidimensional and between-item
  multidimensional, with latent regression, multiple groups and case weights.
- Add parallelised, dimension-factorised streaming estimation engine with
  `grid`, `streaming` and `auto` computation modes.
- Add opt-in controlled-accuracy quadrature mode with measured approximation
  error reporting (accuracy report).
- Add testthat test suite with regression fixtures.
- Add Chinese and English user manuals under `docs/manuals/`.
- Add CRAN submission guide under `docs/`.
- Add development utility scripts (benchmark, simulation, reference
  generation, correctness and smoke checks) under `scripts/`.
- Add R CMD check workflow.
- Establish GPL (>= 2) licensing and company ownership metadata.
