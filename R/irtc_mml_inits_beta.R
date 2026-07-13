# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_inits_beta.R

irtc_mml_inits_beta <- function(Y, formulaY, dataY, G, group, groups, nstud,
        pweights, ridge, beta.fixed, xsi.fixed, constraint, ndim, beta.inits)
{
    nullY <- is.null(Y)

    if (!is.null(formulaY)) {
        formulaY <- stats::as.formula(formulaY)
        Y <- stats::model.matrix(formulaY, dataY)[, -1]
        nullY <- FALSE
    }

    if (!nullY) {
        Y <- as.matrix(Y)
        nreg <- ncol(Y)
        if (is.null(colnames(Y))) {
            colnames(Y) <- paste0("Y", seq_len(nreg))
        }
        Y <- cbind(1, Y)
        colnames(Y)[1L] <- "Intercept"
    } else {
        Y <- matrix(1, nrow=nstud, ncol=1)
        nreg <- 0
    }

    if (G > 1 & nullY) {
        Y <- matrix(0, nrow=nstud, ncol=G)
        colnames(Y) <- paste0("group", groups)
        for (group_index in seq_len(G)) {
            Y[, group_index] <- as.numeric(group == group_index)
        }
        nreg <- G - 1
    }

    W <- t(Y * pweights) %*% Y
    if (ridge > 0) {
        diag(W) <- diag(W) + ridge
    }
    YYinv <- irtc_ginv_scaled(x=W)

    if (is.null(beta.fixed) & is.null(xsi.fixed) & constraint == "cases") {
        beta.fixed <- cbind(rep(1, ndim), seq_len(ndim), rep(0, ndim))
    }

    if (!is.matrix(beta.fixed)) {
        if (!is.null(beta.fixed)) {
            if (!beta.fixed) {
                beta.fixed <- NULL
            }
        }
    }

    beta <- matrix(0, nrow=nreg+1, ncol=ndim)
    if (!is.null(beta.inits)) {
        beta[beta.inits[, 1:2]] <- beta.inits[, 3]
    }

    list(
        Y=Y, nullY=nullY, formulaY=formulaY, nreg=nreg,
        W=W, YYinv=YYinv, beta.fixed=beta.fixed, beta=beta
    )
}
