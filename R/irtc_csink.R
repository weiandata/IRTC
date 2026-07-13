# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_csink.R

irtc_csink <- function(file)
{
    if (!is.null(file)) {
        sink()
    }
    invisible(NULL)
}
