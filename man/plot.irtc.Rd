% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{plot.irtc}
\alias{plot.irtc}
\title{Diagnostic Plots for Fitted Item Response Models}
\description{
Base-graphics plots for a fitted model: \code{"wright"} (item difficulty
vs person ability map), \code{"ability"} (person ability histogram, one
panel per dimension), \code{"quality"} (item quality rating summary) and
\code{"icc"} (item characteristic curves; unidimensional models only).
The same figures are embedded in \code{\link{irtc_report}} reports.
}
\usage{
\method{plot}{irtc}(x, type = c("wright", "ability", "quality", "icc"),
    lang = irtc_lang(), items = NULL, resp = NULL, \dots)
}
\arguments{
\item{x}{A fitted \code{irtc} model object.}
\item{type}{Plot type; see Description.}
\item{lang}{Label language, \code{"zh"} or \code{"en"}. Chinese labels
    require a CJK-capable graphics font.}
\item{items}{For \code{type = "icc"}: item indices or names to plot
    (default: the first 12 items).}
\item{resp}{The response data; only needed when the model object does not
    store it (streaming engine).}
\item{\dots}{Ignored.}
}
\value{Invisibly, \code{x}.}
\seealso{\code{\link{irtc}}, \code{\link{irtc_report}}}
\examples{
set.seed(1)
theta <- rnorm(150)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(150) < plogis(theta - b))
}))
mod <- irtc(resp, model = "1PL", verbose = FALSE)
plot(mod, type = "wright", lang = "en")
plot(mod, type = "icc", lang = "en", items = 1:2)
}
