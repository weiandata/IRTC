# CRAN comments

## Submission: IRTC 1.1.0 (new submission)

This is a new package (not yet on CRAN). Version 1.1.0 contains the verified
0.1.0 estimation core plus a usability layer (data import including sampling
weights and Q-matrix alignment, answer-key/partial-credit scoring, data
checks, quality ratings, Excel export, Word/HTML reports, machine-readable
results). The estimation core is unchanged from 0.1.0; all 1.0.x/1.1.0
additions live in the usability layer and are backward compatible.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Test environments

* Local: macOS Tahoe 26.5.1, R 4.6.0 (aarch64-apple-darwin23)
* GitHub Actions: R release on macOS, Windows, and Linux

## Optional dependencies

readxl, writexl, haven, openxlsx, officer and jsonlite are Suggests and are
used conditionally (guarded by requireNamespace() with an actionable error
message); all examples and tests that need them are skipped when they are
not installed. mvtnorm and sfsmisc are likewise used conditionally.

## Non-ASCII content

R sources are ASCII (Chinese UI strings are \uxxxx escaped). DESCRIPTION
declares Encoding: UTF-8; a few Rd files (irtc_read.Rd, irtc_read_q.Rd,
irtc_score.Rd) declare \encoding{UTF-8} because documented default
arguments and recognised column-name aliases contain Chinese labels.

## Ownership and licensing

Copyright in IRTC is held by WEIAN DATA TECH (Beijing) Co., Ltd. The package is
distributed under GPL (>= 2), with ownership and external runtime dependency
boundaries recorded in DESCRIPTION and inst/COPYRIGHTS. MASS is imported;
all other third-party packages are used conditionally from Suggests. Their
source code is not bundled in IRTC.

Maintainer: Kunxiang Ma <makunxiang@weiandata.com>
Company contact: <contact@weiandata.com>

## Downstream dependencies

There are currently no downstream dependencies because this is a new package.
