# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_include_NA_AXsi.R

irtc_mml_include_NA_AXsi <- function(AXsi, maxcat=NULL, A=NULL, xsi=NULL)
{
    if (!is.null(xsi)) {
        AXsi <- irtc_AXsi_compute(A=A, xsi=xsi)
    }
    if (is.null(maxcat)) {
        maxcat <- rep(ncol(AXsi), nrow(AXsi))
    }

    largest_category_count <- max(maxcat)
    needs_padding <- mean(maxcat == largest_category_count) < 1
    if (anyNA(AXsi)) {
        needs_padding <- FALSE
    }

    if (needs_padding) {
        unavailable <- outer(
            maxcat, seq_len(largest_category_count),
            function(item_categories, category) category > item_categories
        )
        AXsi[unavailable] <- NA
    }
    AXsi
}
