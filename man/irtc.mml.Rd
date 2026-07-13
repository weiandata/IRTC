% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc.mml}
\alias{irtc.mml}
\alias{summary.irtc}
\alias{print.irtc}
\alias{logLik.irtc}
\alias{anova.irtc}
\title{
Marginal Maximum Likelihood Estimation of Fixed-Slope Item Response Models
}
\description{
Estimates unidimensional and multidimensional fixed-slope item response
models by marginal maximum likelihood (MML). Supported models include the
Rasch / 1PL model, the partial credit model (\code{"PCM"}, \code{"PCM2"})
and the rating scale model (\code{"RSM"}). Latent regression on covariates,
multiple groups, case weights and user-specified design matrices are
supported.
}
\usage{
irtc.mml(resp, Y = NULL, group = NULL, irtmodel = "1PL",
   formulaY = NULL, dataY = NULL, ndim = 1, pid = NULL,
   xsi.fixed = NULL, xsi.inits = NULL, beta.fixed = NULL, beta.inits = NULL,
   variance.fixed = NULL, variance.inits = NULL, est.variance = TRUE,
   constraint = "cases", A = NULL, B = NULL, B.fixed = NULL, Q = NULL,
   est.slopegroups = NULL, E = NULL, pweights = NULL,
   userfct.variance = NULL, variance.Npars = NULL, item.elim = TRUE,
   verbose = TRUE, control = list())

\method{summary}{irtc}(object, file = NULL, \dots)

\method{print}{irtc}(x, \dots)

\method{logLik}{irtc}(object, \dots)

\method{anova}{irtc}(object, \dots)
}
\arguments{
\item{resp}{A data frame or matrix of polytomous or dichotomous item responses. Missing responses are coded \code{NA}.}
\item{Y}{An optional matrix of covariates for the latent regression.}
\item{group}{An optional vector of integer group identifiers for multiple-group estimation.}
\item{irtmodel}{The estimated item response model. One of \code{"1PL"}, \code{"PCM"}, \code{"PCM2"} or \code{"RSM"}.}
\item{formulaY}{An optional formula for the latent regression in conjunction with \code{dataY}.}
\item{dataY}{An optional data frame of covariates used together with \code{formulaY}.}
\item{ndim}{The number of latent dimensions (used when no \code{Q} or \code{B} is supplied).}
\item{pid}{An optional vector of person identifiers.}
\item{xsi.fixed}{An optional matrix with two columns for fixing item parameters: parameter index and fixed value.}
\item{xsi.inits}{An optional matrix of initial item parameter values.}
\item{beta.fixed}{An optional matrix for fixing regression coefficients, or \code{FALSE} to estimate all.}
\item{beta.inits}{An optional matrix of initial regression coefficients.}
\item{variance.fixed}{An optional matrix for fixing entries of the covariance matrix.}
\item{variance.inits}{An optional initial covariance matrix.}
\item{est.variance}{Logical: should the covariance matrix be estimated?}
\item{constraint}{Identification constraint, either \code{"cases"} or \code{"items"}.}
\item{A}{An optional design array for the item intercepts.}
\item{B}{An optional design array for the (fixed) item slopes / scoring.}
\item{B.fixed}{An optional matrix for fixing entries of the loading array \code{B}.}
\item{Q}{An optional loading (Q-) matrix mapping items to dimensions.}
\item{est.slopegroups}{An optional vector grouping items with common slope design (advanced use).}
\item{E}{An optional design array used together with \code{est.slopegroups}.}
\item{pweights}{An optional vector of person (case) weights.}
\item{userfct.variance}{An optional user function imposing constraints on the covariance matrix.}
\item{variance.Npars}{The number of estimated parameters in a user-constrained covariance matrix.}
\item{item.elim}{Logical: should items with no observed responses in a category be eliminated?}
\item{verbose}{Logical: print progress during estimation?}
\item{control}{A list of control arguments for the estimation (e.g. \code{maxiter}, \code{conv}, \code{snodes}, \code{nodes}). Performance-related elements: \code{n_threads} (threads for the parallel E-step; default and maximum = 2), \code{fast} (logical, default \code{FALSE}; opt-in approximate mode that prunes negligible-weight quadrature nodes), and \code{fast_threshold} (pruning cutoff, default \code{1e-6}).}
\item{object, x}{An object of class \code{irtc} as produced by \code{irtc.mml}.}
\item{file}{An optional file name; if supplied, summary output is written there.}
\item{\dots}{Further arguments passed to methods.}
}
\value{
An object of class \code{irtc}, a list with (among others) the components:
\item{xsi}{A data frame of estimated item parameters and standard errors.}
\item{beta}{The estimated latent regression coefficients.}
\item{variance}{The estimated covariance matrix of the latent dimensions.}
\item{person}{A data frame of person parameter estimates (EAP) and related statistics.}
\item{EAP.rel}{The EAP reliability per dimension.}
\item{deviance}{The deviance (\eqn{-2 \log L}) at the solution.}
\item{ic}{A list of information criteria (AIC, BIC, \dots).}
\item{CALL}{The matched call.}
}
\references{
Adams, R. J., Wilson, M., & Wang, W. C. (1997). The multidimensional random
coefficients multinomial logit model. \emph{Applied Psychological
Measurement, 21}(1), 1--23. \doi{10.1177/0146621697211001}
}
\seealso{
\code{\link{irtc.mml.2pl}} for models with estimated item slopes.
}
\examples{
\donttest{
#############################################################################
# EXAMPLE 1: Unidimensional Rasch model
#############################################################################

data(data.sim.rasch)
mod1 <- irtc.mml(resp = data.sim.rasch)
summary(mod1)

#############################################################################
# EXAMPLE 2: Partial credit model
#############################################################################

data(data.gpcm)
mod2 <- irtc.mml(resp = data.gpcm, irtmodel = "PCM")
summary(mod2)
}
}
\keyword{models}
