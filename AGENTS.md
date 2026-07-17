# Imported Claude Cowork project instructions

# IRTC agent handoff

Last updated: 2026-07-17. Current work: **V1.1** on branch `v1.1-dev`.

## Project state

- 1.0.0: verified, CRAN-ready (`IRTC_1.0.0.tar.gz`). Plan:
  `docs/internal/v1.0-release-plan-zh.md`; verification: `docs/internal/release-status.md`;
  pipeline: `scripts/verify-release-1.0.R`.
- 1.1.0: **all modules M1-M6 implemented and verified** (merged to `main`;
  `IRTC_1.1.0.tar.gz`). `scripts/verify-release-1.1.R` passes end to end:
  1191 tests green, 96.0% overall coverage (touched key files >= 95%),
  `R CMD check --as-cran` 0 ERROR / 0 WARNING / 1 NOTE, GPCM smoke passed.
  Plan: `docs/internal/v1.1-plan-zh.md`; status: `docs/internal/release-status.md`.

Implemented in 1.1.0 (new files `R/irtc_qmatrix.R`,
`R/irtc_rare_categories.R`; new tests `test-read-weights.R`,
`test-qmatrix.R`, `test-score-partial.R`, `test-rare-categories.R`,
`test-output-semantics.R`, `test-report-diagnostics.R`; DESCRIPTION
1.1.0; NEWS.md, inst/llms.txt, man/*.Rd updated). New exports:
`irtc_read_q`, `irtc_align_q` (+ `print.irtc_qmatrix`). Condition codes
added: E107-E115, W117, W418-W426, I115/I116, I130-I132, I202, E207/E208.

## V1.1 scope (user-confirmed 2026-07-17)

Modules, in implementation order (M2 is the foundation for M3-M6):

1. M1 sampling weights: `irtc_read()` auto-detects weight columns
   (weight/wt/quan-zhong pool, see plan) + explicit `weights=`; flows
   into `pweights` (core already supports it — do NOT touch the core).
2. M2 Q-matrix: new `irtc_read_q()` (all supported file types; item-ID
   column, dimension columns whose headers become output headers,
   optional partial-credit/max-score column) + `irtc_align_q()`.
   Item mismatch default: warn + auto-align (intersect);
   `on_mismatch="error"` strict mode.
3. M3 answer keys from files (`key`/`rules` accept paths); GPCM partial
   credit via `partial_answer` column (full=2, partial=1, other=0;
   >3 categories require explicit `rules`); consistency warnings vs Q.
4. M4 rare categories: `rare_categories="collapse"` (default; explicit
   per-item collapse mapping logged + annotated in outputs) or
   `"prior"` (keep declared structure, N(0,4) prior on inestimable
   thresholds via existing xsi-prior mechanism; mark
   `prior_dominated`). All-NA items stay dropped (W307) but keep a row
   with `status="dropped_no_response"` in items output.
5. M5 output semantics: GPCM difficulty columns labelled
   `b_partial`/`b_full` (or `b_step1..K`); person outputs use Q
   dimension names for EAP/SE headers; results schema bumps to "1.1"
   (additive only).
6. M6 report: two new sections — model diagnostics (convergence, IC
   interpretation, EAP reliability bands, item-fit table) and data
   transparency (cleaning log, alignment results, weights summary,
   collapse records, dropped items, scoring summary). No embedded
   plots, no methodology chapter (explicitly out of scope).

New condition codes reserved: see table at the end of
`docs/internal/v1.1-plan-zh.md` (I115-W425).

## Acceptance gates (same bar as 1.0)

testthat green (expected warnings asserted via `expect_warning`);
coverage overall >=90%, touched key files >=95%;
`R CMD check --as-cran --no-manual` 0 ERROR / 0 WARNING; end-to-end
GPCM smoke (weighted csv + xlsx Q-matrix + partial-credit key, both
collapse and prior paths); new `scripts/verify-release-1.1.R`.

## Hard conventions (violations have bitten before)

- R sources ASCII-only: non-ASCII via `\uXXXX` escapes; re-run the
  escaper after every edit.
- Core estimation layer (`irtc.mml*`, R/irtc_mml_*.R, src/) is frozen:
  V1.1 is usability-layer only.
- Never place `else` at brace level (leading-`else` breaks R sourcing).
- Tests assume English base-R messages: `Sys.setenv(LANGUAGE="en")` at
  top of tests/testthat.R and verify scripts (user machine zh_CN).
- Bilingual output everywhere (`irtc_lang()`); machine-readable schemas
  are language-independent and only change additively.
- New deps Suggests-only, guarded by `irtc_require()`.
- One module = one commit unit (implementation + man + tests + ASCII
  check).

## Working-tree note

The repo may carry uncommitted user edits (manuals, README, scripts)
predating v1.1-dev. Do not include them in V1.1 commits; commit only
files you touched.
