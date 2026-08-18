#!/usr/bin/env bash
# Build the Chinese IRTC workload statement PDF (5 pages).
#
# Shares the manual's visual design (scripts/manual-pdf/style.tex); the
# document itself is hand-set LaTeX in scripts/manual-pdf/workload.tex.
# Requires XeLaTeX and the macOS system fonts used by the manual.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/scripts/manual-pdf"
OUT="$ROOT/docs/IRTC工作量说明_中文_V1.1.1.pdf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Two passes: the TikZ page overlays need the reference data of the first run.
for pass in 1 2; do
  (cd "$ASSETS" && xelatex -interaction=nonstopmode -halt-on-error \
     -output-directory="$TMP" workload.tex > "$TMP/xelatex-pass$pass.log") || {
      echo "XeLaTeX pass $pass failed; last errors:" >&2
      grep -A 4 "^! " "$TMP/xelatex-pass$pass.log" | tail -40 >&2
      exit 1
    }
done

cp "$TMP/workload.pdf" "$OUT"
echo "Generated $OUT"
