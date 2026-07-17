% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_read_q}
\encoding{UTF-8}
\alias{irtc_read_q}
\alias{irtc_align_q}
\alias{print.irtc_qmatrix}
\title{Read a Q Matrix from a File and Align It with the Response Data}
\description{
\code{irtc_read_q} reads a Q (item-by-dimension) matrix from any file
format supported by \code{\link{irtc_read}} (Excel, delimited text,
SPSS/Stata/SAS) or from a data frame / matrix. The dimension column
headers become the dimension names used in all downstream person-level
output (ability and standard-error headers). An optional partial-credit
column declares which items are scored in multiple levels, and
optionally their maximum scores.

\code{irtc_align_q} compares the Q-matrix items with the response-data
items. By default mismatches raise warnings (\code{W420}, \code{W421})
and the analysis continues with the shared items;
\code{on_mismatch = "error"} turns any mismatch into an error
(\code{E422}).
}
\usage{
irtc_read_q(x, sheet = 1)

irtc_align_q(data, q, on_mismatch = c("warn", "error"))

\method{print}{irtc_qmatrix}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{x}{A file path, data frame, or numeric matrix with item rownames.
    For the print method: an \code{irtc_qmatrix} object.}
\item{sheet}{Excel sheet to read (number or name).}
\item{data}{An \code{irtc_data} object (from \code{\link{irtc_read}}),
    data frame or matrix of item responses.}
\item{q}{An \code{irtc_qmatrix} object, or anything accepted by
    \code{irtc_read_q}.}
\item{on_mismatch}{\code{"warn"} (default): report item mismatches as
    warnings and continue with the shared items. \code{"error"}: stop on
    any mismatch.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\details{
Expected table layout for \code{irtc_read_q}:

\itemize{
\item An item-ID column named \code{item}, \code{item_id},
    \zh{题目}{\\u9898\\u76ee}, \zh{题号}{\\u9898\\u53f7}
    (etc.); if no such name is found, the first non-numeric column is
    used.
\item One or more numeric dimension columns; each header is a dimension
    name (e.g. \zh{代数}{\\u4ee3\\u6570}, \code{algebra}). Values are
    usually 0/1 loadings. Empty cells count as 0. Every item must load
    on at least one dimension.
\item Optionally one partial-credit column named \code{partial},
    \code{max_score}, \zh{分部计分}{\\u5206\\u90e8\\u8ba1\\u5206},
    \zh{满分}{\\u6ee1\\u5206} (etc.). Values may be 0/1,
    \code{TRUE}/\code{FALSE}, yes/no, \zh{是}{\\u662f}/\zh{否}{\\u5426},
    or integer maximum scores
    (a value >= 2 declares a partial-credit item and records its
    maximum score).
}
}
\value{
\code{irtc_read_q} returns an object of class \code{irtc_qmatrix}: a
list with components \code{Q} (numeric item-by-dimension matrix with
dimnames), \code{partial} (named logical vector), \code{max_score}
(named integer vector, \code{NA} when not declared), \code{log} and
\code{source}.

\code{irtc_align_q} returns a list with components \code{data} (the
input data restricted to the shared items), \code{q} (the aligned
\code{irtc_qmatrix}, rows in data column order), \code{common},
\code{q_only} and \code{data_only} (character vectors of item names).
}
\seealso{\code{\link{irtc}}, \code{\link{irtc_read}}}
\examples{
qdf <- data.frame(item = c("I1", "I2", "I3"),
    algebra = c(1, 1, 0), geometry = c(0, 0, 1),
    partial = c(0, 1, 0))
qm <- irtc_read_q(qdf)
print(qm, lang = "en")

resp <- data.frame(I1 = c(0, 1), I2 = c(2, 0), I4 = c(1, 1))
al <- suppressWarnings(irtc_align_q(resp, qm))
al$q_only
al$data_only
}
