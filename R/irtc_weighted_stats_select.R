# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_weighted_stats_select.R

irtc_weighted_stats_select <- function(x, w, select)
{
    if (!is.null(select)) {
        x <- x[select]
        w <- w[select]
    }

    observed <- which(!is.na(x))
    list(x=x[observed], w=w[observed])
}
