# Documentation

## User manuals

Start here. The manuals are written for people using IRTC, not for people
developing it.

- [IRTC Manual (English)](manuals/IRTC-Manual-English.md)
- [IRTC 使用手册（中文）](manuals/IRTC手册-中文-V1.1.0.md)
  (PDF can be regenerated with `scripts/build-manual-pdf.sh`)

Inside R, every function has standard help: `?irtc`, `?irtc.mml`,
`help(package = "IRTC")`.

For AI agents and automated pipelines, `inst/llms.txt` is a compact API
reference and `irtc_results()` / `irtc_json()` return a stable schema.

## Internal documentation

Development and release process records, kept for maintainer reference — not
needed to use the package: [docs/internal/](internal/README.md).
