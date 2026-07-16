# IRTC Release Status

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
