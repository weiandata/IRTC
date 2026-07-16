# Changelog

All notable changes to this repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add future changes here before release.

## [1.0.0] - 2026-07-16

### Added

- Usability layer for four audiences (survey staff, statisticians, AI
  agents, decision makers): one-stop `irtc()` estimation entry point with
  pass-through to the unchanged expert API.
- Multi-format data import `irtc_read()` (Excel, CSV/TSV with delimiter and
  UTF-8/GBK detection, SPSS/Stata/SAS, R objects) with automatic cleaning
  and a bilingual cleaning log.
- Answer-key and partial-credit scoring `irtc_score()`.
- Pre-estimation diagnostics `irtc_check_data()` with machine-readable
  issue table.
- Classical statistics `irtc_ctt()`, item fit `irtc_itemfit()` and
  plain-language quality ratings `irtc_quality()`.
- Layered plain-language summary `plain_summary()`.
- Three-workbook Excel export `irtc_excel()`: item quality (colour-coded),
  item parameters (frozen cross-year linking schema v1.0), person ability
  (flat, paste-ready).
- Audience-specific Word/HTML reports `irtc_report()` and diagnostic plots
  `plot.irtc()` (Wright map, ability, quality, ICC).
- Machine-readable results `irtc_results()` / `irtc_json()` (schema v1.0),
  structured error conditions with code/reason/fix, and `inst/llms.txt`
  for AI agents.
- Bilingual (zh/en) user-facing output via `options(irtc.lang=)`.
- New optional dependencies (Suggests): readxl, writexl, haven, openxlsx,
  officer, jsonlite. New base-R Imports: tools, graphics, grDevices.
- Expanded `inst/COPYRIGHTS` to document the copyright boundary for all direct
  runtime, linking, and optional dependencies.
- Standardized the repository owner identity as WEIAN DATA.

## [0.1.0] - 2026-07-10

### Added

- Import the IRTC R package: marginal maximum likelihood (MML) estimation for
  Rasch/1PL, PCM, RSM, 2PL and GPCM models, unidimensional and between-item
  multidimensional, with latent regression, multiple groups and case weights.
- Add parallelised, dimension-factorised streaming estimation engine with
  `grid`, `streaming` and `auto` computation modes.
- Add opt-in controlled-accuracy quadrature mode with measured approximation
  error reporting (accuracy report).
- Add testthat test suite with regression fixtures.
- Add Chinese and English user manuals under `docs/manuals/`.
- Add CRAN submission guide under `docs/`.
- Add development utility scripts (benchmark, simulation, reference
  generation, correctness and smoke checks) under `scripts/`.
- Add R CMD check workflow.
- Establish GPL (>= 2) licensing and company ownership metadata.
