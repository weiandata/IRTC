% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_quality}
\alias{irtc_quality}
\alias{irtc_quality_thresholds}
\alias{print.irtc_quality}
\title{Plain-Language Item Quality Ratings}
\description{
Combines classical difficulty and discrimination
(\code{\link{irtc_ctt}}) with IRT item fit (\code{\link{irtc_itemfit}})
into a four-level quality rating per item - \code{"good"},
\code{"acceptable"}, \code{"review"}, \code{"revise"} - with bilingual
reasons and advice that non-specialists can act on. Negative
discrimination (usually a wrong answer key) always leads to
\code{"revise"}.
}
\usage{
irtc_quality(mod, resp = NULL, thresholds = NULL)

irtc_quality_thresholds()

\method{print}{irtc_quality}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{mod}{A fitted \code{irtc} model object.}
\item{resp}{The response data; only needed when the model object does not
    store it (streaming engine).}
\item{thresholds}{An optional named list overriding entries of
    \code{irtc_quality_thresholds()}: \code{p_hard} (default 0.10),
    \code{p_easy} (0.95), \code{discr_poor} (0.15), \code{discr_weak}
    (0.25), \code{fit_mild} (c(0.70, 1.30)), \code{fit_severe}
    (c(0.50, 1.50)).}
\item{x}{An \code{irtc_quality} object.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
A data frame of class \code{irtc_quality} with columns \code{item},
\code{N}, \code{pvalue}, \code{discr}, \code{outfit}, \code{infit},
\code{rating}, \code{reasons_en}, \code{reasons_zh}, \code{advice_en},
\code{advice_zh}, and attributes \code{alpha} (Cronbach's alpha) and
\code{thresholds}. \code{irtc_quality_thresholds()} returns the default
threshold list.
}
\seealso{\code{\link{irtc}}, \code{\link{irtc_excel}}}
\examples{
set.seed(1)
theta <- rnorm(300)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 6), function(b) {
    as.numeric(runif(300) < plogis(theta - b))
}))
resp$noise <- rbinom(300, 1, 0.5)  # a broken item
mod <- irtc.mml(resp = resp, verbose = FALSE)
qual <- irtc_quality(mod)
qual[, c("item", "pvalue", "discr", "rating")]
print(qual, lang = "en")
}
