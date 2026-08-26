% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_ctt}
\alias{irtc_ctt}
\alias{print.irtc_ctt}
\title{Classical Test Theory Item Statistics}
\description{
Computes classical item statistics: item means and difficulty (share of
the maximum score), corrected item-total (item-rest) correlations,
Cronbach's alpha and alpha-if-item-deleted.
}
\usage{
irtc_ctt(x, key = NULL, weights = NULL)

\method{print}{irtc_ctt}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{x}{An \code{irtc_data} object, a data frame, a matrix, or a fitted
    \code{irtc} model (its stored response data are used). For the print
    method: an \code{irtc_ctt} object.}
\item{key}{An optional answer key; raw responses are scored first via
    \code{\link{irtc_score}}.}
\item{weights}{Optional case (sampling) weights, one per person. All
    statistics -- item means, difficulties, item-rest correlations and
    Cronbach's alpha -- are then computed on the weighted sample, which is
    what a complex-sample survey needs so that the classical statistics
    describe the same population as the weighted IRT estimates. Constant
    weights reproduce the unweighted results exactly.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
An object of class \code{irtc_ctt}: a list with \code{items} (data frame
with columns \code{item}, \code{N}, \code{miss_rate}, \code{max_score},
\code{N_weighted}, \code{M}, \code{pvalue}, \code{discr},
\code{alpha_if_deleted}), \code{alpha}, \code{n_persons},
\code{n_items} and \code{weighted} (whether case weights were applied).
}
\seealso{\code{\link{irtc_quality}}, \code{\link{irtc_itemfit}}}
\examples{
set.seed(1)
theta <- rnorm(200)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 6), function(b) {
    as.numeric(runif(200) < plogis(theta - b))
}))
ctt <- irtc_ctt(resp)
ctt$alpha
ctt$items

## with sampling weights
w <- runif(200, 0.5, 3)
irtc_ctt(resp, weights = w)$items$pvalue
}
