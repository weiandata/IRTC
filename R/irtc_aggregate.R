# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_aggregate.R

irtc_aggregate <- function(x, group, mean=FALSE, na.rm=TRUE)
{
    grouped_values <- rowsum(x=x, group=group, na.rm=na.rm)
    if (mean) {
        grouped_counts <- rowsum(x=1 + 0 * x, group=group, na.rm=na.rm)
        grouped_values <- grouped_values / grouped_counts
    }

    ng1 <- as.numeric(paste(rownames(grouped_values)))
    cbind(ng1, grouped_values)
}
