% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_audit_scoring}
\alias{irtc_audit_scoring}
\alias{print.irtc_audit}
\title{Audit a Saved Analysis for the Pre-1.1.2 Answer-Key Defect}
\description{
Checks whether a saved analysis was hit by the answer-key defect fixed in
IRTC 1.1.2, without re-running it.

Up to and including 1.1.1, \code{\link{irtc_read}} renumbered an item's
categories to consecutive scores starting at 0 (a file coded 1..5 became
0..4) and \code{\link{irtc_score}} then matched the answer key against the
renumbered values. A key written in the coding of the data file therefore
selected the wrong option. Nothing warned, and the resulting 0/1 matrix
looks entirely plausible, so an affected analysis cannot be spotted by
inspecting its results.

The risk condition is narrow and mechanically checkable: an item was scored
against a key or a rules table \emph{and} its categories were renumbered.
Both facts are recorded in the cleaning log that every fit carries, so an
archived analysis can be triaged from the saved object alone.
}
\usage{
irtc_audit_scoring(x)

\method{print}{irtc_audit}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{x}{A fitted \code{irtc} model, an \code{irtc_data} object, the list
    returned by \code{\link{irtc_results}}, or a cleaning-log data frame
    (the \code{cleaning_log} element, which also travels in the exported
    workbooks and reports). For the print method: an \code{irtc_audit}
    object.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
An object of class \code{irtc_audit}: a list with \code{status},
\code{affected_items}, an \code{items} data frame (\code{item},
\code{categories_renumbered}, \code{original_categories}),
\code{package_version}, \code{n_scored} and \code{n_recoded}.

\code{status} is one of:
\describe{
\item{\code{"not_scored"}}{No key or rules were used: the responses were
    already scored, so the defect cannot apply.}
\item{\code{"not_affected"}}{A key was used, but no scored item had its
    categories renumbered, so the key applied to the intended options.}
\item{\code{"ok_fixed"}}{Produced by IRTC 1.1.2 or later, where the key is
    applied in the coding of the data file itself.}
\item{\code{"affected"}}{Scored against a key after renumbering, by a
    version known to predate the fix. Re-run the analysis.}
\item{\code{"affected_if_before_1.1.2"}}{The same risk condition, but the
    recording version is not stamped on the object (fits made before 1.1.2
    carry no stamp). Establish which version produced it.}
}
}
\seealso{\code{\link{irtc_score}}, \code{\link{irtc_read}}}
\examples{
set.seed(1)
n <- 120
raw <- data.frame(pid = seq_len(n),
    Q1 = sample(1:4, n, TRUE), Q2 = sample(1:4, n, TRUE),
    Q3 = sample(1:3, n, TRUE), Q4 = sample(1:3, n, TRUE))
f <- tempfile(fileext = ".csv")
utils::write.csv(raw, f, row.names = FALSE)

mod <- irtc(f, model = "2PL", key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2),
    id = "pid", verbose = FALSE)
irtc_audit_scoring(mod)

## an archived fit from an older version reports the items to re-run
archived <- mod
archived$usability$package_version <- "1.1.1"
irtc_audit_scoring(archived)$affected_items

unlink(f)
}
