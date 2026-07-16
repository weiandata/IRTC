% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{plain_summary}
\alias{plain_summary}
\title{Plain-Language Layered Summary of a Fitted Model}
\description{
Prints a layered, plain-language summary of a fitted item response model:
conclusion first, then analysis overview, item quality, ability
distribution and suggested next steps. Intended for survey staff and
decision makers; statisticians can use \code{summary(mod)} for the full
technical output.
}
\usage{
plain_summary(mod, lang = irtc_lang())
}
\arguments{
\item{mod}{A fitted \code{irtc} model object (from \code{\link{irtc}},
    \code{\link{irtc.mml}} or \code{\link{irtc.mml.2pl}}).}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
}
\value{
Invisibly, the list of summary sections (each with \code{title} and
\code{body}); the same content that \code{\link{irtc_report}} uses.
}
\seealso{\code{\link{irtc}}, \code{\link{irtc_report}}}
\examples{
set.seed(1)
theta <- rnorm(150)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(150) < plogis(theta - b))
}))
mod <- irtc(resp, model = "1PL", verbose = FALSE)
plain_summary(mod, lang = "en")
}
