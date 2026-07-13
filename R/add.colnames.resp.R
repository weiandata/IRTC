# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: add.colnames.resp.R

add.colnames.resp <- function(resp)
{
    if (!is.null(colnames(resp))) {
        return(resp)
    }

    item_numbers <- 1L:ncol(resp)
    colnames(resp) <- paste("I", item_numbers, sep="")
    resp
}
