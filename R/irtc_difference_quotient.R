# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_difference_quotient.R

irtc_difference_quotient <- function(d0, d0p, d0m, h)
{
    forward_change <- d0p - d0
    backward_change <- d0 - d0m
    list(
        d1=forward_change / h,
        d2=(forward_change - backward_change) / h^2
    )
}

irtc_mml_3pl_difference_quotient <- irtc_difference_quotient
