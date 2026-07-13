# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_print_computation_time.R

irtc_print_computation_time <- function(object)
{
    finished_at <- object$time[2]
    elapsed <- finished_at - object$time[1]

    cat("Date of Analysis:", paste(finished_at), "\n")
    print(elapsed)
    cat("Computation time:", elapsed, "\n\n")
}
