# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_latent_regression_standardized_solution.R

irtc_latent_regression_standardized_solution <- function(variance, beta, Y)
{
    res <- NULL
    compute_stand <- TRUE
    if (ncol(Y) == 1) {
        compute_stand <- FALSE
    }
    if (!is.matrix(variance)) {
        compute_stand <- FALSE
    }

    if (compute_stand) {
        N <- nrow(Y)
        ND <- ncol(beta)
        Y_exp <- matrix(0, nrow=N, ncol=ND)
        var_y_exp <- rep(NA, ND)

        for (dimension in 1:ND) {
            Y_exp[, dimension] <- Y %*% beta[, dimension]
            var_y_exp[dimension] <- stats::var(Y_exp[, dimension])
        }

        sd_theta <- sqrt(var_y_exp + diag(variance))
        R2_theta <- var_y_exp / sd_theta^2
        sd_x <- apply(Y, 2, stats::sd)

        NY <- ncol(Y)
        beta_stand <- matrix(NA, nrow=NY*ND, ncol=6)
        colnames(beta_stand) <- c("parm", "dim", "est", "StdYX", "StdX", "StdY")
        beta_stand <- as.data.frame(beta_stand)
        beta_stand$parm <- rep(colnames(Y), ND)

        sd_x0 <- sd_x
        sd_x0[sd_x0 == 0] <- NA
        for (dimension in 1:ND) {
            dimension_rows <- NY * (dimension - 1) + 1:NY
            dimension_sd <- sd_theta[dimension]
            dimension_beta <- beta[, dimension]

            beta_stand[dimension_rows, "dim"] <- dimension
            beta_stand[dimension_rows, "est"] <- dimension_beta
            beta_stand[dimension_rows, "StdX"] <- dimension_beta * sd_x0
            beta_stand[dimension_rows, "StdY"] <- (
                dimension_beta / dimension_sd * (sd_x0 > -10)
            )
            beta_stand[dimension_rows, "StdYX"] <- (
                dimension_beta / dimension_sd * sd_x0
            )
        }

        res <- list(
            beta_stand=beta_stand, R2_theta=R2_theta,
            sd_theta=sd_theta, sd_x=sd_x, var_y_exp=var_y_exp
        )
    }

    res
}
