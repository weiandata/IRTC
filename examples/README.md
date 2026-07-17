# Examples

Small, safe, reproducible examples that help a reader understand or verify the
project. All examples use the synthetic datasets bundled with the package and
contain no client data or secrets.

## Contents

- [`basic-usage.R`](basic-usage.R) — fit a Rasch model, a partial credit
  model and a 2PL model on bundled data, inspect item parameters, extract EAP
  ability estimates and compare nested models; then (usability layer)
  the one-stop `irtc()` workflow, plain-language summaries, data checks,
  answer-key scoring, item quality ratings, Excel/report exports,
  machine-readable results and diagnostic plots.

Run from the repository root after installing the package:

```sh
Rscript examples/basic-usage.R
```
