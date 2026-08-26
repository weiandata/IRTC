# CRAN comments

## Submission: IRTC 1.1.2 (update)

This is an update to IRTC 1.1.1, which is on CRAN. It is a correctness
release: it fixes defects found when the package was used on a national
survey (85,035 respondents, 10 dichotomous items, three content dimensions,
sampling weights), and further defects found by validating the whole
pipeline against that survey's raw SPSS source file. Full user-facing
account in NEWS.md.

### Backward compatibility

No user code needs to change. Function signatures gain arguments only, all
with defaults that reproduce the previous behaviour where the previous
behaviour was correct; the machine-readable schemas advance additively
(`irtc_results()` 1.1 -> 1.2, the Excel linking workbook 1.0 -> 1.1) with no
existing column renamed or redefined. One new function is exported
(`irtc_audit_scoring()`).

### Reported numbers do change, deliberately

We state this explicitly rather than leave it to be discovered:

* The marginal log-likelihood, deviance and all information criteria
  reported by the streaming estimation engine were offset by a constant
  `n * ndim * log(1 / h)` (the quadrature weights were a normal density
  rather than probability mass, so they summed to about `h^-ndim` instead
  of one). They are now correct and comparable across engines,
  dimensionalities and node settings. Item parameters, latent covariances
  and EAP estimates are unchanged, because posterior quantities are
  invariant to that rescaling.
* Where case weights are supplied, the classical item statistics, item fit,
  quality ratings and the norm-referenced person columns are now computed on
  the weighted sample, as the IRT parameters already were. Constant weights
  reproduce the previous unweighted values exactly.
* An answer key is now applied in the category coding of the user's own data
  file. Previously it was matched against the internally renumbered
  categories, so a key could select the wrong option without warning.
  `irtc_audit_scoring()` lets users check an archived analysis without
  re-running it.

### Memory-safety fix

The C++ E-step of the streaming engine indexed a probability array with the
raw response code, so `NA_INTEGER` produced an out-of-bounds read and a
segmentation fault. Missing responses are now handled natively in that
kernel, and the index is bounds-checked.

## R CMD check results

0 errors | 0 warnings | 0 notes

Checked with the PDF manual built (not `--no-manual`):
`checking PDF version of manual ... OK`. The generated manual contains no
CJK characters; the Rd sources reaching LaTeX remain ASCII, as arranged for
1.1.1 via the `\zh` macro in `man/macros/irtc.Rd`.

The only note produced locally is a limitation of this machine's toolchain,
not of the package: HTML Tidy is too old for HTML validation and package
'V8' is unavailable for math rendering, so both sub-checks are skipped.

## Test environments

* Local: macOS Tahoe 26.5.1, R 4.6.0 (aarch64-apple-darwin23)
* GitHub Actions: R release on macOS, Windows, and Linux

Test suite: 1298 assertions in 340 test blocks across 62 files, 0 failures,
0 skips. New regression tests cover each defect above, including agreement
between the two estimation engines, invariance of the reported
log-likelihood to the node count, the degenerate-covariance case, and the
weighted statistics reducing exactly to the unweighted ones under constant
weights.

## Downstream dependencies

There are no reverse dependencies on CRAN
(`tools::package_dependencies("IRTC", reverse = TRUE)` returns none), so
this update cannot break any dependent package.

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

---

## Previous submission: IRTC 1.1.1 (accepted, 2026-07)

Kept for reference. 1.1.1 was the first CRAN release, itself a resubmission
after the incoming pre-tests rejected 1.1.0 with 2 ERRORs, 1 WARNING and
1 NOTE:

* **ERROR (tests, Windows and Debian).** Two assertions in
  `tests/testthat/test-print-session.R` matched the literal string
  `"R version"`, which holds for released R but not for r-devel
  (`"R Under development (unstable)"`). They now compare against
  `R.version.string` itself. The package code was not at fault.

* **WARNING / ERROR (PDF version of manual).** Three Rd files documented
  recognised Chinese column-name aliases as literal CJK characters, which
  have no definition in the LaTeX encoding used to build the manual. The Rd
  sources were made ASCII: `\usage` writes the affected default arguments as
  `\uxxxx` escapes, and prose uses the `\zh` macro described above.

* **NOTE (possibly misspelled words in DESCRIPTION).** A false positive.
  "MML" (marginal maximum likelihood), "Rasch" (Georg Rasch, after whom the
  model is named) and "unidimensional" are standard item response theory
  terminology; "pre" is the prefix of the hyphenated compound
  "pre-estimation". All are spelled as intended.
