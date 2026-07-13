# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_stud_prior.R

# Prior ability density for every person at every quadrature node. The latent
# distribution is normal with person mean Y %*% beta (latent regression) and
# covariance `variance`. Returns an nstud x nnodes matrix gwt.
irtc_stud_prior <- function(theta, Y, beta, variance, nstud,
            nnodes, ndim, YSD, unidim_simplify, snodes=0,
            normalize=FALSE )
{
    if ( ndim == 1 ){
        #--- univariate normal prior
        if ( unidim_simplify ){
            # all persons share one mean (no covariate-driven spread)
            TP <- nrow(theta)
            mean_common <- as.numeric( Y[1, ] %*% beta )
            gwt <- matrix( stats::dnorm( theta[, 1], mean = mean_common,
                            sd = sqrt(variance[1, 1]) ),
                           nrow = nstud, ncol = TP, byrow = TRUE )
        } else {
            person_mean <- Y %*% beta
            gwt <- matrix( stats::dnorm( rep(theta, each = nstud),
                            mean = person_mean, sd = sqrt(variance) ),
                           nrow = nstud )
        }
    } else {
        #--- multivariate normal prior
        person_mean <- Y %*% beta
        variance <- irtc_ginv( x = variance, eps = .05 )   # stabilize before inverting
        varInverse <- solve(variance)
        coeff <- 1 / sqrt( (2 * pi)^ndim * det(variance) )
        if ( YSD ){
            gwt <- irtc_rcpp_prior_normal_density_unequal_means( theta = theta,
                        mu = person_mean, varInverse = varInverse, COEFF = coeff )
        } else {
            gwt <- irtc_rcpp_prior_normal_density_equal_means( theta = theta,
                        mu = person_mean, varInverse = varInverse, COEFF = coeff )
            gwt <- matrix( gwt, nrow = nstud, ncol = nnodes, byrow = TRUE )
        }
    }

    if ( normalize ){ gwt <- irtc_normalize_matrix_rows(gwt) }
    gwt
}

stud_prior.v2 <- irtc_stud_prior
