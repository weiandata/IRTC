% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc.mml.2pl}
\alias{irtc.mml.2pl}
\title{
Marginal Maximum Likelihood Estimation of Slope (Discrimination) Item Response Models
}
\description{
Estimates unidimensional and multidimensional item response models with
estimated item slopes (discriminations) by marginal maximum likelihood
(MML). Supported models are the two-parameter logistic model (\code{"2PL"}),
the generalized partial credit model (\code{"GPCM"}), their design-matrix
and slope-group variants (\code{"GPCM.design"}, \code{"2PL.groups"},
\code{"GPCM.groups"}).
}
\usage{
irtc.mml.2pl(resp, Y = NULL, group = NULL, irtmodel = "2PL",
   formulaY = NULL, dataY = NULL, ndim = 1, pid = NULL,
   xsi.fixed = NULL, xsi.inits = NULL, beta.fixed = NULL, beta.inits = NULL,
   variance.fixed = NULL, variance.inits = NULL, est.variance = FALSE,
   A = NULL, B = NULL, B.fixed = NULL, Q = NULL, est.slopegroups = NULL,
   E = NULL, gamma.init = NULL, pweights = NULL, userfct.variance = NULL,
   variance.Npars = NULL, item.elim = TRUE, verbose = TRUE,
   method = c("auto", "grid", "streaming"), control = list())
}
\arguments{
\item{resp}{A data frame or matrix of item responses (\code{NA} = missing).}
\item{Y}{Optional covariate matrix for the latent regression.}
\item{group}{Optional integer vector of group identifiers for multiple groups.}
\item{irtmodel}{The estimated model: one of \code{"2PL"}, \code{"GPCM"}, \code{"GPCM.design"}, \code{"2PL.groups"}, \code{"GPCM.groups"}.}
\item{formulaY}{Optional formula for the latent regression (with \code{dataY}).}
\item{dataY}{Optional covariate data frame used with \code{formulaY}.}
\item{ndim}{Number of latent dimensions (when no \code{Q}/\code{B} is given).}
\item{pid}{Optional vector of person identifiers.}
\item{xsi.fixed}{Optional matrix (index, value) fixing item intercept parameters.}
\item{xsi.inits}{Optional matrix of initial item parameters.}
\item{beta.fixed}{Optional matrix fixing regression coefficients, or \code{FALSE}.}
\item{beta.inits}{Optional matrix of initial regression coefficients.}
\item{variance.fixed}{Optional matrix fixing covariance entries.}
\item{variance.inits}{Optional initial covariance matrix.}
\item{est.variance}{Logical: estimate the covariance matrix? (default \code{FALSE}).}
\item{A}{Optional design array for item intercepts.}
\item{B}{Optional design array for item slopes.}
\item{B.fixed}{Optional matrix fixing entries of the slope array \code{B}.}
\item{Q}{Optional loading (Q-) matrix mapping items to dimensions.}
\item{est.slopegroups}{Optional vector grouping items that share a common estimated slope.}
\item{E}{Optional design array used with \code{est.slopegroups} / \code{GPCM.design}.}
\item{gamma.init}{Optional initial values for the estimated slope parameters.}
\item{pweights}{Optional vector of person (case) weights.}
\item{userfct.variance}{Optional user function constraining the covariance matrix.}
\item{variance.Npars}{Number of estimated parameters in a user-constrained covariance.}
\item{item.elim}{Logical: eliminate items with empty response categories?}
\item{verbose}{Logical: print estimation progress?}
\item{method}{Estimation engine. \code{"grid"} is the standard full-quadrature path. \code{"streaming"} routes to a dimension-factorized streaming engine for large between-item (simple-structure) multidimensional 2PL/GPCM models; it supports latent regression (\code{Y}), multiple groups (\code{group}, with per-group covariances), and case weights (\code{pweights}), but not the advanced item-design arguments (\code{A}, \code{B}, \code{xsi.fixed}, etc.), which force \code{"grid"}. \code{"auto"} (default) predicts which engine is faster from \code{(N, items, dims, nodes, unique covariate patterns)} and routes accordingly (falling back to \code{"grid"} for unidimensional/small/unsupported models); the chosen engine and reasoning are returned in the \code{routing} component of the result. With case weights the result also reports the Kish effective sample size in \code{n_eff}.}
\item{control}{List of control arguments (e.g. \code{maxiter}, \code{conv}, \code{nodes}, \code{Msteps}). Performance-related elements: \code{n_threads} (threads for the parallel E-step and slope M-step; default and maximum = 2), \code{fast} (logical, default \code{FALSE}; approximate mode pruning negligible-weight quadrature nodes), \code{fast_threshold} (pruning cutoff, default \code{1e-6}), and \code{acceleration} (\code{"none"} default, or \code{"squarem"}/\code{"Ramsay"}/\code{"Yu"} to accelerate the grid EM). The streaming engine additionally accepts \code{reg} for opt-in statistical regularization (\code{slope_penalty}, \code{slope_max}, \code{sigma_shrink}, and \code{sigma_shrink_pooled} for shrinking per-group covariances toward the pooled estimate; default off), and \code{group_structure} (\code{"full"} = independent per-group covariances, default; \code{"mean"} = shared covariance with free group means).

When \code{fast=TRUE} the streaming engine prunes quadrature nodes by a calibrated \code{mass_budget} (default \code{1e-3}): after a few full-grid burn-in iterations it drops the lowest-importance nodes holding at most that fraction of the combined prior-and-posterior mass, retained per (covariate, group) pattern and unioned so extreme responders and small groups are protected. \code{mass_budget} is a pruning budget, \emph{not} a guaranteed error. The real accuracy is \emph{measured}: with \code{verify="stratified"} (default) a stratified subsample (groups, high weights, extreme responders, high-missingness; \code{verify_n}, \code{verify_seed}) is run through both the full and pruned grids at the final parameters, and the per-metric error quantiles (deviance / EAP / posterior moments / one-M-step parameter change, against \code{tol_deviance}/\code{tol_eap}/\code{tol_moment}/\code{tol_par}) are returned in \code{accuracy_report} with a \code{met} verdict. \code{refine=TRUE} refits with a tighter budget until the tolerances are met.}
}
\value{
An object of class \code{irtc} (see \code{\link{irtc.mml}}) with, in addition,
the estimated slope array \code{B} and the slope parameter vector. Streaming-engine
fits also carry a \code{routing} component (chosen engine and reasoning) and, when
\code{fast=TRUE} with verification on, an \code{accuracy_report}: a measured,
stratified approximation check (per-metric error quantiles plus a \code{met}
verdict), \emph{not} a strict mathematical error bound.
}
\seealso{
\code{\link{irtc.mml}} for fixed-slope (Rasch / PCM / RSM) models.
}
\examples{
\donttest{
data(data.sim.rasch)
mod1 <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL")
summary(mod1)

data(data.gpcm)
mod2 <- irtc.mml.2pl(resp = data.gpcm, irtmodel = "GPCM")
summary(mod2)
}
}
\keyword{models}
