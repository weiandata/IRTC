# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_calc_prob.R
irtc_mml_calc_prob <- function(iIndex, A, AXsi, B, xsi, theta,
            nnodes, maxK, recalc=TRUE, use_rcpp=FALSE, maxcat=NULL,
            avoid_outer=FALSE)
{
    if (use_rcpp) {
        if (is.null(maxcat)) {
            use_rcpp <- FALSE
        }
        if (!recalc) {
            use_rcpp <- FALSE
        }
    }

    if (!use_rcpp) {
        probability_result <- irtc_mml_calc_prob_R(
            iIndex=iIndex, A=A, AXsi=AXsi, B=B, xsi=xsi,
            theta=theta, nnodes=nnodes, maxK=maxK, recalc=recalc,
            avoid_outer=avoid_outer
        )
        rprobs <- probability_result$rprobs
        AXsi <- probability_result$AXsi
    } else {
        probability_result <- irtc_rcpp_calc_prob(
            A=as.vector(A), dimA=dim(A), xsi=xsi, maxcat=maxcat,
            AXsi0=AXsi, iIndex=iIndex, theta=theta, B=as.vector(B)
        )
        selected_item_count <- length(iIndex)
        rprobs <- array(
            probability_result$rprobs,
            dim=c(selected_item_count, maxK, nnodes)
        )
        AXsi <- probability_result$AXsi
    }

    list("rprobs"=rprobs, "AXsi"=AXsi)
}

calc_prob.v5 <- irtc_mml_calc_prob
irtc_calc_prob <- irtc_mml_calc_prob
