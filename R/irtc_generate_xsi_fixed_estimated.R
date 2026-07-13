# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_generate_xsi_fixed_estimated.R

irtc_generate_xsi_fixed_estimated <- function( xsi, A )
{
    parameter_count <- length(xsi)
    parameter_table <- cbind(1:parameter_count, xsi)
    rownames(parameter_table) <- dimnames(A)[[3]]
    parameter_table
}
