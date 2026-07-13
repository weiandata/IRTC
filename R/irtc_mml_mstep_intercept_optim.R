# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_mstep_intercept_optim.R

irtc_mml_mstep_intercept_optim <- function( xsi, n.ik, prior_list_xsi, nitems, A,
        AXsi, B, theta, nnodes, maxK, Msteps, xsi.fixed, eps=1E-40)
{
    NX <- length(xsi)
    oldxsi <- xsi

    posterior_xsi <- function(x) {
        rprobs <- irtc_mml_calc_prob(
            iIndex=1:nitems, A=A, AXsi=AXsi, B=B,
            xsi=x, theta=theta, nnodes=nnodes, maxK=maxK,
            recalc=TRUE
        )$rprobs

        G <- dim(n.ik)[4]
        counts <- array(0, dim=dim(n.ik)[1:3])
        for (group_index in 1:G) {
            counts <- counts + n.ik[, , , group_index]
        }

        rprobs <- aperm(rprobs, c(3, 1, 2))
        rprobs[is.na(rprobs)] <- 0
        rprobs <- rprobs + eps

        log_likelihood <- 0
        for (category in 1:maxK) {
            log_likelihood <- log_likelihood + sum(
                counts[, , category] * log(rprobs[, , category])
            )
        }

        logprior <- irtc_evaluate_prior(
            prior_list=prior_list_xsi, parameter=xsi, derivatives=FALSE
        )$d0
        -(log_likelihood + sum(logprior))
    }

    lower <- rep(-Inf, NX)
    upper <- rep(Inf, NX)
    if (!is.null(xsi.fixed)) {
        eps0 <- 1e-4
        lower[xsi.fixed[, 1]] <- xsi.fixed[, 2] - eps0
        upper[xsi.fixed[, 1]] <- xsi.fixed[, 2] + eps0
    }

    optimization <- stats::optim(
        par=xsi, fn=posterior_xsi, method="L-BFGS-B",
        lower=lower, upper=upper, control=list(maxit=Msteps),
        hessian=TRUE
    )
    xsi <- optimization$par

    increment <- xsi - oldxsi
    increment <- irtc_trim_increment(
        increment=increment, max.increment=1, trim_increment="cut"
    )
    xsi <- oldxsi + increment

    se.xsi <- sqrt(diag(solve(optimization$hessian)))
    logprior_xsi <- irtc_evaluate_prior(
        prior_list=prior_list_xsi, parameter=xsi
    )$d0

    list(xsi=xsi, se.xsi=se.xsi, logprior_xsi=logprior_xsi)
}
