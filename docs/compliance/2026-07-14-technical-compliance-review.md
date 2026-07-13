# IRTC 0.1.0 Technical Compliance Review

Review date: 2026-07-14

This record is the repository-level GPL, CRAN, copyright, and source-boundary
review adopted by the project owner for IRTC 0.1.0. It is a technical
compliance decision for this repository and is not an opinion signed by
external counsel.

## Identity and ownership

- Copyright holder: WEIAN DATA TECH (Beijing) Co., Ltd.
- Company contact: contact@weiandata.com
- Author and maintainer: Kunxiang Ma <makunxiang@weiandata.com>
- Package license: GPL (>= 2)
- Per-file source identifier: `SPDX-License-Identifier: GPL-2.0-or-later`

`DESCRIPTION`, source notices, and `inst/COPYRIGHTS` use the same ownership and
contact mapping.

## External runtime dependencies

IRTC calls separately distributed functions from MASS, mvtnorm, and sfsmisc.
Their source code is not bundled in IRTC, and their respective copyright
holders retain rights in those packages. `inst/COPYRIGHTS` records the package,
function, project URL, and license family for each dependency.

## Review basis

The review uses these official sources:

- GNU General Public License v2.0: https://www.gnu.org/licenses/gpl2.html
- GNU licensing FAQ: https://www.gnu.org/licenses/gpl-faq.en.html
- CRAN Repository Policy: https://cran.r-project.org/web/packages/policies.html
- Writing R Extensions: https://cran.r-project.org/doc/manuals/r-release/R-exts.html

The resulting repository keeps the full GPL terms, provides corresponding
IRTC source, identifies ownership consistently, and does not add distribution
restrictions. External dependency code is not represented as company-owned
source.

## Audit scope

The audit covers:

- ordinary and hidden text files;
- filenames and tracked paths;
- generated Rcpp interface files;
- extracted PDF text and rendered PDF layout;
- names, character values, classes, dimensions, and attributes in `.rda` and
  `.rds` files;
- package metadata and external dependency declarations;
- reachable commit messages, paths, and content.

The restricted-content rule is maintained outside the repository so the audit
record does not reproduce the identifiers it excludes.

## Acceptance conditions

- Complete testthat suite: zero failures and zero errors.
- Standard package check: `Status: OK`.
- CRAN-style package check: zero ERROR and zero WARNING.
- Restricted legacy-origin and process identifiers: zero findings.
- Local and remote branch set: `main` only.
- Reachable Git history: one root commit.

## Measured results

- Complete testthat suite: 624 passed expectations, 0 failures, 0 errors, and
  1 expected controlled-accuracy tolerance warning.
- Generated interfaces: 17 R wrappers and 17 registered native symbols, with
  signatures and arities unchanged.
- Standard `R CMD check --no-manual`: `Status: OK`.
- CRAN-style `R CMD check --as-cran --no-manual`: 0 ERROR, 0 WARNING, and 1
  NOTE for a new submission.
- Serialized data audit: 0 findings across 3 `.rda` and 4 `.rds` files.
- Chinese PDF manual: 28 pages; extracted-text scan and rendered-layout review
  passed.
- Repository tree and reachable Git content: 0 findings.

The new-submission NOTE is informational and does not identify a package
defect. These results satisfy the repository owner's technical compliance
acceptance conditions without an external legal opinion.
