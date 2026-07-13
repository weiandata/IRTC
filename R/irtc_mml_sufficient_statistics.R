# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_sufficient_statistics.R

# Observed sufficient statistics for the item parameters: the one-hot response
# encoding cResp and the design-mapped item score vector ItemScore. Dispatches
# to the native kernel or the R fallback.
irtc_mml_sufficient_statistics <- function( nitems, maxK, resp, resp.ind,
        pweights, cA, progress, use_rcpp=TRUE )
{
    cA[is.na(cA)] <- 0
    col.index <- rep( seq_len(nitems), each = maxK )

    res <- if ( use_rcpp ){
        irtc_rcpp_calc_suff_stat( resp=resp, resp_ind=resp.ind, maxK=maxK,
                    nitems=nitems, pweights=pweights, cA=cA )
    } else {
        irtc_mml_sufficient_statistics_R( nitems=nitems, maxK=maxK, resp=resp,
                    resp.ind=resp.ind, pweights=pweights, cA=cA,
                    col.index=col.index )
    }

    if ( progress ){
        cat( "    * Calculated Sufficient Statistics   (",
             paste(Sys.time()), ")\n" )
        utils::flush.console()
    }

    list( cResp = res$cResp, ItemScore = res$ItemScore, col.index = col.index )
}
