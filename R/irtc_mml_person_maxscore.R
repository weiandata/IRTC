# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_person_maxscore.R

irtc_mml_person_maxscore <- function(resp, resp.ind=NULL)
{
    if (is.null(resp.ind)) {
        resp.ind <- 1 - is.na(resp)
    }

    person_count <- nrow(resp)
    item_maxima <- apply(resp, 2, max, na.rm=TRUE)
    available_maxima <- matrix(
        item_maxima,
        nrow=person_count, ncol=ncol(resp), byrow=TRUE
    )
    rowSums(available_maxima * resp.ind)
}
