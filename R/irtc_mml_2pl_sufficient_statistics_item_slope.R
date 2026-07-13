# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_2pl_sufficient_statistics_item_slope.R

irtc_mml_2pl_sufficient_statistics_item_slope <- function(hwt, theta, cResp,
    pweights, maxK, nitems, ndim)
{
    thetabar <- hwt %*% theta
    cB_obs <- crossprod(cResp*pweights, thetabar)
    B_obs <- aperm(
        array(cB_obs, dim=c(maxK, nitems, ndim)), c(2, 1, 3)
    )

    list(thetabar=thetabar, cB_obs=cB_obs, B_obs=B_obs)
}
