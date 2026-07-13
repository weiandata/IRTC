# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_summary_display.R

irtc_summary_display <- function(symbol="-", len=60)
{
    paste0(strrep(symbol, len), "\n")
}
