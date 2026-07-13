# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_osink.R

irtc_osink <- function(file, suffix=".Rout")
{
    if (!is.null(file)) {
        sink(paste0(file, suffix), split=TRUE)
    }
    invisible(NULL)
}
