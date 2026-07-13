# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_ic.R
irtc_mml_ic <- function( nstud, deviance, xsi, xsi.fixed,
    beta, beta.fixed, ndim, variance.fixed, G, irtmodel,
    B_orig=NULL, B.fixed, E, est.variance, resp,
    est.slopegroups=NULL, variance.Npars=NULL, group, penalty_xsi=0,
    AXsi=NULL, pweights=NULL, resp.ind=NULL, B=NULL)
{
    deviance <- deviance - penalty_xsi
    loglike <- - deviance / 2
    logprior <- - penalty_xsi / 2
    logpost <- loglike + logprior

    ic <- data.frame("n"=nstud, "deviance"=deviance)
    ic$loglike <- loglike
    ic$logprior <- logprior
    ic$logpost <- logpost
    dev <- deviance

    ic$Nparsxsi <- length(xsi)
    if (!is.null(xsi.fixed)) {
        ic$Nparsxsi <- ic$Nparsxsi - nrow(xsi.fixed)
    }

    if (!is.null(AXsi)) {
        maxKi <- rowSums(!is.na(AXsi)) - 1
        NB <- dim(B_orig)[3]
        NparsB <- 0
        for (dimension in 1:NB) {
            NparsB <- NparsB + sum(
                maxKi * (rowSums(B_orig[, , dimension]) > 0)
            )
        }
    }

    ic$NparsB <- 0
    if (irtmodel == "2PL") {
        ic$NparsB <- sum(B_orig != 0)
    }
    if (irtmodel == "GPCM") {
        B1 <- B[, 2, ]
        NparsB <- sum(B1 != 0)
        ic$NparsB <- NparsB
    }
    if (irtmodel == "GPCM.groups") {
        ic$NparsB <- length(unique(setdiff(est.slopegroups, 0)))
    }
    if (irtmodel == "GPCM.design") {
        ic$NparsB <- ncol(E)
    }
    if (irtmodel == "2PL.groups") {
        ic$NparsB <- length(unique(setdiff(est.slopegroups, 0)))
    }
    if (!is.null(B.fixed)) {
        nB <- nrow(B.fixed)
        if (irtmodel == "GPCM") {
            nB <- length(B.fixed[B.fixed[, 2] == 2, 1])
        }
        ic$NparsB <- max(ic$NparsB - nB, 0)
    }

    ic$Nparsbeta <- dim(beta)[1] * dim(beta)[2]
    if (!is.null(beta.fixed)) {
        ic$Nparsbeta <- ic$Nparsbeta - nrow(beta.fixed)
    }

    ic$Nparscov <- ndim + ndim * (ndim - 1) / 2
    if (!est.variance) {
        ic$Nparscov <- ic$Nparscov - ndim
    }
    if (!is.null(variance.fixed)) {
        ic$Nparscov <- max(0, ic$Nparscov - nrow(variance.fixed))
    }
    if (!is.null(variance.Npars)) {
        ic$Nparscov <- variance.Npars
    }
    if (!is.null(group)) {
        ic$Nparscov <- ic$Nparscov + length(unique(group)) - 1
    }

    ic$Npars <- ic$np <- ic$Nparsxsi + ic$NparsB + ic$Nparsbeta + ic$Nparscov
    ic$ghp_obs <- irtc_ghp_number_informations(
        pweights=pweights, resp.ind=resp.ind
    )
    ic <- irtc_mml_ic_criteria(ic=ic)

    ic
}

.IRTC.ic <- irtc_mml_ic
