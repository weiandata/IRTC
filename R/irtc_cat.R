# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_cat.R

irtc_cat <- function(label, time0, active)
{
    if (!active) {
        return(NULL)
    }

    cat(label, "  ")
    current_time <- Sys.time()
    print(current_time - time0)
    current_time
}
