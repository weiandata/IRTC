#!/usr/bin/env bash
# Build the designed Chinese IRTC user manual PDF from its Markdown source.
#
# Requires XeLaTeX (TeX Live) and Pandoc. The visual design lives in
# scripts/manual-pdf/ : style.tex (typography and colour), front.tex (cover,
# colophon, preface), back.tex (end page) and preprocess.py (Markdown to book
# structure).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/scripts/manual-pdf"
SRC="$ROOT/docs/manuals/IRTC手册-中文-V1.1.2.md"
OUT="$ROOT/docs/manuals/IRTC使用手册_中文_V1.1.2.pdf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 "$ASSETS/preprocess.py" "$SRC" "$TMP/manual.md"

pandoc "$TMP/manual.md" \
  -f markdown+lists_without_preceding_blankline-tex_math_dollars \
  -t latex-smart \
  -s \
  -o "$TMP/manual.tex" \
  --toc \
  --toc-depth=2 \
  --number-sections \
  --syntax-highlighting=tango \
  --lua-filter="$ASSETS/tables.lua" \
  --include-in-header="$ASSETS/style.tex" \
  --include-before-body="$ASSETS/front.tex" \
  --include-after-body="$ASSETS/back.tex" \
  -V documentclass=book \
  -V classoption=oneside \
  -V secnumdepth=0 \
  -V papersize=a4 \
  -V geometry:a4paper \
  -V geometry:top=3cm \
  -V geometry:bottom=2.5cm \
  -V geometry:left=2.4cm \
  -V geometry:right=2.4cm \
  -V geometry:headsep=0.55cm \
  -V geometry:footskip=1.1cm \
  -V fontsize=11pt \
  -V mainfont="Palatino" \
  -V monofont="Menlo" \
  -V monofontoptions="Scale=0.86" \
  -V monofontoptions="HyphenChar=None" \
  -V CJKmainfont="Songti SC" \
  -V CJKoptions="BoldFont=Songti SC Bold,ItalicFont=Kaiti SC" \
  -V title-meta="IRTC 使用手册（中文 · 零基础完整版 · V1.1.2）" \
  -V author-meta="马崑翔 Kunxiang Ma" \
  -V subject="IRTC 1.1.1 项目反应理论分析工具包 · 中文使用手册" \
  -V lang=zh-CN \
  -V colorlinks=true \
  -V linkcolor=IRTCteal \
  -V urlcolor=IRTCteal \
  -V toccolor=IRTCink

# Three XeLaTeX passes: TikZ overlays and the table of contents both need the
# reference data written by the previous run.
for pass in 1 2 3; do
  xelatex -interaction=nonstopmode -halt-on-error \
    -output-directory="$TMP" "$TMP/manual.tex" > "$TMP/xelatex-pass$pass.log" || {
      echo "XeLaTeX pass $pass failed; last errors:" >&2
      grep -A 4 "^! " "$TMP/xelatex-pass$pass.log" | tail -40 >&2
      exit 1
    }
done

cp "$TMP/manual.pdf" "$OUT"
echo "Generated $OUT"
