# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_ginv_scaled.R

irtc_ginv_scaled <- function(x, use_MASS=TRUE)
{
    standard_deviation <- sqrt(diag(x))
    scale <- irtc_outer(standard_deviation, standard_deviation)
    correlation <- x / scale
    inverse_correlation <- if (use_MASS) {
        irtc_import_MASS_ginv(X=correlation)
    } else {
        irtc_ginv(x=correlation)
    }
    inverse_standard_deviation <- 1 / standard_deviation
    inverse_scale <- irtc_outer(
        inverse_standard_deviation, inverse_standard_deviation
    )
    inverse_correlation * inverse_scale
}
