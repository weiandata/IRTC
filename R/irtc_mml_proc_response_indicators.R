# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_proc_response_indicators.R

irtc_mml_proc_response_indicators <- function(resp, nitems)
{
    missing <- is.na(resp)
    resp.ind <- 1 - missing
    nomiss <- sum(missing) == 0

    item_sequence <- 1:nitems
    resp.ind.list <- list(item_sequence)
    for (item in item_sequence) {
        resp.ind.list[[item]] <- which(resp.ind[, item] == 1)
    }

    resp[missing] <- 0
    list(resp=resp, resp.ind=resp.ind, resp.ind.list=resp.ind.list, nomiss=nomiss)
}
