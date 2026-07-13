# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_mstep_regression.R
irtc_mml_mstep_regression <- function( resp, hwt,  resp.ind,
    pweights, pweightsM, Y, theta, theta2, YYinv, ndim,
    nstud, beta.fixed, variance, Variance.fixed, group, G,
    snodes=0, thetasamp.density=NULL, nomiss=FALSE, iter=1E9,
    min.variance=0, userfct.variance=NULL,
    variance_acceleration=NULL, est.variance=TRUE, beta=NULL,
    latreg_use=FALSE, gwt=NULL, importance_sampling=FALSE )
{
    variance.fixed <- Variance.fixed
    beta_old <- beta
    variance_old <- variance
    itemwt <- NULL

    if (snodes == 0) {
        hwt_colsums <- colSums(hwt*pweights)
        if (!latreg_use) {
            if (!nomiss) {
                itemwt <- crossprod(hwt, resp.ind * pweightsM)
            }
            if (nomiss) {
                itemwt <- matrix(
                    hwt_colsums, nrow=ncol(hwt), ncol=ncol(resp.ind)
                )
            }
        }

        thetabar <- hwt %*% theta
        sumbeta <- crossprod(Y, thetabar*pweights)
        sumsig2 <- as.vector(crossprod(hwt_colsums, theta2))
    }

    if (snodes > 0) {
        if (importance_sampling) {
            hwt0 <- hwt / gwt
            TP <- length(thetasamp.density)
            tsd <- irtc_matrix2(thetasamp.density, nrow=nstud, ncol=TP)
            rej_prob <- gwt / tsd
            rnm <- irtc_matrix2(stats::runif(TP), nrow=nstud, ncol=TP)
            hwt_acc <- 1 * (rej_prob > rnm)
            hwt <- irtc_normalize_matrix_rows(hwt0 * tsd * hwt_acc)
        }

        if (!latreg_use) {
            hwt <- hwt / rowSums(hwt)
            itemwt <- crossprod(hwt, resp.ind*pweightsM)
        }

        thetabar <- hwt %*% theta
        sumbeta <- crossprod(Y, thetabar*pweights)
        sumsig2 <- as.vector(crossprod(colSums(pweights * hwt), theta2))
    }

    beta <- YYinv %*% sumbeta
    sumsig2 <- matrix(sumsig2, nrow=ndim, ncol=ndim)
    if (G == 1) {
        variance <- (sumsig2 - crossprod(sumbeta, beta))/nstud
    }

    if (!is.null(beta.fixed)) {
        beta[beta.fixed[, 1:2, drop=FALSE]] <- beta.fixed[, 3]
        beta <- as.matrix(beta, ncol=ndim)
    }

    if (!is.null(variance.fixed)) {
        variance[variance.fixed[, 1:2, drop=FALSE]] <- variance.fixed[, 3]
        variance[variance.fixed[, c(2, 1), drop=FALSE]] <- variance.fixed[, 3]
    }

    if (G > 1) {
        if (snodes > 0) {
            hwt <- hwt / snodes
            hwt <- hwt / rowSums(hwt)
        }

        for (group_index in 1:G) {
            group_students <- which(group == group_index)
            thetabar <- hwt[group_students, ] %*% theta
            sumbeta <- crossprod(
                Y[group_students, ], thetabar*pweights[group_students]
            )
            sumsig2 <- colSums(
                (pweights[group_students]*hwt[group_students, ]) %*% theta2
            )
            sumsig2 <- matrix(sumsig2, ndim, ndim)
            variance[group_students] <- (
                sumsig2 - crossprod(sumbeta, beta)
            ) / sum(pweights[group_students])
        }
    }

    eps <- 1E-10
    if (ndim == 1) {
        variance[variance < min.variance] <- min.variance
    }
    if (G == 1) {
        diag(variance) <- diag(variance) + eps
    }
    if (!est.variance) {
        if (G == 1) {
            variance <- stats::cov2cor(variance)
        }
        if (G > 1) {
            variance[group == 1] <- 1
        }
    }

    if (!is.null(userfct.variance)) {
        variance <- do.call(userfct.variance, list(variance))
    }

    if (iter < 4) {
        na_variance <- sum(is.na(variance)) > 0
        if (na_variance) {
            message <- paste0(
                "Problems in variance estimation.\n ",
                "Try to Choose argument control=list( xsi.start0=TRUE, ...) "
            )
            stop(message)
        }
    }

    if (!is.null(variance_acceleration)) {
        if (variance_acceleration$acceleration != "none") {
            variance_acceleration <- irtc_accelerate_parameters(
                xsi_acceleration=variance_acceleration,
                xsi=as.vector(variance), iter=iter, itermin=3
            )
            variance <- matrix(
                variance_acceleration$parm,
                nrow=nrow(variance), ncol=ncol(variance)
            )
        }
    }

    beta_change <- max(abs(beta - beta_old))
    variance_change <- max(abs(as.vector(variance) - as.vector(variance_old)))

    list(
        beta=beta, variance=variance, itemwt=itemwt,
        variance_acceleration=variance_acceleration,
        beta_change=beta_change, variance_change=variance_change
    )
}

mstep.regression <- irtc_mml_mstep_regression
