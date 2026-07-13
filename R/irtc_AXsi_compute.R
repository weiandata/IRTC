# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_AXsi_compute.R

irtc_AXsi_compute <- function(A, xsi)
{
    if (dim(A)[2] == 0) {
        A[, 1, ]
    }
    category_predictors <- lapply(seq_len(dim(A)[2]), function(category) {
        A[, category, ] %*% xsi
    })
    unname(do.call(cbind, category_predictors))
}
