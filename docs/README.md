# Documentation

## User manuals

Start here. The manuals are written for people using IRTC, not for people
developing it.

- [IRTC Manual (English)](manuals/IRTC-Manual-English.md)
- [IRTC 使用手册（中文）](manuals/IRTC手册-中文-V1.1.2.md) —
  [designed PDF edition](manuals/IRTC使用手册_中文_V1.1.2.pdf)
  (rebuild with `scripts/build-manual-pdf.sh`)

Inside R, every function has standard help: `?irtc`, `?irtc.mml`,
`help(package = "IRTC")`.

Earlier editions are kept for reference: the
[1.1.1](manuals/IRTC手册-中文-V1.1.1.md),
[1.1.0](manuals/IRTC手册-中文-V1.1.0.md) and
[0.1.0](manuals/IRTC手册-中文-V0.1.0.md) Chinese manuals.

For AI agents and automated pipelines, `inst/llms.txt` is a compact API
reference and `irtc_results()` / `irtc_json()` return a stable schema.

## Project overview

- [IRTC 工作量说明（中文 · PDF）](IRTC工作量说明_中文_V1.1.2.pdf) — a five-page
  statement of code volume, documentation volume, technical approach and
  delivered results (rebuild with `scripts/build-workload-pdf.sh`).

## Internal documentation

Development and release process records, kept for maintainer reference — not
needed to use the package: [docs/internal/](internal/README.md).
