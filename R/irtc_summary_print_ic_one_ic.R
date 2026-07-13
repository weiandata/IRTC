# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_summary_print_ic_one_ic.R

irtc_summary_print_ic_one_ic <- function(ic, crit, digits_ic=0, digits_penalty=2)
{
    value <- ic[[crit]]
    penalty_label <- paste0(
        " | penalty=", round(value - ic$deviance, digits_penalty)
    )
    if (crit == "GHP") {
        digits_ic <- 5
        penalty_label <- ""
    }

    cat(
        crit, "=", round(value, digits_ic), penalty_label,
        "   |", irtc_summary_print_ic_description(crit), "\n"
    )
}
