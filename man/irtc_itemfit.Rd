% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_itemfit}
\alias{irtc_itemfit}
\alias{print.irtc_itemfit}
\title{Item Fit Statistics (Infit and Outfit)}
\description{
Residual-based item fit for a fitted model: infit and outfit mean squares
with Wilson-Hilferty \emph{t} statistics, evaluated at the EAP person
estimates. Values near 1 indicate good fit; the conventional normal range
is 0.7 to 1.3.
}
\usage{
irtc_itemfit(mod, resp = NULL)

\method{print}{irtc_itemfit}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{mod}{A fitted \code{irtc} model object.}
\item{resp}{The response data; only needed when the model object does not
    store it (streaming engine).}
\item{x}{An \code{irtc_itemfit} object.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
A data frame of class \code{irtc_itemfit} with columns \code{item},
\code{N}, \code{outfit}, \code{outfit_t}, \code{infit}, \code{infit_t}.
}
\seealso{\code{\link{irtc_quality}}, \code{\link{irtc_ctt}}}
\examples{
set.seed(1)
theta <- rnorm(200)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(200) < plogis(theta - b))
}))
mod <- irtc.mml(resp = resp, verbose = FALSE)
irtc_itemfit(mod)
}
