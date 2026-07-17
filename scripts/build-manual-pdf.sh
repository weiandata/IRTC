#!/usr/bin/env bash
# Build the Chinese IRTC user manual PDF from its Markdown source.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/docs/manuals/IRTC手册-中文-V1.1.0.md"
OUT="$ROOT/docs/manuals/IRTC使用手册_中文_V1.0.0.pdf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The Markdown has a hand-written linked contents list for web readers.
# Remove that block for PDF builds because Pandoc generates a native TOC.
awk '
  $0 == "## 目录" { skip = 1; next }
  skip && $0 == "---" { skip = 0; next }
  !skip { gsub(/❌/, "[X]"); print }
' "$SRC" > "$TMP/manual.md"

pandoc "$TMP/manual.md" \
  -s \
  -o "$TMP/manual.tex" \
  --toc \
  --toc-depth=2 \
  --number-sections \
  -V documentclass=article \
  -V geometry:a4paper,margin=2.2cm \
  -V fontsize=10pt \
  -V mainfont="Arial Unicode MS" \
  -V monofont="Menlo" \
  -V CJKmainfont="Arial Unicode MS" \
  -V CJKsansfont="Arial Unicode MS" \
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue

# Two XeLaTeX passes resolve the generated table-of-contents references.
xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory="$TMP" "$TMP/manual.tex" > "$TMP/xelatex-pass1.log"
xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory="$TMP" "$TMP/manual.tex" > "$TMP/xelatex-pass2.log"
cp "$TMP/manual.pdf" "$OUT"

echo "Generated $OUT"
