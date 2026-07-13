# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: weighted_mean.R

weighted_mean <- function( x, w=rep(1,length(x)), select=NULL )
{
    selected <- irtc_weighted_stats_select(x=x, w=w, select=select)
    sum(selected$x * selected$w) / sum(selected$w)
}
