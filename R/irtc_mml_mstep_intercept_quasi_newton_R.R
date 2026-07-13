# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_mstep_intercept_quasi_newton_R.R

irtc_mml_mstep_intercept_quasi_newton_R <- function( rprobs, converge, Miter, Msteps,
    nitems, A, AXsi, B, xsi, theta, nnodes, maxK, est.xsi.index, itemwt, indexIP.no,
    indexIP.list2, Avector, ItemScore, xsi.fixed, eps=1E-20, old_increment, convM,
    fac.oldxsi, oldxsi, trim_increment, progress, np, increments_msteps, maxcat=NULL,
    use_rcpp=FALSE )
{
    while (!converge & Miter <= Msteps) {
        if (Miter > 1) {
            probability_result <- irtc_mml_calc_prob(
                iIndex=1:nitems, A=A, AXsi=AXsi, B=B, xsi=xsi,
                theta=theta, nnodes=nnodes, maxK=maxK,
                maxcat=maxcat, use_rcpp=use_rcpp
            )
            rprobs <- probability_result$rprobs
        }

        expected <- irtc_calc_exp(
            rprobs=rprobs, A=A, np=np, est.xsi.index=est.xsi.index,
            itemwt=itemwt, indexIP.no=indexIP.no,
            indexIP.list2=indexIP.list2, Avector=Avector
        )
        score_difference <- as.vector(ItemScore) - expected$xbar
        information_derivative <- expected$xbar2 - expected$xxf

        increment <- score_difference * abs(1 / (information_derivative + eps))
        if (!is.null(xsi.fixed)) {
            increment[xsi.fixed[, 1]] <- 0
        }

        increment <- irtc_trim_increment(
            increment=increment, max.increment=old_increment,
            trim_increment=trim_increment
        )
        old_increment <- increment

        se.xsi <- sqrt(1 / abs(information_derivative))
        if (!is.null(xsi.fixed)) {
            se.xsi[xsi.fixed[, 1]] <- 0
        }

        xsi <- xsi + increment

        max_change <- max(abs(increment))
        increments_msteps[Miter] <- max_change
        if (max_change < convM) {
            converge <- TRUE
        }

        Miter <- Miter + 1
        if (fac.oldxsi > 0) {
            xsi <- (1 - fac.oldxsi) * xsi + fac.oldxsi * oldxsi
        }

        if (progress) {
            cat("-")
            utils::flush.console()
        }
    }

    list(
        xsi=xsi, Miter=Miter, increments_msteps=increments_msteps,
        se.xsi=se.xsi, logprior_xsi=0
    )
}
