# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_normalize_matrix_rows.R

irtc_normalize_matrix_rows <- function(x)
{
    totals <- rowSums(x)
    sweep(x, MARGIN=1, STATS=totals, FUN="/")
}
