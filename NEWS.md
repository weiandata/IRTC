# IRTC 1.0.0

First CRAN release. The estimation core is unchanged from 0.1.0; this
release adds a usability layer for four audiences: survey staff without
statistical training, professional statisticians, AI agents / automated
pipelines, and decision makers receiving the results.

## New features

* `irtc()`: one-stop estimation. Accepts a file path (`.xlsx`, `.xls`,
  `.csv`, `.tsv`, `.txt`, `.dat`, `.sav`, `.por`, `.dta`, `.sas7bdat`,
  `.xpt`) or a data frame/matrix; cleans, optionally scores raw responses
  against an answer key, checks the data, estimates the requested model
  (`model` is required: `"1PL"`/`"Rasch"`, `"2PL"`, `"PCM"`, `"PCM2"`,
  `"RSM"`, `"GPCM"`) and attaches classical statistics, item fit and
  quality ratings. All extra arguments pass through to `irtc.mml()` /
  `irtc.mml.2pl()`, which are unchanged.
* `irtc_read()`: unified import with automatic delimiter and UTF-8/GBK
  encoding detection, person-ID detection (English and Chinese column
  names), missing-code recoding with a range guard, category recoding to
  consecutive 0-based scores, and a bilingual cleaning log.
* `irtc_score()`: answer-key (0/1) and partial-credit rules scoring with
  normalisation of case, whitespace and full-width characters.
* `irtc_check_data()`: pre-estimation diagnostics; returns a
  machine-readable issue table (code / severity / where / bilingual
  message / fix).
* `irtc_ctt()`: item difficulty, corrected item-total correlations,
  Cronbach's alpha and alpha-if-item-deleted.
* `irtc_itemfit()`: infit/outfit mean squares with Wilson-Hilferty t
  statistics, for both the grid and the streaming engine.
* `irtc_quality()`: four-level plain-language item quality ratings
  (good / acceptable / review / revise) with bilingual reasons and advice;
  thresholds are configurable via `irtc_quality_thresholds()`.
* `plain_summary()`: layered plain-language summary (conclusion first).
* `irtc_excel()`: writes three separate Excel workbooks - a plain-language
  item quality table (colour-coded), an item difficulty/discrimination
  table with a frozen schema for cross-year anchor linking, and a flat,
  paste-ready person ability table. Requires the optional 'openxlsx'.
* `irtc_report()`: audience-specific reports (`decision`, `survey`,
  `stat`) as self-contained HTML or Word (optional 'officer'), with
  Wright map, ability distribution, quality summary and ICC figures.
* `plot.irtc()`: `wright`, `ability`, `quality` and `icc` plot types.
* `irtc_results()` / `irtc_json()`: machine-readable results with a
  stable documented schema (see `inst/llms.txt`); JSON export via the
  optional 'jsonlite'.
* Structured conditions: all errors/warnings of the usability layer carry
  classes (`irtc_error`, domain classes) and fields `code`, `reason`,
  `fix`, `data`, enabling programmatic recovery.
* Bilingual output (Chinese default, English via
  `options(irtc.lang = "en")`); machine-readable schemas are
  language-independent.
* `inst/llms.txt`: compact API and schema reference for AI agents.

## Notes

* All new dependencies are optional (Suggests) and requested with an
  actionable installation hint when needed; the estimation core adds no
  hard dependencies beyond 0.1.0 (only 'tools', 'graphics', 'grDevices'
  from base R).

# IRTC 0.1.0

* Initial version: MML estimation for Rasch/1PL, PCM, PCM2, RSM, 2PL and
  GPCM models, unidimensional and between-item multidimensional, with
  latent regression, multiple groups, case weights, EAP person estimates,
  parallel grid engine, bounded-memory streaming engine and an opt-in
  controlled-accuracy quadrature mode with a measured error report.
