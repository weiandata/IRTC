# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_calc_posterior.R

# E-step posterior over ability nodes. The joint (person x node) weight is the
# prior times the likelihood of the observed responses, the latter accumulated
# item by item in the native kernel irtc_calcfx. Dividing by the row totals
# gives the individual posterior hwt; the row totals rfx are the marginal
# likelihood contributions used for the deviance.
irtc_calc_posterior <- function(rprobs, gwt, resp, nitems,
            resp.ind.list, normalization=TRUE,
            thetasamp.density=NULL, snodes=0, resp.ind=NULL,
            avoid.zerosum=FALSE, logprobs=FALSE, n_threads=1L,
            fast=FALSE, fast_threshold=1e-6 )
{
    n_persons <- nrow(gwt)
    prior <- gwt
    tsd <- NULL

    # stochastic integration: convert prior weights into importance weights
    if ( snodes > 0 ){
        tsd <- matrix( thetasamp.density, nrow=n_persons, ncol=ncol(gwt), byrow=TRUE )
        prior <- gwt / tsd / ncol(gwt)
    }

    storage.mode(resp) <- "integer"

    # optional fast mode: skip quadrature nodes carrying negligible prior mass
    keep <- NULL
    if ( fast && snodes == 0 ){
        node_mass <- colSums(prior)
        keep <- which( node_mass >= fast_threshold * max(node_mass) )
        if ( length(keep) == ncol(prior) ){ keep <- NULL }
    }

    # joint weight = prior * product over items of the response probability
    if ( is.null(keep) ){
        joint <- irtc_calcfx( prior, rprobs, resp.ind.list, resp, n_threads )
    } else {
        joint <- matrix( 0, nrow=n_persons, ncol=ncol(prior) )
        joint[, keep] <- irtc_calcfx( prior[, keep, drop=FALSE],
                            rprobs[, , keep, drop=FALSE], resp.ind.list, resp,
                            n_threads )
    }

    # keep normalization finite for all-zero or NA rows
    if ( avoid.zerosum ){
        row_tot <- rowSums(joint)
        floor_val <- max( min( row_tot[row_tot > 0], na.rm=TRUE ), 1e-200 ) /
                        1e3 / ncol(joint)
        joint[ row_tot == 0, ] <- floor_val
        joint[ is.na(row_tot), ] <- floor_val
    }

    rfx <- rowSums(joint)
    hwt <- if ( normalization ) joint / rfx else joint

    res <- list( hwt=hwt, rfx=rfx, fx1 = joint / prior )
    if ( snodes > 0 ){
        res$swt <- joint
        res$gwt <- prior
    }
    res$tsd <- tsd
    res
}

calc_posterior.v2 <- irtc_calc_posterior
