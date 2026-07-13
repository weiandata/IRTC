# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_create_nodes.R

# Build the ability integration grid. With snodes == 0 a deterministic
# tensor-product quadrature grid is used; with snodes > 0 the integral is
# approximated by (quasi-)Monte-Carlo draws. A discrete skill space uses the
# supplied support points theta.k directly.
irtc_mml_create_nodes <- function(snodes, nodes, ndim, QMC,
        skillspace="normal", theta.k=NULL)
{
    theta <- theta2 <- thetawidth <- theta0.samp <- thetasamp.density <- NULL
    nnodes <- ntheta <- NULL
    discrete <- ( skillspace == "discrete" )
    do_numeric <- !discrete

    if ( discrete && is.null(theta.k) ){ snodes <- 0 }
    if ( discrete && !is.null(theta.k) ){
        theta <- as.matrix(theta.k)
        nnodes <- ntheta <- nrow(theta)
    }

    #--- deterministic tensor-product quadrature
    if ( snodes == 0 && do_numeric ){
        theta <- irtc_mml_create_nodes_multidim_nodes( nodes=nodes, ndim=ndim )
        if ( skillspace != "normal" && !is.null(theta.k) ){
            theta <- as.matrix(theta.k)
        }
        theta2 <- irtc_theta_sq( theta=theta, is_matrix=TRUE )   # node second moments
        gaps <- diff( theta[, 1] )
        thetawidth <- ( gaps[gaps > 0][1] )^ndim                 # cell volume for deviance
        nnodes <- ntheta <- nrow(theta)
    }

    #--- stochastic (Monte-Carlo / quasi-Monte-Carlo) nodes
    if ( snodes > 0 ){
        if ( QMC ){
            r1 <- irtc_import_sfsmisc_QUnif( n=snodes, min=0, max=1, n.min=1,
                            p=ndim, leap=409 )
            theta0.samp <- stats::qnorm(r1)
            if ( ndim == 1 ){
                theta0.samp <- theta0.samp[ order(theta0.samp[, 1]), ]
            }
        } else {
            theta0.samp <- matrix( irtc_rmvnorm( snodes, mean=rep(0, ndim),
                                sigma=diag(1, ndim) ), nrow=snodes, ncol=ndim )
        }
        theta <- matrix( theta0.samp, nrow=snodes, ncol=ndim )
        nnodes <- ntheta <- snodes
    }

    list( theta=theta, theta2=theta2, thetawidth=thetawidth,
          theta0.samp=theta0.samp, thetasamp.density=thetasamp.density,
          nodes=nodes, snodes=snodes, QMC=QMC, nnodes=nnodes,
          theta.k=theta.k, ntheta=ntheta )
}
