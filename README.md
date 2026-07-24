# IRTC

**English** | [简体中文](README.zh-CN.md)

[![CRAN status](https://www.r-pkg.org/badges/version/IRTC)](https://CRAN.R-project.org/package=IRTC)
[![R CMD check](https://github.com/weiandata/IRTC/actions/workflows/r-check.yml/badge.svg)](https://github.com/weiandata/IRTC/actions/workflows/r-check.yml)
[![License: GPL v2+](https://img.shields.io/badge/License-GPL%20%3E%3D%202-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)

Item response theory (IRT) analysis in R that goes from a spreadsheet to a
readable report — without requiring you to be a statistical programmer.

Most IRT packages start after your data is already a clean numeric matrix and
stop at a model object you have to dig results out of. IRTC does those two ends
for you as well, while leaving the full expert API available underneath.

> **Status:** on CRAN — install with `install.packages("IRTC")`. The API is
> stable; 1.1.x is backward compatible with 1.0.

## What it looks like

One line from data to fitted model, and a summary in plain language rather than
a wall of coefficients. This runs as-is on the bundled example data:

```r
library(IRTC)
data(data.sim.rasch)
mod <- irtc(data.sim.rasch, model = "1PL")   # a file path works the same way
plain_summary(mod)
```

```text
------------------------------------------------------------
Conclusion
------------------------------------------------------------
The test measured 2000 persons with 40 items. Score reliability is 0.87 (good).
40 of 40 items are of good or acceptable quality.

------------------------------------------------------------
Item quality
------------------------------------------------------------
Item quality: 40 good, 0 acceptable, 0 to review, 0 to revise.
Internal consistency (Cronbach's alpha): 0.8658.

------------------------------------------------------------
Ability distribution
------------------------------------------------------------
mean ability 0, spread (SD) 0.93, range -2.92 to 3.14.
Ability scores are on the logit scale; 0 is the population-model average,
higher means stronger.

------------------------------------------------------------
Next steps
------------------------------------------------------------
Export the three Excel tables: irtc_excel(mod).
Create a report: irtc_report(mod, "report.docx").
Full technical output: summary(mod).
```

The block above is abridged; an "Analysis overview" section is also printed.

`irtc()` reads Excel/CSV/TSV/SPSS/Stata/SAS or R objects, cleans the data with
a traceable log, scores raw A/B/C/D responses against an answer key, checks the
data, and estimates the model. Every expert argument passes straight through.

## Install

```r
install.packages("IRTC")

# development version:
# install.packages("remotes")
remotes::install_github("weiandata/IRTC")
```

Requires R (>= 3.5.0) and a C++ toolchain (Rtools on Windows). Excel, SPSS and
report output need optional packages (`readxl`, `writexl`, `haven`, `officer`);
IRTC tells you which one to install if you use a feature that needs it.

## Models and features

- **Models:** Rasch / 1PL, PCM, RSM, 2PL, GPCM — dichotomous and ordered
  polytomous items.
- **Designs:** unidimensional and between-item multidimensional, latent
  regression, multiple groups, sampling weights.
- **Output:** item parameters, EAP abilities and standard errors, AIC/BIC,
  nested model comparison (`anova`), item fit and classical statistics.
- **Scale:** three engines (`grid`, `streaming`, `auto`) with automatic
  routing; streaming bounds memory for large person × item × dimension data.
  An opt-in controlled-accuracy mode reports a *measured* approximation error,
  and exact computation stays the default.
- **Bilingual:** `options(irtc.lang = "zh")` (default) or `"en"`.

## Three ways to use it

**Survey and assessment staff** — file in, results out:

```r
mod <- irtc("responses.xlsx", model = "1PL")
plain_summary(mod)                            # plain-language summary
irtc_excel(mod, dir = "results")              # item quality / parameters / abilities
irtc_report(mod, "report.docx", audience = "decision")
```

**Statisticians** — the full expert API, nothing hidden:

```r
data(data.sim.rasch)
mod <- irtc.mml(resp = data.sim.rasch)
summary(mod)
irtc_itemfit(mod)
```

**AI agents and pipelines** — machine-readable in and out:

```r
chk <- irtc_check_data(irtc_read("responses.csv", verbose = FALSE))
if (chk$ok) {
    mod <- irtc("responses.csv", model = "2PL", verbose = FALSE)
    irtc_json(mod, "results.json")   # stable schema; see inst/llms.txt
}
```

Errors are structured conditions carrying a code, a reason and a fix.

See [examples/basic-usage.R](examples/basic-usage.R) for a runnable tour.

## Documentation

- [English manual](docs/manuals/IRTC-Manual-English.md) —
  [中文使用手册](docs/manuals/IRTC手册-中文-V1.1.0.md)
- In R: `?irtc`, `?irtc.mml`, `help(package = "IRTC")`
- [Documentation index](docs/README.md)

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)
for branch, commit, testing and review requirements. Report security concerns
privately through [SECURITY.md](SECURITY.md), not in public issues.

Bundled datasets are simulated by IRTC and reproducible via
[`scripts/gen_data.R`](scripts/gen_data.R); they contain no real respondent
data.

## License

GPL (>= 2). See [LICENSE](LICENSE) and [`inst/COPYRIGHTS`](inst/COPYRIGHTS).

Copyright © 2026 WEIAN DATA TECH (Beijing) Co., Ltd. — <contact@weiandata.com>
