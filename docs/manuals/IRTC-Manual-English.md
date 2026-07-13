# IRTC User Manual (English)

**An R package for item response theory estimation — for the complete newcomer**

IRTC is a **self-contained marginal maximum likelihood (MML) estimation** package for item response theory (IRT). It estimates unidimensional and multidimensional Rasch, partial credit (PCM), rating scale (RSM), 2PL, and generalized partial credit (GPCM) models, supports latent regression, multiple groups, and case weights, and ships a parallel **streaming estimation engine** with a **controlled-accuracy** acceleration mode that can calibrate millions of respondents on an ordinary laptop.

> Five parts: ① Quick start ② Full function reference ③ Mathematics and principles ④ Complete troubleshooting ⑤ References.

---

## Contents

1. [Quick Start Guide](#1-quick-start-guide)
2. [Full Function Reference](#2-full-function-reference)
3. [Mathematics and Principles](#3-mathematics-and-principles)
4. [Complete Troubleshooting Manual](#4-complete-troubleshooting-manual)
5. [References and Bibliography](#5-references-and-bibliography)

---

# 1. Quick Start Guide

## 1.1 What IRT is (one minute)

IRT explains a respondent's answers to test items through a latent **ability** θ. The simplest Rasch model:

> P(correct on item j) = `1 / (1 + exp(-(θ - b_j)))`

Higher ability θ and lower item difficulty b_j mean a higher probability of a correct answer. IRTC's job: given a person × item response matrix, **recover** each item's parameters (difficulty, discrimination) and the distribution of each person's ability.

## 1.2 Installation

```r
# from source (contains C++, needs a compiler)
install.packages("path/to/IRTC_0.1.0.tar.gz", repos = NULL, type = "source")
library(IRTC)
```

## 1.3 First example: Rasch model (5 lines)

```r
library(IRTC)
data(data.sim.rasch)                    # bundled: 2000 persons x 40 items, 0/1
mod <- irtc.mml(resp = data.sim.rasch)  # estimate 1PL/Rasch (default)
summary(mod)                            # item params, ability variance, AIC/BIC
```

## 1.4 Second example: 2PL (with discrimination)

```r
mod2 <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL")
summary(mod2)        # each item now also has a discrimination a_j
```

## 1.5 Third example: multidimensional + GPCM (polytomous)

```r
data(data.gpcm)
Q <- matrix(1, nrow = ncol(data.gpcm), ncol = 1)   # loading (Q) matrix
mod3 <- irtc.mml.2pl(resp = data.gpcm, irtmodel = "GPCM", Q = Q)
summary(mod3)
```

## 1.6 Standard ways to read results

```r
mod$xsi          # item parameters (intercepts / difficulties)
mod$person       # per-person ability point estimates (EAP)
mod$variance     # ability (co)variance
logLik(mod)      # log-likelihood
anova(mod, mod2) # likelihood-ratio test of two nested models
```

## 1.7 Speed: the streaming engine for big data

For large, multidimensional, simple-structure data, let the engine pick the fastest path and optionally enable approximate acceleration:

```r
mod_fast <- irtc.mml.2pl(
  resp = big_resp, irtmodel = "GPCM", Q = Qmatrix,
  method = "auto",                                    # auto-select grid / streaming
  control = list(fast = TRUE, mass_budget = 1e-3)     # controlled-accuracy acceleration
)
mod_fast$routing            # which engine and why
mod_fast$accuracy_report    # measured approximation error (met=TRUE = within tolerance)
```

---

# 2. Full Function Reference

IRTC exports **2 estimation functions** and **4 S3 methods**.

## 2.1 `irtc.mml()` — fixed-slope models (Rasch / PCM / RSM)

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
| `control` | control list (see 2.4) | `list()` |

**Returns**: an `irtc` object with `xsi` (item parameters), `person` (per-person EAP), `variance`, `beta` (regression coefficients), `ic` (AIC/BIC), `deviance`, etc.

```r
# multidim PCM: items 1-4 load dim 1, items 5-8 load dim 2
Q <- cbind(c(1,1,1,1,0,0,0,0), c(0,0,0,0,1,1,1,1))
m <- irtc.mml(resp = dat, irtmodel = "PCM", Q = Q)

m <- irtc.mml(resp = dat, Y = cbind(1, X))     # latent regression
m <- irtc.mml(resp = dat, pweights = w)        # case weights
```

## 2.2 `irtc.mml.2pl()` — models with discrimination (2PL / GPCM)

**Purpose**: estimable slopes — 2PL, GPCM and variants (GPCM.design, 2PL.groups, GPCM.groups). **This is the entry point to the streaming engine.**

**Additional / key arguments**:

| Argument | Meaning | Default |
|---|---|---|
| `irtmodel` | `"2PL"`/`"GPCM"`/`"GPCM.design"`/`"2PL.groups"`/`"GPCM.groups"` | `"2PL"` |
| `method` | engine: `"auto"`/`"grid"`/`"streaming"` | `"auto"` |
| `est.slopegroups` | groups of items sharing a discrimination | `NULL` |
| `E` | design matrix for slopes (GPCM.design) | `NULL` |
| `control` | see 2.4 — streaming / acceleration settings live here | `list()` |

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

## 2.3 S3 methods

| Method | Effect |
|---|---|
| `summary(obj)` | readable summary of item parameters, variance, information criteria |
| `print(obj)` | brief printout |
| `logLik(obj)` | log-likelihood (with df); works with `AIC()`/`BIC()` |
| `anova(obj1, obj2)` | likelihood-ratio test of two nested models |

## 2.4 Full `control` list

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
