# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_sufficient_statistics_R.R

irtc_mml_sufficient_statistics_R <- function( nitems, maxK, resp, resp.ind,
        pweights, cA, col.index)
{
    observed_categories <- (resp + 1) * resp.ind
    observed_categories <- observed_categories[, col.index]

    category_grid <- matrix(
        rep(1:maxK, nitems),
        nrow(observed_categories), ncol(observed_categories), byrow=TRUE
    )
    cResp <- 1 * (observed_categories == category_grid)

    if (stats::sd(pweights) > 0) {
        category_totals <- colSums(cResp * pweights)
    } else {
        category_totals <- colSums(cResp)
    }
    ItemScore <- as.vector(t(category_totals) %*% cA)

    list(cResp=cResp, ItemScore=ItemScore)
}
