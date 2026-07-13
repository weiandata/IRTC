# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_inits_variance.R

irtc_mml_inits_variance <- function(variance.inits, ndim, variance.fixed)
{
    variance <- if (is.null(variance.inits)) diag(ndim) else variance.inits

    if (!is.null(variance.fixed)) {
        coordinates <- variance.fixed[, 1:2, drop=FALSE]
        variance[coordinates] <- variance.fixed[, 3]
        variance[coordinates[, 2:1, drop=FALSE]] <- variance.fixed[, 3]
    }

    list(variance=variance)
}
