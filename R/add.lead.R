# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: add.lead.R

add.lead <- function(x, width=max(nchar(x)))
{
    integer_formats <- paste("%0", width, "i", sep="")
    sprintf(integer_formats, x)
}
