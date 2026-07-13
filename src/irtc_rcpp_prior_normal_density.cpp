// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_prior_normal_density.cpp

// Multivariate normal prior density evaluated on the ability node grid:
//   g(theta) = COEFF * exp( -0.5 * (theta - mu)^T Sigma^{-1} (theta - mu) ).
// COEFF carries the (already computed) normalising constant. The quadratic form
// is summed over the full ndim x ndim index pair, which uses the symmetry of
// Sigma^{-1} implicitly.

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_prior_normal_density_unequal_means
// Person-specific means (latent regression): returns an nstud x nnodes matrix.
// [[Rcpp::export]]
Rcpp::NumericMatrix irtc_rcpp_prior_normal_density_unequal_means(
    Rcpp::NumericMatrix theta, Rcpp::NumericMatrix mu, Rcpp::NumericMatrix varInverse,
    Rcpp::NumericVector COEFF )
{
    const int nnodes = theta.nrow();
    const int ndim = theta.ncol();
    const int nstud = mu.nrow();
    const double coeff = COEFF[0];
    Rcpp::NumericMatrix gwt(nstud, nnodes);
    std::vector<double> x(ndim);

    for (int n = 0; n < nstud; n++){
        for (int q = 0; q < nnodes; q++){
            for (int d = 0; d < ndim; d++){ x[d] = theta(q, d) - mu(n, d); }
            double quad = 0.0;
            for (int a = 0; a < ndim; a++){
                for (int b = 0; b < ndim; b++){
                    quad += x[a] * x[b] * varInverse(a, b);
                }
            }
            gwt(n, q) = coeff * std::exp( -0.5 * quad );
        }
    }
    return gwt;
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_prior_normal_density_equal_means
// Common mean for every person: returns a length-nnodes vector.
// [[Rcpp::export]]
Rcpp::NumericVector irtc_rcpp_prior_normal_density_equal_means(
    Rcpp::NumericMatrix theta, Rcpp::NumericMatrix mu, Rcpp::NumericMatrix varInverse,
    Rcpp::NumericVector COEFF )
{
    const int nnodes = theta.nrow();
    const int ndim = theta.ncol();
    const double coeff = COEFF[0];
    Rcpp::NumericVector gwt(nnodes);
    std::vector<double> x(ndim);

    for (int q = 0; q < nnodes; q++){
        for (int d = 0; d < ndim; d++){ x[d] = theta(q, d) - mu(0, d); }
        double quad = 0.0;
        for (int a = 0; a < ndim; a++){
            for (int b = 0; b < ndim; b++){
                quad += x[a] * x[b] * varInverse(a, b);
            }
        }
        gwt[q] = coeff * std::exp( -0.5 * quad );
    }
    return gwt;
}
///********************************************************************
