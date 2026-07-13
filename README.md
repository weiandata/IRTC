# IRTC

High-performance item response theory (IRT) estimation for R, built for
surveys, assessments and scale analysis.

Status: Active

Owner: WEIAN DATA Engineering

## Project Overview

IRTC is an R package for marginal maximum likelihood (MML) estimation of item
response models. It supports dichotomous and ordered polytomous items,
unidimensional and between-item multidimensional models, latent regression,
multiple groups, case weights and person ability estimation (EAP).

On top of standard MML estimation, IRTC adds parallel computation, automatic
engine selection, low-memory streaming estimation and an opt-in
controlled-accuracy quadrature mode that reports a measured approximation
error. It suits both routine questionnaire analysis and large-scale data with
many persons, items and dimensions.

## Features

- Rasch / 1PL, PCM, RSM, 2PL and GPCM models.
- Unidimensional and between-item multidimensional models.
- Latent regression, multiple groups and case weights.
- Item parameters, EAP ability estimates and standard errors.
- AIC, BIC, log-likelihood and nested model comparison (`anova`).
- Three computation engines: `grid`, `streaming` and `auto`; streaming avoids
  the full person-by-node posterior matrix and bounds memory use.
- Optional controlled-accuracy acceleration with a measured error report;
  exact computation remains the default.
- Chinese and English user manuals for non-specialist users.

## Repository Structure

```text
.
├── .github/            # Issue/PR templates and CI workflows
├── R/                  # Package R source
├── src/                # Rcpp/C++ estimation core
├── man/                # Package documentation (Rd)
├── data/               # Bundled example datasets
├── tests/              # testthat suite and regression fixtures
├── docs/               # User manuals and CRAN submission guide
├── examples/           # Minimal usage examples
├── scripts/            # Development utility scripts
├── DESCRIPTION         # Package metadata
└── NAMESPACE           # Package namespace
```

## Getting Started

Requirements: R (>= 3.5.0) with a C++ toolchain (Rtools on Windows), and the
Rcpp and RcppArmadillo packages.

Install from this repository:

```r
# install.packages("remotes")
remotes::install_github("weiandata/IRTC")
```

Or from a local clone:

```sh
R CMD build .
R CMD INSTALL IRTC_0.1.0.tar.gz
```

Quick start:

```r
library(IRTC)
data(data.sim.rasch)
mod <- irtc.mml(resp = data.sim.rasch)
summary(mod)
```

See [examples/basic-usage.R](examples/basic-usage.R) for more.

## Development

Changes use short-lived branches named `<category>/<kebab-case-topic>` and go
through pull requests; keep `main` releasable. See
[CONTRIBUTING.md](CONTRIBUTING.md) for commit, review, testing and evidence
requirements.

Run the test suite from the repository root:

```r
devtools::test()
```

CI runs Markdown/link checks and `R CMD check` on every push and pull request.

## Documentation

- [Documentation index](docs/README.md)
- [English manual](docs/manuals/IRTC-Manual-English.md)
- [中文使用手册 (V0.1.0)](docs/manuals/IRTC手册-中文-V0.1.0.md)
- [CRAN submission guide (中文)](docs/cran-submission-guide-zh.md)
- [WeianData Engineering Handbook](https://github.com/weiandata/.github/blob/main/handbook/README.md)

## Data and Security

Bundled datasets are simulated by IRTC (reproducible via
[`scripts/gen_data.R`](scripts/gen_data.R)). Do not commit credentials,
secrets, personal information, restricted
client data, or unapproved datasets. Follow [SECURITY.md](SECURITY.md) for
private vulnerability reporting.

## Support

Use the repository's issue templates for non-sensitive defects, features, and
documentation work. Report security concerns only through the private channels
listed in [SECURITY.md](SECURITY.md).

## License

IRTC is distributed under GPL (>= 2). See [LICENSE](LICENSE) and
[`inst/COPYRIGHTS`](inst/COPYRIGHTS). Copyright in IRTC is held by WEIAN DATA
TECH (Beijing) Co., Ltd. Company contact: <contact@weiandata.com>.
