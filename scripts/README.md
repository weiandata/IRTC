# Scripts

- `build-manual-pdf.sh` rebuilds the Chinese user-manual PDF from
  `docs/manuals/IRTC手册-中文-V0.1.0.md` using Pandoc and XeLaTeX.

Use this directory only for small utility scripts that support repository tasks
such as setup, validation, documentation, release preparation, or maintenance.

Business logic lives in the package source (`R/`, `src/`), not in `scripts/`.
Do not place credentials, client data, or environment-specific secrets in
scripts.

All scripts are run from the repository root, for example
`Rscript scripts/benchmark.R`. Scripts that load the package with
`devtools::load_all(".")` require the `devtools` package and a C++ toolchain.

## Contents

- `benchmark.R` — timing benchmark of the estimation engine on the bundled
  simulated Rasch data.
- `gen_reference.R` — regenerates regression fixtures from IRTC's estimation
  engine and bundled simulated datasets. Run only when intentionally
  re-baselining the numerical regression oracle.
- `sp4_simulate.R` — shared simulation helpers used by the SP4/SP5 scripts.
- `sp4_feasibility.R` — feasibility measurements for the streaming engine
  (memory/time scaling).
- `sp4_correctness.R` — correctness comparison between engines.
- `sp5_scale_smoke.R` — large-scale smoke test of the streaming engine.
- `sp5_threading_notes.md` — notes on threading behavior and thread-safety
  considerations.
