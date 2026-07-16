% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{IRTC-package}
\alias{IRTC-package}
\alias{IRTC}
\docType{package}
\title{
Marginal Maximum Likelihood Estimation for Item Response Models
}
\description{
A self-contained marginal maximum likelihood estimation package for
unidimensional and multidimensional item response models. It supports
Rasch / 1PL, partial credit, rating scale, 2PL and generalized partial
credit models, latent regression, multiple groups, case weights, and a
bounded-memory streaming engine for large simple-structure models.
}
\details{
Two entry points are provided.

For statisticians, the expert functions \code{\link{irtc.mml}} and
\code{\link{irtc.mml.2pl}} return an object of class \code{irtc} with
\code{summary}, \code{print}, \code{logLik}, \code{anova} and
\code{\link[=plot.irtc]{plot}} methods.

For non-specialists and automated pipelines, the one-stop function
\code{\link{irtc}} reads data from common file formats
(\code{\link{irtc_read}}), scores raw responses
(\code{\link{irtc_score}}), checks the data
(\code{\link{irtc_check_data}}) and enriches the fitted model with
classical statistics (\code{\link{irtc_ctt}}), item fit
(\code{\link{irtc_itemfit}}) and plain-language quality ratings
(\code{\link{irtc_quality}}). Results can be exported as three Excel
workbooks (\code{\link{irtc_excel}}), audience-specific Word/HTML reports
(\code{\link{irtc_report}}), a layered text summary
(\code{\link{plain_summary}}) or machine-readable structures
(\code{\link{irtc_results}}, \code{\link{irtc_json}}; schema reference in
\code{inst/llms.txt}). User-facing output is bilingual; see
\code{\link{irtc_lang}}.
}
\author{
Kunxiang Ma and WEIAN DATA TECH (Beijing) Co., Ltd.
}
\seealso{
\code{\link{irtc}}, \code{\link{irtc.mml}}, \code{\link{irtc.mml.2pl}}
}
\keyword{package}
