# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_theta_sq.R

irtc_theta_sq <- function(theta, is_matrix=FALSE )
{
    node_count <- nrow(theta)
    dimension_count <- ncol(theta)
    native_products <- irtc_rcpp_theta_sq(theta=theta)

    second_moments <- array(
        native_products,
        dim=c(node_count, dimension_count, dimension_count)
    )
    if (is_matrix) {
        dim(second_moments) <- c(node_count, dimension_count^2)
    }
    second_moments
}

theta.sq2 <- irtc_theta_sq
