# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_2pl_mstep_item_slopes_suffstat_R.R

irtc_mml_2pl_mstep_item_slopes_suffstat_R <- function( rprobs, maxK, LIT, TP, itemwt, theta, dd,
            items.temp, items.conv, xbar, xbar2, xxf, xtemp, irtmodel )
{
    theta_transpose <- t(theta[, dd, drop=FALSE])
    theta_squared_transpose <- t(theta[, dd, drop=FALSE]^2)

    for (category in 1:maxK) {
        category_probabilities <- matrix(
            rprobs[, category, ], nrow=LIT, ncol=TP
        )
        probability_weights <- t(category_probabilities) * itemwt[, items.temp]

        xbar[items.temp, category] <- theta_transpose %*% probability_weights
        xxf[items.temp, category] <- (
            theta_squared_transpose %*% probability_weights
        )

        if (irtmodel == "2PL") {
            xbar2[items.temp, category] <- theta_squared_transpose %*% (
                t(category_probabilities^2) * itemwt[, items.temp]
            )
        }

        if (irtmodel %in% c("GPCM", "GPCM.design")) {
            xxf[items.temp, category] <- (
                xxf[items.temp, category] * (category - 1)^2
            )
            xtemp <- xtemp + (
                irtc_matrix2(theta[, dd], nrow=LIT, ncol=TP) *
                rprobs[, category, ] * (category - 1)
            )
        }

        if (irtmodel == "2PL.groups") {
            grouped_second_moment <- tcrossprod(
                theta_squared_transpose,
                rprobs[, category, ]^2 * t(itemwt[, items.temp])
            )
            xbar2[items.temp, category] <- grouped_second_moment
        }

        if (!is.null(items.conv)) {
            xbar[items.conv, ] <- 0
            xxf[items.conv, ] <- 0
            xbar2[items.conv, ] <- 0
        }
    }

    list(xbar=xbar, xbar2=xbar2, xxf=xxf, xtemp=xtemp)
}
