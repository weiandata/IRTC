# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_se_AXsi.R

irtc_mml_se_AXsi <- function(AXsi, A, se.xsi, maxK)
{
    se.AXsi <- 0 * AXsi
    design <- A
    design[is.na(A)] <- 0

    if (length(se.xsi) > 1) {
        xsi_variance <- diag(se.xsi^2)
    } else {
        xsi_variance <- matrix(se.xsi^2, 1, 1)
    }

    design_dimensions <- dim(design)
    for (category in 1:maxK) {
        category_design <- design[, category, ]
        if (is.vector(category_design)) {
            category_design <- matrix(
                category_design,
                nrow=design_dimensions[1], ncol=design_dimensions[3]
            )
        }
        propagated_variance <- (
            category_design %*% xsi_variance %*% t(category_design)
        )
        se.AXsi[, category] <- sqrt(diag(propagated_variance))
    }

    se.AXsi
}
