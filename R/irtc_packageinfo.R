# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_packageinfo.R

irtc_packageinfo <- function(pack)
{
    description <- utils::packageDescription(pkg=pack)
    paste0(
        description$Package, " ", description$Version,
        " (", description$Date, ")"
    )
}
