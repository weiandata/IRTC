# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_outer.R

irtc_outer <- function(x,y, op="*")
{
    row_values <- matrix(x, nrow=length(x), ncol=length(y))
    column_values <- irtc_matrix2(y, nrow=length(x), ncol=length(y))
    is_supported <- op == "*" | op == "+" | op == "-"

    if (is_supported) {
        operation <- if (op == "*") {
            function() row_values * column_values
        } else if (op == "+") {
            function() row_values + column_values
        } else {
            function() row_values - column_values
        }
        return(operation())
    }
    NULL
}
