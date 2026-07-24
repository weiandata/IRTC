# Internal documentation

Development and release process records. **Not user documentation** — nothing
here is needed to install or use IRTC. If you are looking for how to use the
package, see the [user manuals](../manuals/) or the
[project README](../../README.md).

These files are kept in the repository for maintainer reference. They are
excluded from the built R package via `.Rbuildignore`, so they are never
distributed to CRAN users.

## Release and status

- [Release status](release-status.md) — verified state of each release, and
  what the verification did and did not cover.
- [V1.0 release plan (中文)](v1.0-release-plan-zh.md)
- [V1.1 plan (中文)](v1.1-plan-zh.md)

## CRAN

- [CRAN submission guide (中文)](cran-submission-guide-zh.md) — how the
  submission process should be run.
- [CRAN submission record: 1.1.0 rejection and 1.1.1 resubmission (中文)](cran-submission-1.1.1-zh.md)
  — what actually happened: root cause of each pre-test failure and why each
  fix was chosen. **Outcome: 1.1.1 was accepted and published on CRAN
  (2026-07).**

## Governance

- [Repository standard](repository-standard.md) — governance baseline
  inherited from the WeianData repository template.
- [Technical compliance review](compliance/2026-07-14-technical-compliance-review.md)
  — repository-level licensing and ownership audit.
