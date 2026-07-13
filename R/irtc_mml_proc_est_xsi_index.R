# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_proc_est_xsi_index.R

irtc_mml_proc_est_xsi_index <- function(A, xsi.inits, xsi.fixed)
{
    np <- dim(A)[[3]]
    xsi <- rep(0, np)

    if (!is.null(xsi.inits)) {
        xsi[xsi.inits[, 1]] <- xsi.inits[, 2]
    }

    all_parameters <- 1:np
    if (!is.null(xsi.fixed)) {
        xsi[xsi.fixed[, 1]] <- xsi.fixed[, 2]
        est.xsi.index <- setdiff(all_parameters, xsi.fixed[, 1])
    } else {
        est.xsi.index <- all_parameters
    }

    list(np=np, xsi=xsi, est.xsi.index=est.xsi.index)
}
