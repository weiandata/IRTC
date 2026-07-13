# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_compute_deviance.R

irtc_mml_compute_deviance <- function( loglike_num, loglike_sto, snodes,
    thetawidth, pweights, deviance=NA, deviance.history=NULL, iter=NULL,
    logprior_xsi=NULL )
{
    previous_deviance <- deviance
    penalty_xsi <- 0
    deviance <- 0

    if (!is.null(logprior_xsi)) {
        penalty_xsi <- -2 * sum(logprior_xsi)
        deviance <- deviance + penalty_xsi
    }

    if (snodes == 0) {
        weighted_log_likelihood <- sum(
            pweights * log(loglike_num * thetawidth)
        )
    } else {
        weighted_log_likelihood <- sum(pweights * log(loglike_sto))
    }
    deviance <- deviance - 2 * weighted_log_likelihood

    signed_change <- deviance - previous_deviance
    relative_change <- abs(signed_change / deviance)
    absolute_change <- abs(signed_change)

    if (!is.null(deviance.history)) {
        deviance.history[iter, 2] <- deviance
    }

    list(
        deviance=deviance,
        deviance_change=absolute_change,
        rel_deviance_change=relative_change,
        deviance.history=deviance.history,
        penalty_xsi=penalty_xsi,
        deviance_change_signed=signed_change
    )
}
