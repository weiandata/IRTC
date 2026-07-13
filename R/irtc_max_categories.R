# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_max_categories.R

irtc_max_categories <- function(resp)
{
    if (is.vector(resp)) {
        resp <- matrix(resp, ncol=1)
    }

    item_count <- ncol(resp)
    if (item_count <= 1) {
        return(max(resp[, 1], na.rm=TRUE))
    }

    maxima <- unlist(
        lapply(seq_len(item_count), function(item) {
            max(resp[, item], na.rm=TRUE)
        }),
        use.names=FALSE
    )
    names(maxima) <- colnames(resp)
    maxima
}
