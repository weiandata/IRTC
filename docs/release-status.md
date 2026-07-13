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
