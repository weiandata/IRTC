# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_inits_xsi.R

irtc_mml_inits_xsi <- function(A, resp.ind, ItemScore, xsi.inits, xsi.fixed,
        est.xsi.index, pweights, xsi.start0, xsi, resp, addnumb=.5 )
{
    maxAi <- -apply(-A, 3, irtc_rowMaxs, na.rm=TRUE)
    personMaxA <- resp.ind %*% maxAi
    ItemMax <- crossprod(personMaxA, pweights)

    maxscore.resp <- apply(resp, 2, max)
    if (ncol(resp) > 1) {
        sd.maxscore.resp <- stats::sd(maxscore.resp)
    } else {
        sd.maxscore.resp <- 0
    }
    equal.categ <- !(sd.maxscore.resp > 1E-6)

    estimated_score <- ItemScore[est.xsi.index]
    available_score <- ItemMax[est.xsi.index] - estimated_score
    xsi[est.xsi.index] <- -log(abs(
        (estimated_score + addnumb) / (available_score + addnumb)
    ))

    if (xsi.start0) {
        xsi <- 0 * xsi
    }

    if (!is.null(xsi.inits)) {
        xsi[xsi.inits[, 1]] <- xsi.inits[, 2]
    }
    if (!is.null(xsi.fixed)) {
        xsi[xsi.fixed[, 1]] <- xsi.fixed[, 2]
    }

    list(
        xsi=xsi, personMaxA=personMaxA,
        ItemMax=ItemMax, equal.categ=equal.categ
    )
}
