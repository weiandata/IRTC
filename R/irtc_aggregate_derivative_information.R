# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_aggregate_derivative_information.R

irtc_aggregate_derivative_information <- function(deriv, groups)
{
    totals <- stats::aggregate(deriv, list(groups), sum)
    totals[totals[, 1] == 0, 2] <- 0
    group_rows <- match(groups, totals[, 1])
    totals[group_rows, 2]
}
