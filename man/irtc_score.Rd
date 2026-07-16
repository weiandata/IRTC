% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_score}
\alias{irtc_score}
\title{Score Raw Responses with an Answer Key or Scoring Rules}
\description{
Converts raw multiple-choice responses (e.g. \code{"A"}, \code{"B"},
\code{"C"}, \code{"D"}) to 0/1 scores using an answer key, or maps
responses to partial-credit scores through a rules table. Responses are
normalised before matching: whitespace is trimmed, case is ignored and
full-width characters are converted to half-width.
}
\usage{
irtc_score(resp, key = NULL, rules = NULL, na_as_wrong = FALSE)
}
\arguments{
\item{resp}{An \code{irtc_data} object (from \code{\link{irtc_read}}), a
    data frame or a matrix of raw responses.}
\item{key}{A named vector mapping item names to correct answers, e.g.
    \code{c(Q1 = "A", Q2 = "C")}. An unnamed vector is matched to the item
    columns by position. Items not named in the key are left unchanged.}
\item{rules}{A data frame with columns \code{item}, \code{response},
    \code{score} defining partial-credit scoring. Observed responses
    without a rule are set to \code{NA} with a warning of class
    \code{irtc_warning_scoring}.}
\item{na_as_wrong}{Logical: score missing responses as 0 instead of
    \code{NA}? (Key scoring only.)}
}
\value{
The same type as the input: an \code{irtc_data} object with scored
\code{resp} and an extended log, or a data frame with a
\code{"scoring_log"} attribute.
}
\seealso{\code{\link{irtc_read}}, \code{\link{irtc}}}
\examples{
resp <- data.frame(Q1 = c("A", "b", "C"), Q2 = c("c", "C", "D"),
    stringsAsFactors = FALSE)
irtc_score(resp, key = c(Q1 = "A", Q2 = "C"))

rules <- data.frame(item = "Q1", response = c("A", "B", "C"),
    score = c(2, 1, 0))
irtc_score(resp["Q1"], rules = rules)
}
