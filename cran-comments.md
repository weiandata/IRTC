# CRAN comments

## Resubmission

This is a resubmission. The previous submission's incoming pre-tests
reported 2 ERRORs, 1 WARNING and 1 NOTE. All are addressed:

* **ERROR (tests, Windows and Debian).** Two assertions in
  `tests/testthat/test-print-session.R` matched the literal string
  `"R version"`. That wording holds for released R but not for r-devel,
  whose `R.version.string` begins `"R Under development (unstable)"`, so
  the tests failed on the r-devel check flavors only. The assertions now
  compare against `R.version.string` itself instead of assuming the
  released wording. The package code was not at fault and is unchanged.

* **WARNING (PDF version of manual) and ERROR (PDF version of manual
  without index).** Three Rd files documented recognised Chinese
  column-name aliases as literal CJK characters, which have no definition
  in the LaTeX encoding used to build the manual. The Rd sources are now
  ASCII: `\usage` writes the affected default arguments as `\uxxxx`
  escapes (identical R strings, so the code/documentation match still
  holds), and prose uses a new `\zh` Rd macro (`man/macros/irtc.Rd`) that
  renders the Chinese characters in the HTML and text help while emitting
  the equivalent ASCII `\uxxxx` escape in the PDF manual. `R CMD Rd2pdf`
  now completes with no LaTeX errors, which also clears the related NOTE
  about `IRTC-manual.tex` being left in the check directory.

* **NOTE (possibly misspelled words in DESCRIPTION).** We believe this is
  a false positive. "MML" (marginal maximum likelihood), "Rasch" (Georg
  Rasch, after whom the model is named) and "unidimensional" are standard
  item response theory terminology; "pre" is the prefix of the hyphenated
  compound "pre-estimation". All are spelled as intended.

## Submission: IRTC 1.1.1 (new submission)

This is a new package (not yet on CRAN). Version 1.1.1 contains the verified
0.1.0 estimation core plus a usability layer (data import including sampling
weights and Q-matrix alignment, answer-key/partial-credit scoring, data
checks, quality ratings, Excel export, Word/HTML reports, machine-readable
results). The estimation core is unchanged from 0.1.0; all 1.0.x/1.1.x
additions live in the usability layer and are backward compatible. 1.1.1
differs from the rejected 1.1.0 only in documentation sources and one test
file (see Resubmission above); no package code changed.

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
declares Encoding: UTF-8. Three Rd files (irtc_read.Rd, irtc_read_q.Rd,
irtc_score.Rd) document recognised Chinese column-name aliases. They
declare \encoding{UTF-8} and keep the Chinese characters only as the
first argument of the \zh macro defined in man/macros/irtc.Rd, which
resolves to the characters for HTML and text help and to an ASCII \uxxxx
escape for the LaTeX/PDF manual. Everything reaching LaTeX is ASCII.

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
