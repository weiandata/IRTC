# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_ginv.R

irtc_ginv <- function(x, eps=.05)
{
    decomposition <- svd(x)
    original_spectrum <- decomposition$d
    requires_stabilization <- original_spectrum < eps
    if (!any(requires_stabilization)) return(x)

    adjusted_spectrum <- pmax(original_spectrum, eps)
    adjusted_spectrum <- adjusted_spectrum *
        (sum(original_spectrum) / sum(adjusted_spectrum))
    scaled_left_vectors <- sweep(
        decomposition$u, MARGIN=2, STATS=adjusted_spectrum, FUN="*"
    )
    scaled_left_vectors %*% t(decomposition$v)
}
