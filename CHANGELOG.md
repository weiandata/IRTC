# Changelog

All notable changes to this repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Expanded `inst/COPYRIGHTS` to document the copyright boundary for all direct
  runtime, linking, and optional dependencies.
- Standardized the repository owner identity as WEIAN DATA.

### Added

- Add future changes here before release.

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
