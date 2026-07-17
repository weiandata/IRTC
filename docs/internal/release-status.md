# IRTC Release Status

## 1.1.1 (verified 2026-07-17, submitted to CRAN)

Packaging-only release. It exists because CRAN's incoming pre-tests
rejected 1.1.0 with 2 ERRORs and 1 WARNING. No package code changed: the
failures came from documentation sources and two over-specified test
assertions. Full account, including root causes and the reasoning behind
each fix: `docs/internal/cran-submission-1.1.1-zh.md`.

What changed relative to 1.1.0:

- Rd sources reaching LaTeX are now ASCII, so the PDF reference manual
  builds without errors. Chinese column-name aliases are preserved: the
  new `\zh` macro (`man/macros/irtc.Rd`) renders the characters in HTML
  and text help and an equivalent `\uxxxx` escape in the PDF.
- `test-print-session.R` no longer assumes the released R wording
  `"R version"`, which does not hold on r-devel
  (`"R Under development (unstable)"`) and failed both r-devel flavors.
- DESCRIPTION gains the `Date` field that was missing, so the banner
  reads `IRTC 1.1.1 (2026-07-17)` rather than `IRTC 1.1.1 ()`.

Verification:

- Local (macOS, R 4.6.0 aarch64) `R CMD check --as-cran`: 0 ERROR,
  0 WARNING, 1 NOTE ("New submission" + DESCRIPTION spelling false
  positive). Generated PDF contains 0 CJK characters; HTML help retains
  the Chinese aliases.
- win-builder R-devel (`R Under development (unstable) (2026-07-16
  r90264 ucrt)`): Status 1 NOTE; `checking tests` OK [326s];
  `checking PDF version of manual` OK [20s]. This flavor is the only one
  that can confirm the test fix, since the failure does not reproduce on
  released R.
- Submission tarball: IRTC_1.1.1.tar.gz, built from a clean
  `git archive HEAD` export.

## 1.1.0 (verified 2026-07-17, rejected by CRAN incoming pre-tests)

Superseded by 1.1.1. The verification below was reported honestly but
could not have caught either ERROR, for two structural reasons worth
recording:

- `scripts/verify-release-1.1.R` runs `rcmdcheck` with `--as-cran` **and
  `--no-manual`** (line 85), which skips building the PDF manual. The
  LaTeX failure on the CJK characters in the Rd sources was therefore
  invisible locally. The "0 WARNING" below is real for `--no-manual` and
  says nothing about the manual.
- The suite ran on released R only (local macOS R 4.6.0, and CI on R
  release). The test failure reproduces exclusively on r-devel, whose
  `R.version.string` wording differs.

Consequence: local green did not imply CRAN green. See the 1.1.1 entry
above and `docs/internal/cran-submission-1.1.1-zh.md`.

1.1.0 is a usability release for the GPCM / multidimensional workflow on
top of the verified 1.0.0 core. New behaviour (all in the usability
layer, estimation core untouched, no new dependencies): sampling-weight
import in `irtc_read()`; Q-matrix import and alignment (`irtc_read_q()`,
`irtc_align_q()`, `irtc(q=)`); answer-key/rules from files with
partial-credit key scoring; `rare_categories` handling of unobserved
score categories (collapse default, prior optional); semantic GPCM
difficulty labels and Q-dimension person headers (`irtc_results` schema
1.1, additive); and Model-diagnostics + Data-transparency report
sections.

Plan: `docs/internal/v1.1-plan-zh.md`. Acceptance follows the 1.0 policy and is
wired into `scripts/verify-release-1.1.R`. Verification results
(`scripts/verify-release-1.1.R` on macOS, R 4.6.0 aarch64):

- testthat suite: 1191 passes, 0 failures, 0 errors (expected warnings
  asserted via `expect_warning()`).
- Test coverage (covr): overall 96.0% (target >= 90%); every touched key
  file >= 95% incl. `irtc_qmatrix.R` (99.7%), `irtc_rare_categories.R`
  (100%), `irtc_report.R` (99.6%), `irtc_score.R` (99.6%).
- `R CMD check --as-cran`: 0 ERROR, 0 WARNING, 1 NOTE ("New submission").
- End-to-end GPCM smoke (weights + Q matrix + partial-credit key under
  both rare-category modes, plus an extreme-data case): passed.
- Submission tarball: IRTC_1.1.0.tar.gz.

## 1.0.0 (verified 2026-07-17, ready for CRAN submission)

Verification results (scripts/verify-release-1.0.R on macOS Tahoe 26.5.2,
R 4.6.0 aarch64):

- testthat suite: 975 expectations, 0 failures, 0 errors; the single
  controlled-accuracy tolerance warning is now asserted via
  expect_warning() instead of leaking into the summary.
- Test coverage (covr): overall 95.2% (target >= 90%); all 11 key entry
  files between 95.2% and 100% (target >= 95%).
- `R CMD check --as-cran --no-manual`: 0 ERROR, 0 WARNING, 1 NOTE
  ("New submission" - expected for any first CRAN submission).
- End-to-end smoke test (csv -> irtc() -> plain_summary zh/en ->
  irtc_excel -> irtc_report html x3 + docx -> irtc_json): passed.
- Submission tarball: IRTC_1.0.0.tar.gz.

## 1.0.0 (in verification)

1.0.0 adds the usability layer on top of the verified 0.1.0 core: one-stop
`irtc()` estimation from common file formats, answer-key scoring, data
checks, CTT/item-fit/quality statistics, three-workbook Excel export with a
frozen cross-year linking schema, audience-specific Word/HTML reports,
diagnostic plots, machine-readable results (`irtc_results`/`irtc_json`),
structured error conditions and bilingual output. New dependencies are
Suggests-only.

Release acceptance for 1.0.0 follows the same policy as 0.1.0 (full test
suite green, `R CMD check --as-cran --no-manual` with 0 ERROR / 0 WARNING).
Run `Rscript scripts/verify-release-1.0.R` from the repository root on the
maintainer machine to execute the complete verification pipeline
(tests, build, as-cran check, end-to-end smoke test).

# IRTC 0.1.0 Release Status

IRTC 0.1.0 provides marginal maximum likelihood estimation for Rasch/1PL,
PCM, RSM, 2PL, and GPCM models. It supports unidimensional and between-item
multidimensional structures, latent regression, multiple groups, case weights,
EAP ability estimates, model comparison, and item-parameter reporting.

For large simple-structure models, IRTC provides a bounded-memory streaming
engine with automatic routing. Its optional controlled-accuracy mode reports
measured approximation error; exact full-grid estimation remains the default.

## Ownership and contacts

Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.

- Company contact: <contact@weiandata.com>
- Maintainer: Kunxiang Ma <makunxiang@weiandata.com>

IRTC is distributed under GPL (>= 2). MASS, mvtnorm, and sfsmisc are external
runtime dependencies; their source code is not bundled in IRTC.

## Verification policy

Release acceptance requires the complete testthat suite to have zero failures
and errors, standard `R CMD check --no-manual` to report `Status: OK`, and
`R CMD check --as-cran --no-manual` to report zero ERROR and zero WARNING.
Repository text, generated documentation, serialized R data, and reachable Git
content must pass the restricted-content audit described in the technical
compliance review.

## Release verification

- Complete testthat suite: 624 passed expectations, 0 failures, 0 errors, and
  1 expected controlled-accuracy tolerance warning.
- Generated interfaces: 17 R wrappers and 17 registered native symbols, with
  signatures and arities unchanged.
- Standard `R CMD check --no-manual`: `Status: OK`.
- CRAN-style `R CMD check --as-cran --no-manual`: 0 ERROR, 0 WARNING, and 1
  NOTE for a new submission.
- Serialized data: 0 restricted-content findings across 3 `.rda` and 4 `.rds`
  files.
- Chinese PDF manual: 28 pages; extracted-text and rendered-layout review
  passed.
- Repository tree and reachable Git content: 0 restricted-content findings.
