# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_prior_eval_log_density_one_parameter.R

irtc_prior_eval_log_density_one_parameter <- function(density_pp, args_pp,
        parameter_pp, deriv=0)
{
    args_pp$x <- parameter_pp
    loc <- args_pp$mean
    scale <- args_pp$sd
    x <- args_pp$x

    if (density_pp == "norm") {
        if (deriv == 0) {
            res <- -0.5 * log(2 * pi) - log(scale) - (x - loc)^2 / (2 * scale^2)
        }
        if (deriv == 1) {
            res <- -(x - loc) / scale^2
        }
        if (deriv == 2) {
            res <- -1 / scale^2
        }
    }
    res
}
