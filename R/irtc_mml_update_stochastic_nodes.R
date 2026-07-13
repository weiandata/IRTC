# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_update_stochastic_nodes.R

irtc_mml_update_stochastic_nodes <- function(theta0.samp, variance, snodes, beta,
        theta)
{
    if (is.array(variance)) {
        variance_dimensions <- dim(variance)
        if (length(variance_dimensions) == 3) {
            variance <- matrix(
                variance[1, , ],
                nrow=variance_dimensions[2], ncol=variance_dimensions[3]
            )
        }
    }

    theta <- beta[rep(1, snodes), ] + theta0.samp %*% chol(variance)
    thetasamp.density <- irtc_import_mvtnorm_dmvnorm(
        theta, mean=as.vector(beta[1, ]), sigma=variance
    )
    theta2 <- irtc_theta_sq(theta=theta, is_matrix=TRUE)

    list(theta=theta, theta2=theta2, thetasamp.density=thetasamp.density)
}
