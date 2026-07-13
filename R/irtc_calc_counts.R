# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_calc_counts.R

# Expected counts and ability distribution from the current posterior.
#   n.ik[t, i, k, g]  expected weighted count of category (k-1) on item i at
#                     ability node t within group g
#   pi.k[t, g]        posterior ability distribution at node t within group g
irtc_calc_counts <- function( resp, theta, resp.ind, group, maxK, pweights, hwt )
{
    n_nodes <- nrow(theta)
    n_items <- ncol(resp)
    if ( is.null(group) ){ group <- rep(1, nrow(resp)) }
    G <- length( unique(group) )

    n.ik <- array( 0, dim = c(n_nodes, n_items, maxK, G) )
    for (g in seq_len(G)){
        rows <- which( group == g )
        for (k in seq_len(maxK)){
            # weighted indicator that item i was answered in category (k-1)
            hit <- ( resp[rows, ] == (k - 1) ) * resp.ind[rows, ] * pweights[rows]
            n.ik[, , k, g] <- crossprod( hwt[rows, ], hit )
        }
    }

    wt <- matrix( pweights, nrow = nrow(resp), ncol = ncol(hwt) )
    pi.k <- matrix( NA, nrow = n_nodes, ncol = G )
    for (g in seq_len(G)){
        rows <- which( group == g )
        dens <- colSums( wt[rows, ] * hwt[rows, ] ) / colSums( wt[rows, ] )
        pi.k[, g] <- dens / sum(dens)
    }

    list( "n.ik" = n.ik, "pi.k" = pi.k )
}
