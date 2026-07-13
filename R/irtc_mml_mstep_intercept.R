# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_mstep_intercept.R

irtc_mml_mstep_intercept <- function( A, xsi, AXsi, B, theta, nnodes, maxK,
        Msteps, rprobs, np, est.xsi.index0, itemwt, indexIP.no, indexIP.list2,
        Avector, max.increment, xsi.fixed, fac.oldxsi, ItemScore, convM,
        progress, nitems, iter, increment.factor, xsi_acceleration,
        trim_increment="cut", prior_list_xsi=NULL, eps=1E-20,
        mstep_intercept_method="R", n.ik=NULL, maxcat=NULL)
{
    converge <- FALSE
    logprior_xsi <- 0
    Miter <- 1

    old_increment <- rep(max.increment, np)
    est.xsi.index <- est.xsi.index0
    oldxsi <- xsi
    increments_msteps <- rep(NA, Msteps)
    if (progress) {
        cat("M Step Intercepts   |")
        utils::flush.console()
    }

    if (mstep_intercept_method == "optim") {
        res <- irtc_mml_mstep_intercept_optim(
            xsi, n.ik, prior_list_xsi, nitems, A,
            AXsi, B, theta, nnodes, maxK, Msteps, xsi.fixed
        )
    }

    if (mstep_intercept_method == "R") {
        res <- irtc_mml_mstep_intercept_quasi_newton_R(
            rprobs=rprobs, converge=converge, Miter=Miter,
            Msteps=Msteps, nitems=nitems, A=A, AXsi=AXsi, B=B,
            xsi=xsi, theta=theta, nnodes=nnodes, maxK=maxK,
            est.xsi.index=est.xsi.index, itemwt=itemwt,
            indexIP.no=indexIP.no, indexIP.list2=indexIP.list2,
            Avector=Avector, ItemScore=ItemScore, xsi.fixed=xsi.fixed,
            eps=eps, old_increment=old_increment, convM=convM,
            fac.oldxsi=fac.oldxsi, oldxsi=oldxsi,
            trim_increment=trim_increment, progress=progress, np=np,
            increments_msteps=increments_msteps, maxcat=maxcat,
            use_rcpp=TRUE
        )
    }

    xsi <- res$xsi
    Miter <- res$Miter
    increments_msteps <- res$increments_msteps
    se.xsi <- res$se.xsi
    logprior_xsi <- res$logprior_xsi

    if (increment.factor > 1) {
        max.increment <- 1 / increment.factor^iter
    }

    if (xsi_acceleration$acceleration != "none") {
        xsi_acceleration <- irtc_accelerate_parameters(
            xsi_acceleration=xsi_acceleration, xsi=xsi,
            iter=iter, itermin=3
        )
        xsi <- xsi_acceleration$parm
    }

    xsi_change <- max(abs(xsi - oldxsi))
    list(
        xsi=xsi, max.increment=max.increment, se.xsi=se.xsi, Miter=Miter,
        xsi_acceleration=xsi_acceleration, xsi_change=xsi_change,
        Miter=Miter, increments_msteps=increments_msteps,
        logprior_xsi=logprior_xsi
    )
}
