# IRTC User Manual (English) — V1.1.0

**An R package for item response theory estimation — from complete newcomer to production pipeline**

IRTC is a **self-contained marginal maximum likelihood (MML) estimation** package for item response theory (IRT). It estimates unidimensional and multidimensional Rasch, partial credit (PCM), rating scale (RSM), 2PL, and generalized partial credit (GPCM) models, supports latent regression, multiple groups, and case weights.

## Why IRTC (what sets it apart)

Mainstream IRT packages (TAM, mirt, ltm, ...) assume you are a statistical
programmer: you prepare a clean numeric matrix by hand and dig the results
out of a model object yourself. IRTC covers both ends of the pipeline
as well:

- **Data gets in (input advantage).** Reads Excel (.xlsx/.xls), CSV/TSV
  (delimiter and UTF-8/GBK encoding auto-detected), SPSS (.sav), Stata
  (.dta), SAS (.sas7bdat) and R data frames directly; detects and sets
  aside person-ID and sampling-weight columns, recodes missing codes, and
  scores raw A/B/C/D answers against a key (with an optional
  partial-credit column). A Q matrix and an answer key can both be read
  from files. Every cleaning action is logged and traceable.
- **Results get out (output advantage).** One call writes three
  deliverable-ready Excel workbooks (a colour-coded item quality table, a
  frozen-schema item parameter table for cross-year linking, and a
  paste-ready person ability table) plus Word/HTML reports in three
  audience layouts (decision makers / survey staff / statisticians) — with
  model-diagnostics and data-processing-transparency sections — all
  bilingual (English/Chinese).
- **It is fast (speed advantage).** The estimation core is parallelised
  Rcpp/C++ with SQUAREM/over-relaxation acceleration, and an opt-in
  **controlled-accuracy** mode prunes negligible-weight quadrature nodes
  and reports the **measured** approximation error (exact computation
  remains the default).
- **It scales (scale advantage).** A bounded-memory **streaming engine**
  never materialises the persons-by-nodes posterior matrix, so large
  between-item multidimensional models with millions of responses
  calibrate on an ordinary laptop; engine routing is automatic.
- **Two APIs, four audiences.** Non-specialists run one line —
  `irtc("data.xlsx", model = "1PL")`; statisticians keep the full
  TAM-style expert API (`irtc.mml()`, `irtc.mml.2pl()`); decision makers
  get reports; AI agents get machine-readable results.
- **AI/pipeline-ready.** Frozen-schema tidy results
  (`irtc_results()`/`irtc_json()`), structured error conditions with
  code/reason/fix fields, and a bundled `llms.txt` API digest — one of the
  first IRT packages designed for automated callers.
- **Verifiable quality.** 1191 automated tests, 96% overall code coverage
  (>= 95% on every key module), `R CMD check --as-cran` clean on macOS,
  Windows and Linux CI.

> Six parts: ① Quick start ② Full function reference ③ Mathematics and principles ④ Complete troubleshooting ⑤ References ⑥ End-to-end walkthrough.

---

## Contents

1. [Quick Start Guide](#1-quick-start-guide)
2. [Full Function Reference](#2-full-function-reference) — main workflow in [2.1](#21-the-main-workflow-functions-complete-reference), expert estimation in 2.2-2.5
3. [Mathematics and Principles](#3-mathematics-and-principles)
4. [Complete Troubleshooting Manual](#4-complete-troubleshooting-manual)
5. [References and Bibliography](#5-references-and-bibliography)
6. [End-to-End Walkthrough (the workflow in practice)](#6-end-to-end-walkthrough-the-workflow-in-practice)

---

# 1. Quick Start Guide

## 1.1 What IRT is (one minute)

IRT explains a respondent's answers to test items through a latent **ability** θ. The simplest Rasch model:

> P(correct on item j) = `1 / (1 + exp(-(θ - b_j)))`

Higher ability θ and lower item difficulty b_j mean a higher probability of a correct answer. IRTC's job: given a person × item response matrix, **recover** each item's parameters (difficulty, discrimination) and the distribution of each person's ability.

## 1.2 Installation

```r
# from CRAN (once accepted)
install.packages("IRTC")

# or from a source tarball (contains C++, needs a compiler)
install.packages("path/to/IRTC_1.1.0.tar.gz", repos = NULL, type = "source")
library(IRTC)

# optional helpers, installed on demand (Excel/SPSS import, Excel/Word
# output, JSON): readxl, haven, openxlsx, officer, jsonlite
```

## 1.3 First analysis: one line from file to fitted model

```r
library(IRTC)
mod <- irtc("responses.xlsx", model = "1PL")   # read + clean + check + estimate + rate
plain_summary(mod)                             # plain-language summary, conclusion first
```

`irtc()` reads the file (Excel, CSV/TSV, SPSS, Stata, SAS or a data
frame), detects and sets aside the person-ID column, recodes missing
codes and Likert categories, checks the data, fits the requested model
and attaches item quality ratings. `model` is required — right/wrong
items: `"1PL"` or `"2PL"`; partial-credit or rating items: `"PCM"` or
`"GPCM"`. Raw A/B/C/D answers? Add `key = c(Q1 = "A", Q2 = "C", ...)`, or
point `key =` at an answer-key file (add a `partial_answer` column for
partial credit). Multidimensional? Pass a Q matrix with `q = "qmatrix.xlsx"`
(its dimension column names flow into the results). Sampling weights in the
data file are detected automatically, or name the column with `weights =`.

## 1.4 Deliverables: Excel tables, reports, plots

```r
irtc_excel(mod, dir = "results")     # 3 workbooks: quality / parameters / abilities
irtc_report(mod, "report.docx", audience = "decision")   # 1-2 page executive summary
irtc_report(mod, "report.html", audience = "stat")       # full technical report
plot(mod, type = "wright")           # also "ability", "quality", "icc"
mod$usability$quality                # per-item rating with reasons and advice
```

## 1.5 The expert path (unchanged TAM-style API)

Statisticians can call the estimation functions directly on a prepared
numeric matrix — every advanced option (latent regression, groups,
weights, fixed parameters, custom designs) lives here, and `irtc()`
passes all of them through via `...`:

```r
data(data.sim.rasch)                    # bundled: 2000 persons x 40 items, 0/1
mod  <- irtc.mml(resp = data.sim.rasch)                    # Rasch/1PL
mod2 <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL")
summary(mod2)
anova(mod, mod2)                        # likelihood-ratio comparison
```

## 1.6 Standard ways to read results

```r
plain_summary(mod)   # conclusion-first text (zh/en)
summary(mod)         # full technical summary
mod$xsi              # item parameters (difficulties)
mod$person$EAP       # per-person ability estimates
irtc_results(mod)    # frozen-schema tidy data frames (pipelines/AI)
```

## 1.7 Speed and scale: the streaming engine for big data

For large, multidimensional, simple-structure data, let the engine pick
the fastest path and optionally enable controlled-accuracy acceleration:

```r
mod_fast <- irtc("big.csv", model = "GPCM", Q = Qmatrix,
  method = "auto",                                    # auto-select grid / streaming
  control = list(fast = TRUE, mass_budget = 1e-3))    # accuracy-controlled pruning
mod_fast$routing            # which engine and why
mod_fast$accuracy_report    # measured approximation error (met=TRUE = within tolerance)
```

---

# 2. Full Function Reference

IRTC 1.1.0 exports the **main workflow functions** (2.1 — start here),
the **expert estimation functions** `irtc.mml()` / `irtc.mml.2pl()`
(2.2-2.5) and **6 S3 methods** (`summary`, `print`, `logLik`, `anova`,
`plot`, plus class-specific `print` methods).

## 2.1 The main workflow functions (complete reference)

These functions are the primary interface of IRTC. Details: `?function_name` in R. Output
language for all user-facing text: `options(irtc.lang = "zh")` (default) or
`"en"`; machine-readable schemas never depend on it (`irtc_lang()` shows the
current setting).

| Layer | Function | Purpose |
| --- | --- | --- |
| One-stop | `irtc()` | file/data frame -> clean -> score -> check -> estimate -> quality ratings |
| Data | `irtc_read()` | multi-format import with automatic cleaning and a bilingual log |
| Data | `irtc_score()` | answer-key (0/1) or rules-table (partial credit) scoring |
| Data | `irtc_check_data()` | pre-estimation diagnostics with machine-readable fixes |
| Statistics | `irtc_ctt()` | classical difficulty, item-rest correlations, Cronbach's alpha |
| Statistics | `irtc_itemfit()` | infit/outfit mean squares with Wilson-Hilferty t |
| Statistics | `irtc_quality()` | four-level plain-language item ratings with reasons and advice |
| Output | `plain_summary()` | layered plain-language summary, conclusion first |
| Output | `irtc_excel()` | three Excel workbooks: quality / linking parameters / abilities |
| Output | `irtc_param_table()` / `irtc_person_table()` | the underlying data frames (no openxlsx needed) |
| Output | `irtc_report()` | Word/HTML reports for decision / survey / stat audiences |
| Output | `plot()` (plot.irtc) | Wright map, ability histogram, quality summary, ICC curves |
| AI | `irtc_results()` / `irtc_json()` | frozen-schema tidy results (v1.0) and JSON export |

### `irtc(data, model, key = NULL, rules = NULL, q = NULL, on_mismatch = c("warn","error"), rare_categories = c("collapse","prior"), id = NULL, weights = NULL, sheet = 1, missing_codes = c(-9, -99, 99, 999), check = TRUE, quality = TRUE, verbose = TRUE, ...)`

`data` is a file path (.xlsx/.xls/.csv/.tsv/.txt/.dat/.sav/.por/.dta/
.sas7bdat/.xpt), a data frame/matrix, or an `irtc_read()` result. `model`
is **required**: `"1PL"` (= `"Rasch"`), `"2PL"`, `"PCM"`, `"PCM2"`,
`"RSM"`, `"GPCM"` (case-insensitive). `key`/`rules` accept a vector/data
frame **or a file path**; an answer-key file with a `partial_answer`
column gives partial credit (full = 2 / partial = 1 / other = 0). `q` is a
Q matrix (see `irtc_read_q()`), aligned to the data (`on_mismatch` =
`"warn"` keeps the shared items, `"error"` stops); its dimension names
become the person-output column names. `rare_categories` handles score
categories nobody reached: `"collapse"` (default, merges and annotates)
or `"prior"` (keeps the structure, stabilises the thresholds). `weights`
names the sampling-weight column (auto-detected otherwise) and is used as
`pweights`. `...` passes through to `irtc.mml()` / `irtc.mml.2pl()`
unchanged, so every expert argument still works (including the uppercase
`Q =` loading-matrix pass-through). Returns a standard `irtc` object plus
`$usability` (cleaning log, check result, CTT, item fit, quality ratings,
Q alignment, weights, rare-category info). Unusable items (all-missing or
zero-variance) are removed with warning `W410` and kept as an annotated
row (`status`) in `irtc_results()`.

### `irtc_read(x, sheet = 1, id = NULL, weights = NULL, missing_codes = c(-9, -99, 99, 999), na_strings = ..., guess_id = TRUE, guess_weights = TRUE, clean = TRUE, recode = TRUE, verbose = TRUE)`

Delimiter (comma/tab/semicolon/pipe) and encoding (UTF-8, UTF-8-BOM,
GBK/GB18030) are detected automatically. Negative missing codes are always
recoded to NA; positive codes only when clearly outside the observed
response range (protects a legitimate 99 on a 0-100 scale). With
`recode = TRUE`, integer categories become consecutive 0-based scores
(1-5 Likert -> 0-4), logged per item. `weights` names the sampling-weight
column; with `guess_weights = TRUE` (default) common weight column names
(`weight`, `wt`, `pweight`, `权重`, ...; the single letter `w` is excluded
and must be named explicitly) are detected, validated (positive; missing
set to 1 with a warning) and set aside as `$weights`. Returns an
`irtc_data` object with `$resp`, `$pid`, `$weights` and the bilingual
`$log`.

### `irtc_score(resp, key = NULL, rules = NULL, na_as_wrong = FALSE, sheet = 1)`

`key` is a named vector such as `c(Q1 = "A", Q2 = "C")` **or an answer-key
file** (an `item`/`题目` column plus an `answer`/`答案` column); case,
whitespace and full-width characters are normalised. Add a
`partial_answer`/`部分正确答案` column (several answers separated by
`|`, `;`, `,` or `、`) for partial credit: full = 2, partial = 1, other =
0. `rules` is a data frame or file (item, response, score) for arbitrary
partial credit; responses without a rule become NA with warning `W207`.

### `irtc_read_q(x, sheet = 1)`

Reads a Q (item-by-dimension) matrix from a file, a data frame, or a
numeric matrix with item row names. An item column (`item`/`题目`, ...) is
detected; the remaining columns are dimensions and **their names become
the dimension names**. An optional partial-credit / maximum-score column
(`partial`/`max_score`, ...) declares which items are polytomous and their
maximum score. Returns an `irtc_qmatrix` object (`$Q`, `$partial`,
`$max_score`, `$log`).

### `irtc_align_q(data, q, on_mismatch = c("warn","error"))`

Aligns a Q matrix (an `irtc_qmatrix` or anything `irtc_read_q()` accepts)
to the response data by item name and in the same order. Items on only one
side are reported: `"warn"` keeps the shared items (`W420`/`W421`),
`"error"` stops (`E422`); fewer than two shared items is an error.

### `irtc_check_data(x, key = NULL, verbose = TRUE)`

Checks sizes, non-numeric columns, negative/non-integer values,
zero-variance items, extreme missingness, sparse categories, all-missing
persons and duplicated IDs. Returns `$ok` plus an `$issues` data frame
(code, severity, where, bilingual message and fix) that automated callers
can act on row by row.

### `irtc_ctt(x, key = NULL)` / `irtc_itemfit(mod, resp = NULL)` / `irtc_quality(mod, resp = NULL, thresholds = NULL)`

Classical statistics; residual-based infit/outfit at the EAP estimates
(ideal 1.0, normal range 0.7-1.3); and the combined four-level rating
(good / acceptable / review / revise) with bilingual reasons and advice.
Negative discrimination (usually a wrong key) always yields "revise".
Defaults come from `irtc_quality_thresholds()` and can be overridden.

### `plain_summary(mod, lang = irtc_lang())`

Prints conclusion -> analysis overview -> item quality -> ability
distribution -> next steps, in plain language.

### `irtc_excel(mod, dir = ".", prefix = "IRTC", lang = irtc_lang(), resp = NULL, overwrite = FALSE, verbose = TRUE)`

Writes three separate .xlsx files (requires openxlsx):
`*_item_quality.xlsx` (colour-coded ratings + advice + notes sheet),
`*_item_parameters.xlsx` (frozen schema v1.0 - merge anchor items across
years on `item_id`), `*_person_ability.xlsx` (rows stay in input order).
For polytomous items the parameter table labels the step difficulties
semantically: `b_partial` / `b_full` for three-category items,
`b_step1..b_stepK` for more, plus `categories_unobserved` /
`categories_collapsed` when some category was never reached. Existing files
require `overwrite = TRUE` (error `E501` otherwise).

### `irtc_report(mod, file, format = NULL, audience = c("survey", "decision", "stat"), lang = irtc_lang(), ...)`

`.html` output is a fully self-contained single file (no extra
dependencies); `.docx` requires officer. The decision layout is a 1-2 page
executive summary; survey is a plain-language full report; stat adds
parameter, fit and model-information tables plus ICC curves. The survey and
stat layouts also carry a **model-diagnostics** section (convergence,
AIC/BIC, EAP-reliability bands, item-fit reading) and a
**data-processing-transparency** section (weights, Q alignment, category
collapses, dropped items, scoring summary, cleaning log). Missing parent
directories of the output file are created automatically.

### `plot(mod, type = c("wright", "ability", "quality", "icc"), lang = irtc_lang(), items = NULL)`

The same base-graphics figures that the reports embed; `type = "icc"`
accepts an `items =` selection (unidimensional models).

### `irtc_results(mod, resp = NULL)` / `irtc_json(mod, file = NULL, resp = NULL, pretty = TRUE)`

Five frozen-schema data frames: `model_info`, `items` (parameters + CTT +
fit + ratings + `status` and rare-category annotations), `persons`,
`cleaning_log`, `check_issues`. Column names are fixed English snake_case
regardless of the language option; with a Q matrix the per-dimension
ability/SE columns use the dimension names (`eap_<dim>` / `se_<dim>`). The
schema version advances to 1.1 (additive only — existing columns are
unchanged). Full schema reference: `inst/llms.txt` inside the installed
package.

### Structured conditions

Every error/warning of the usability layer carries `$code`, `$reason`,
`$fix` and `$data`, with domain classes for programmatic handling:
`tryCatch(expr, irtc_error = function(e) e$code)`. Code ranges: E0xx
missing dependency, E1xx reading, E2xx scoring, E3xx validation, E4xx
estimation, E5xx export/report.

## 2.2 `irtc.mml()` — fixed-slope models (Rasch / PCM / RSM)

**Purpose**: models with slope fixed to 1 (1PL/Rasch, PCM, RSM), uni- or multidimensional.

**Key arguments**:

| Argument | Meaning | Default |
|---|---|---|
| `resp` | response matrix/data frame (person × item), `NA` = missing | required |
| `irtmodel` | `"1PL"`/`"PCM"`/`"PCM2"`/`"RSM"` | `"1PL"` |
| `Q` | loading (Q) matrix: item × dimension | `NULL` (unidim) |
| `ndim` | number of dimensions (if no Q) | `1` |
| `Y` | covariate matrix for latent regression (person × covariate) | `NULL` |
| `group` | grouping vector (length = N) | `NULL` |
| `pweights` | case weights (length N, non-negative) | `NULL` |
| `xsi.fixed` | fix some item parameters | `NULL` |
| `variance.fixed` | fix (co)variance elements | `NULL` |
| `est.variance` | whether to estimate the variance | `TRUE` |
| `verbose` | print iteration progress | `TRUE` |
| `control` | control list (see 2.5) | `list()` |

**Returns**: an `irtc` object with `xsi` (item parameters), `person` (per-person EAP), `variance`, `beta` (regression coefficients), `ic` (AIC/BIC), `deviance`, etc.

```r
# multidim PCM: items 1-4 load dim 1, items 5-8 load dim 2
Q <- cbind(c(1,1,1,1,0,0,0,0), c(0,0,0,0,1,1,1,1))
m <- irtc.mml(resp = dat, irtmodel = "PCM", Q = Q)

m <- irtc.mml(resp = dat, Y = cbind(1, X))     # latent regression
m <- irtc.mml(resp = dat, pweights = w)        # case weights
```

> The uppercase `Q =` here is the raw loading-matrix pass-through. Through
> `irtc()` prefer the lowercase `q =` (a file or data frame with an item
> column and named dimension columns): it aligns the Q matrix to the data
> and carries the dimension names into the results.

## 2.3 `irtc.mml.2pl()` — models with discrimination (2PL / GPCM)

**Purpose**: estimable slopes — 2PL, GPCM and variants (GPCM.design, 2PL.groups, GPCM.groups). **This is the entry point to the streaming engine.**

**Additional / key arguments**:

| Argument | Meaning | Default |
|---|---|---|
| `irtmodel` | `"2PL"`/`"GPCM"`/`"GPCM.design"`/`"2PL.groups"`/`"GPCM.groups"` | `"2PL"` |
| `method` | engine: `"auto"`/`"grid"`/`"streaming"` | `"auto"` |
| `est.slopegroups` | groups of items sharing a discrimination | `NULL` |
| `E` | design matrix for slopes (GPCM.design) | `NULL` |
| `control` | see 2.5 — streaming / acceleration settings live here | `list()` |

**The three engines**:
- `"grid"`: standard full-quadrature; works for any supported model; robust.
- `"streaming"`: dimension-factorized streaming engine for large, between-item (simple-structure) 2PL/GPCM; bounded memory; supports covariates/groups/weights; errors on unsupported models.
- `"auto"` (default): predicts which is faster from `(N, items, dims, nodes, unique covariate patterns)` and routes accordingly; the result carries `$routing` explaining the choice.

```r
m <- irtc.mml.2pl(resp = dat, irtmodel = "GPCM", Q = Q)   # auto
m$routing                                                  # chosen engine

# force streaming + multiple groups (per-group covariance, shared item params)
m <- irtc.mml.2pl(resp = dat, irtmodel = "2PL", Q = Q,
                  group = grp, method = "streaming")
m$variance     # a list with multiple groups: one covariance per group
m$gmean        # group ability means (reference group fixed at 0)
```

## 2.4 S3 methods

| Method | Effect |
|---|---|
| `summary(obj)` | readable summary of item parameters, variance, information criteria |
| `print(obj)` | brief printout |
| `logLik(obj)` | log-likelihood (with df); works with `AIC()`/`BIC()` |
| `anova(obj1, obj2)` | likelihood-ratio test of two nested models |

## 2.5 Full `control` list

| Item | Meaning | Default |
|---|---|---|
| `nodes` | quadrature nodes per dimension | `seq(-6,6,len=21)` |
| `maxiter` | max EM iterations | `1000` |
| `conv` | parameter convergence threshold | `1e-4` |
| `convD` | deviance convergence threshold | `1e-3` |
| `Msteps` | inner iterations per M-step | `4` |
| `acceleration` | EM acceleration: `"none"`/`"squarem"`/`"Ramsay"`/`"Yu"` | `"none"` |
| `ridge` | covariance ridge (numerical stability) | `0` |
| **`n_threads`** | parallel threads (streaming E-step / slope M-step) | all cores |
| **`fast`** | enable approximate acceleration (node pruning) | `FALSE` |
| **`mass_budget`** | controlled-accuracy mass budget ε (a pruning budget, **not a guaranteed error**) | `1e-3` |
| **`verify`** | post-acceleration check: `"stratified"`/`"random"`/`FALSE` | `"stratified"` |
| `verify_n` | verification subsample size | `3000` |
| `verify_seed` | verification sampling seed (reproducibility) | `1` |
| `refine` | refit with a tighter ε if the check fails | `FALSE` |
| `tol_deviance`/`tol_eap`/`tol_moment`/`tol_par` | per-metric verification tolerances | see §3.6 |
| **`reg`** | statistical regularization (streaming): `slope_penalty`, `slope_max`, `sigma_shrink`, `sigma_shrink_pooled` | off |
| `group_structure` | per-group covariance: `"full"` (independent) / `"mean"` (shared cov, free group means) | `"full"` |

```r
m <- irtc.mml.2pl(resp = dat, irtmodel = "GPCM", Q = Q,
       control = list(fast = TRUE, mass_budget = 1e-3,
                      verify = "stratified", verify_n = 3000, refine = TRUE))
m$accuracy_report$met         # TRUE = measured error within tolerance
m$accuracy_report$eap_abs     # EAP error: median / 95th pct / max
```

---

# 3. Mathematics and Principles

## 3.1 Measurement models

Let respondent p have a D-dimensional ability vector **θ**_p; item j loads on dimension d(j) (simple structure).

**Rasch / 1PL (binary)**:
> P(X_pj = 1 | θ) = exp(θ_{d(j)} − b_j) / (1 + exp(θ_{d(j)} − b_j))

**2PL (binary, discrimination a_j)**:
> P(X_pj = 1 | θ) = exp(a_j(θ_{d(j)} − b_j)) / (1 + exp(a_j(θ_{d(j)} − b_j)))

**GPCM (K categories, k = 0,…,K−1)**: with cumulative thresholds `cb_k = Σ_{m≤k} b_{jm}` and `η_k = a_j(k·θ_{d(j)} − cb_k)`,
> P(X_pj = k | θ) = exp(η_k) / Σ_m exp(η_m)

PCM is GPCM with a_j ≡ 1; RSM is PCM with a threshold structure shared across items.

## 3.2 Latent distribution and latent regression

Abilities follow a multivariate normal prior:
> **θ**_p ~ N(**Y**_p **β**, **Σ**)

- No covariates ⇒ mean zero.
- **Latent regression**: covariates **Y**_p predict the ability mean through **β**.
- **Multiple groups**: each group g has its own mean and covariance **Σ**_g (item parameters shared across groups as the anchor).

## 3.3 Marginal maximum likelihood (MML)

Integrating out the latent ability gives the marginal likelihood of respondent p:
> L_p = ∫ [∏_j P(X_pj | θ)] · φ(θ; **Y**_p **β**, **Σ**) dθ

Total log-likelihood = Σ_p w_p log L_p (w_p = case weight). Maximized via EM.

## 3.4 The EM algorithm (Bock–Aitkin)

- **E-step**: compute each respondent's posterior over a quadrature grid; accumulate expected item-category counts `n_{jk}(θ)` and the latent moments.
- **M-step**: given the expected counts, update
  - item parameters (safeguarded Newton with **analytic gradient + observed Hessian**, line search, BFGS fallback);
  - regression coefficients **β** (weighted least squares / QR, with automatic collinearity detection);
  - covariance **Σ** (from the **full posterior second moments**, not by treating EAPs as observed — the latter systematically underestimates the variance).
- Iterate to deviance convergence. Optional **SQUAREM** acceleration (extrapolation from three consecutive iterates with a monotonicity fallback).

## 3.5 Curse of dimensionality; the streaming engine

A full D-dimensional grid has `Q^D` nodes — exponential in D. For **between-item (simple-structure)** models the likelihood factorizes per dimension into `L_d(θ_d)`. IRTC's **streaming E-step**:

- compute per-dimension likelihoods (cost ~ N·I·Q);
- scatter the joint over the `Q^D` grid into D one-dimensional marginals and the moments of Σ, **streamed per person** (memory essentially independent of N).

Cost model (per iteration): `t_grid ∝ N·I·Q^D` vs `t_stream ∝ N·I·Q + N·Q^D·D`. The `auto` router chooses by predicted time (not by memory).

## 3.6 Controlled-accuracy acceleration (`fast` mode)

The full `Q^D` grid can still be large. `fast` mode prunes nodes by a **mass budget ε** (`mass_budget`):

- **importance = prior mass + sample posterior mass**: pruning by prior alone would drop nodes with low prior but high likelihood for extreme responders, so a representative subsample's posterior occupancy protects them.
- **each (covariate, group) pattern retains ≥ 1−ε of its mass; the union is kept**, so small special groups are not masked by large ones.
- a few full-grid burn-in iterations precede pruning; the keep-set is recomputed each iteration as the distribution moves.

**ε is not a guaranteed error**, only a budget of discarded mass. The real guarantee is a **stratified, measured check**: at the final parameters, a full-grid vs pruned-grid E-step over a stratified subsample (ordinary, small groups, high weight, extreme responders, high missingness) reports the **median / 95th-percentile / max** of

> deviance relative error, EAP absolute error, posterior-moment error, and one-M-step parameter change,

against per-metric tolerances `tol_*`, with a `met` verdict (all four 95th-percentiles within tolerance); a `warning` if not met; `refine=TRUE` tightens ε and **refits** until met.

## 3.7 Identification (conventions)

- **Scale**: latent covariance diagonal fixed to 1 (`diag(Σ)=1`), correlations free.
- **Location**: with an intercept, the reference group's intercept is fixed to 0; in multiple groups the reference group is N(0, correlation matrix) and the others have free means and variances.
- Item parameters are shared across groups — the backbone of multiple-group identification.

## 3.8 Information criteria

`AIC = -2·logL + 2·p`, `BIC = -2·logL + p·log(N_eff)`, with p free parameters; under weights, N_eff is the Kish effective sample size `(Σw)²/Σw²`.

---

# 4. Complete Troubleshooting Manual

## 4.0 Start here: the error-code system

Every error and warning raised by the workflow layer carries a code, a
reason and a **Fix** line — follow the fix first. Code ranges:

| Range | Stage | Typical example |
| --- | --- | --- |
| E001 | missing optional package | run the suggested `install.packages(...)` and retry |
| E1xx | reading files | E103 file not found; E105 unsupported extension |
| E2xx | answer-key scoring | E204 key item not present in the data |
| E3xx | data checks | E305 text columns (supply `key=`); E308 negative values |
| E4xx | estimation | E406 missing `model=`; E407 data check failed (with issue list); E408 estimation failed |
| E5xx | export/reports | E501 file exists (use `overwrite=TRUE`) |

Programmatic handling: `tryCatch(expr, irtc_error = function(e) e$code)`.
The sections below cover engine-level problems, which mostly arise when
calling the expert functions directly on hand-prepared matrices.


The tables below cover every error/warning IRTC raises plus common IRT estimation pitfalls. **Left column: what you see (or observe); right: cause and fix.**

## 4.1 Input and arguments

| Message / symptom | Cause and fix |
|---|---|
| `pweights must be non-negative, finite, length N, not all zero.` | Illegal weights. Check length = N, no negatives/NA, not all zero. |
| `Y contains missing values; resolve them before estimation.` | Covariate `Y` has `NA`. Impute or delete before estimating (covariate missingness is not handled silently). |
| `group contains missing values; resolve them before estimation.` | Grouping vector has `NA`. Fill in or drop those persons. |
| `pweights contains missing values; resolve them before estimation.` | Weights contain `NA`. Same handling. |
| `extreme case weights (max/mean > 50).` (warning) | Highly uneven weights; a few high-weight cases may dominate. Verify the weights; consider winsorizing extremes. Results are still returned but interpret with care. |
| `collinear covariates (columns ...) are not identified.` (warning) | `Y` has collinear columns (e.g., duplicates). Those coefficients are unidentified and set to zero. Remove redundant covariates. |

## 4.2 Engine and routing

| Message / symptom | Cause and fix |
|---|---|
| `method='streaming' unsupported for this model (within-item / non-simple structure); use method='grid'.` | The streaming engine supports only between-item (one dimension per item) 2PL/GPCM. Your model is within-item / non-simple. Use `method="grid"`, or make Q simple-structure. |
| `Multiple group estimation is not (yet) supported for ...` (grid path) | The grid engine does not support **multidimensional multiple-group** models. Use `method="streaming"` (which does), or reduce to one dimension. |
| `auto` picked grid but you expected streaming | Read `$routing$reason`. Routing chooses by **predicted speed**, not memory. Force `method="streaming"` if you know better. |
| `accuracy verification did not meet tolerance; see accuracy_report.` (warning) | Pruning too aggressive. (1) Lower `mass_budget` (e.g., 1e-4); (2) set `refine=TRUE` to auto-tighten and refit; (3) inspect `accuracy_report` for the offending metric/percentile. |
| `fast mode kept >70% of nodes; speed benefit is limited.` (message) | Pruning saves little here; you take approximation risk for small gain. Prefer `fast=FALSE` (exact full grid). |

## 4.3 Numerical and convergence

| Message / symptom | Cause and fix |
|---|---|
| Non-convergence / hits `maxiter` | (1) Raise `control$maxiter`; (2) enable `control$acceleration="squarem"`; (3) weak identifiability (few items/persons, high dimensions) — simplify or add items. |
| Singular / non-positive-definite covariance | The streaming engine already projects to the nearest PD; if still odd: (1) add `control$ridge`; (2) for small groups use `reg = list(sigma_shrink_pooled = 0.3)` to shrink toward the pooled covariance; (3) check that every dimension has loading items. |
| Discrimination a blows up | Near-perfect discrimination (data separation). Bound it with `reg = list(slope_max = 6)` or penalize via `slope_penalty` (streaming Layer-B regularization; it changes the objective and is flagged). |
| A category never chosen → degenerate | Zero-count GPCM category; its threshold is unidentified. Collapse the category or check scoring; the streaming engine has numerical guards against crashing. |
| Correlated-ability recovery only moderate vs truth | This is the **data's inherent identifiability**, not a bug. The criterion is "streaming ≈ full grid", not "close to truth". |
| ~1e-8 jitter across thread counts | The streaming kernel partitions persons across threads and reduces, so floating-point order depends on the thread count. Fix `n_threads` for bit-reproducibility, or use `method="grid"` for bit-identical-across-threads. |

## 4.4 Installation and compilation

| Message / symptom | Cause and fix |
|---|---|
| Compilation fails on install | Missing C++ toolchain: macOS `xcode-select --install`; Windows install Rtools; Linux install `r-base-dev`. |
| `CXX_STD` / C++17 errors | Upgrade R (≥ 3.5) and the compiler; the package requires C++17. |
| `RcppArmadillo` not found | `install.packages(c("Rcpp","RcppArmadillo"))` then reinstall. |

---

# 5. References and Bibliography

**Foundations and models**
- Lord, F. M. (1980). *Applications of Item Response Theory to Practical Testing Problems.* Erlbaum.
- Rasch, G. (1960). *Probabilistic Models for Some Intelligence and Attainment Tests.*
- Birnbaum, A. (1968). Latent trait models. In Lord & Novick (Eds.), *Statistical Theories of Mental Test Scores.* (2PL/3PL)
- Masters, G. N. (1982). A Rasch model for partial credit scoring. *Psychometrika, 47*, 149–174. (PCM)
- Andrich, D. (1978). A rating formulation for ordered response categories. *Psychometrika, 43*, 561–573. (RSM)
- Muraki, E. (1992). A generalized partial credit model. *Applied Psychological Measurement, 16*, 159–176. (GPCM)

**Estimation (MML / EM / multidimensional)**
- Bock, R. D., & Aitkin, M. (1981). Marginal maximum likelihood estimation of item parameters. *Psychometrika, 46*, 443–459.
- Adams, R. J., Wilson, M., & Wang, W. (1997). The multidimensional random coefficients multinomial logit model. *Applied Psychological Measurement, 21*, 1–23.
- Gibbons, R. D., & Hedeker, D. (1992). Full-information item bifactor analysis. *Psychometrika, 57*, 423–436.
- Schilling, S., & Bock, R. D. (2005). High-dimensional MML item factor analysis by adaptive quadrature. *Psychometrika, 70*, 533–555.
- Varadhan, R., & Roland, C. (2008). Accelerating the convergence of EM (SQUAREM). *Scandinavian Journal of Statistics, 35*, 335–353.

**Numerical integration**
- Smolyak, S. A. (1963). Quadrature and interpolation formulas for tensor products. (sparse grids — a future lever)

**Software**
- Chalmers, R. P. (2012). mirt. *Journal of Statistical Software, 48*(6).
- Eddelbuettel, D., & François, R. (2011). Rcpp. *Journal of Statistical Software, 40*(8).

**Textbooks**
- de Ayala, R. J. (2009). *The Theory and Practice of Item Response Theory.* Guilford.
- Embretson, S. E., & Reise, S. P. (2000). *Item Response Theory for Psychologists.* Erlbaum.
- van der Linden, W. J. (Ed.) (2016). *Handbook of Item Response Theory* (3 vols). CRC Press.


*This manual corresponds to IRTC 0.1.0. Function signatures are authoritative in the package help pages `?irtc.mml` and `?irtc.mml.2pl`.*

# 6. End-to-End Walkthrough (the workflow in practice)

This chapter walks the main workflow end to end for three audiences: survey staff without statistical training, automated
pipelines / AI agents, and decision makers who receive the results. The
expert API is unchanged; everything here is optional.

Output language: `options(irtc.lang = "zh")` (default) or `"en"`.

## 6.1 One line from file to fitted model

```r
mod <- irtc("responses.xlsx", model = "1PL")
```

`irtc()` reads the file (Excel, CSV/TSV with automatic delimiter and
UTF-8/GBK detection, SPSS/Stata/SAS via haven, or a data frame), detects
and sets aside the person-ID column, cleans the data (missing codes,
text-to-number, category recoding — every action logged), checks it,
estimates the requested model and attaches classical statistics, item fit
and quality ratings. `model` is required; raw A/B/C/D answers are scored
with `key = c(Q1 = "A", ...)`. Extra arguments (e.g. `group`, `control`)
pass straight to `irtc.mml()` / `irtc.mml.2pl()`.

## 6.2 Check first, then estimate

```r
chk <- irtc_check_data(irtc_read("responses.csv"))
chk$ok        # TRUE / FALSE
chk$issues    # code, severity, where, bilingual message and fix
```

## 6.3 Plain-language results

```r
plain_summary(mod)            # layered summary, conclusion first
mod$usability$quality         # good / acceptable / review / revise per item
plot(mod, type = "wright")    # also: "ability", "quality", "icc"
```

## 6.4 The three Excel workbooks

```r
irtc_excel(mod, dir = "results")
```

Writes three separate .xlsx files (needs the openxlsx package): an item
quality table anyone can read (colour-coded ratings with reasons and
advice), an item parameter table with a frozen column schema for
cross-year anchor-item linking (merge on `item_id`), and a flat person
ability table whose rows stay in input order for pasting into a master
sample sheet. Each workbook has a "Notes" sheet explaining every column.

## 6.5 Reports for each audience

```r
irtc_report(mod, "report.docx", audience = "decision")  # 1-2 page summary
irtc_report(mod, "report.html", audience = "survey")    # plain language
irtc_report(mod, "report.html", audience = "stat")      # full technical
```

HTML reports are single self-contained files; Word needs the officer
package.

## 6.6 For pipelines and AI agents

```r
res <- irtc_results(mod)   # tidy data frames, stable schema v1.0
irtc_json(mod, "results.json")
```

All errors and warnings of the usability layer are structured conditions
with `$code`, `$reason`, `$fix` and `$data`; see `inst/llms.txt` for the
complete code list and schema reference.
