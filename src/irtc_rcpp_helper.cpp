// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_helper.cpp

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_theta_sq
// Per-person flattened outer product of the ability vector: for person n the
// row holds theta_n theta_n^T laid out as out(n, a*D + b) = theta(n,a)*theta(n,b).
// Used to form second moments of the latent distribution.
// [[Rcpp::export]]
Rcpp::NumericMatrix irtc_rcpp_theta_sq( Rcpp::NumericMatrix theta )
{
    const int N = theta.nrow();
    const int D = theta.ncol();
    Rcpp::NumericMatrix out( N, D*D );
    for (int n = 0; n < N; n++){
        for (int a = 0; a < D; a++){
            const double ta = theta(n, a);
            for (int b = 0; b < D; b++){
                out( n, a*D + b ) = ta * theta(n, b);
            }
        }
    }
    return out;
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_interval_index
// For each row, the 1-based index of the first column whose value exceeds the
// per-row threshold RN[n]; 0 when no column exceeds it. Used to place a drawn
// uniform into a cumulative-probability grid.
// [[Rcpp::export]]
Rcpp::NumericVector irtc_rcpp_interval_index( Rcpp::NumericMatrix MATR,
    Rcpp::NumericVector RN )
{
    const int NR = MATR.nrow();
    const int NC = MATR.ncol();
    Rcpp::NumericVector out( NR );
    for (int n = 0; n < NR; n++){
        int hit = 0;
        for (int c = 0; c < NC; c++){
            if ( MATR(n, c) > RN[n] ){ hit = c + 1; break; }
        }
        out[n] = hit;
    }
    return out;
}
///********************************************************************
