% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_check_data}
\alias{irtc_check_data}
\alias{print.irtc_check}
\title{Pre-Estimation Data Diagnostics}
\description{
Checks a response data set before model estimation and returns both a
human-readable report and a machine-readable issue table, so that survey
staff and automated callers (e.g. AI agents) can verify data quality and
act on concrete fixes.

Checked, among others: number of items and persons, non-numeric (raw)
response columns, negative or non-integer values, items without responses
or without variance, extreme missingness, sparse categories, persons
without any responses and duplicated person IDs.
}
\usage{
irtc_check_data(x, key = NULL, verbose = TRUE)

\method{print}{irtc_check}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{x}{An \code{irtc_data} object, a data frame or a matrix. For the
    print method: an \code{irtc_check} object.}
\item{key}{If an answer key will be used for scoring, pass it here so that
    raw text columns are reported as scorable instead of as errors.}
\item{verbose}{Logical: print the result?}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
An object of class \code{irtc_check}: a list with \code{ok} (logical:
no error-level issues), \code{n_persons}, \code{n_items},
\code{n_errors}, \code{n_warnings} and \code{issues}, a data frame with
columns \code{code}, \code{severity} (\code{"error"}, \code{"warning"},
\code{"info"}), \code{scope}, \code{where}, \code{message_en},
\code{message_zh}, \code{fix_en}, \code{fix_zh}.
}
\seealso{\code{\link{irtc_read}}, \code{\link{irtc}}}
\examples{
d <- data.frame(i1 = c(0, 1, 1, 0), i2 = c(1, 1, 1, 1),
    i3 = c(0, NA, 1, -9))
chk <- irtc_check_data(d, verbose = FALSE)
chk$ok
chk$issues[, c("code", "severity", "where")]
print(chk, lang = "en")
}
