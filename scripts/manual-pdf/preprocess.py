#!/usr/bin/env python3
"""Prepare the Chinese IRTC manual Markdown for the designed PDF build.

The Markdown is written for GitHub readers; the PDF gets its cover, preface
and table of contents from the LaTeX side. This script rewrites the source so
that Pandoc produces the book structure the design expects:

* drops the H1 document title and its subtitle (they live on the cover);
* drops the hand-written contents list (LaTeX builds a native one);
* turns "# 第 N 章　标题" into an unprefixed chapter whose LaTeX chapter
  counter is N, so cross references like "见第 4 章" keep pointing at the
  right chapter while the design supplies the numeral;
* marks the front matter and the appendix as unnumbered chapters;
* removes the horizontal rules used as web separators.
"""

import re
import sys

CHAPTER = re.compile(r"^# 第\s*(\d+)\s*章[　\s]+(.+?)\s*$")


def main(src: str, dst: str) -> None:
    with open(src, encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    out = []
    in_fence = False
    skip_toc = False
    dropped_title = False
    inserted_front = False

    for line in lines:
        if line.startswith("```"):
            in_fence = not in_fence
            out.append(line)
            continue

        if in_fence:
            out.append(line.replace("❌", "[X]"))
            continue

        if skip_toc:
            if line.strip() == "---":
                skip_toc = False
            continue

        if not dropped_title and line.startswith("# "):
            dropped_title = True
            continue

        if line.startswith("**一本写给"):
            continue

        if line.startswith("## 目录"):
            skip_toc = True
            continue

        if not inserted_front and line.startswith("> **本手册对应"):
            out.extend(["\\pagenumbering{arabic}", "", "# 关于本手册 {-}", ""])
            inserted_front = True
            out.append(line)
            continue

        match = CHAPTER.match(line)
        if match:
            number, title = match.group(1), match.group(2)
            out.extend(["", "\\setcounter{chapter}{%d}" % (int(number) - 1), "",
                        "# " + title, ""])
            continue

        if line.rstrip() == "# 附录":
            out.extend(["", "# 附录 {-}", ""])
            continue

        if line.strip() == "---":
            continue

        out.append(line.replace("❌", "[X]"))

    text = "\n".join(out)
    text = re.sub(r"\n{4,}", "\n\n\n", text)
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(text)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
