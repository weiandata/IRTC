// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_calc_prob.cpp

// E-step response probabilities for the generalized item response model.
//
// For item i, response category k in {0, .., K_i-1} and ability node theta_t
// (a D-dimensional latent vector) the model log-odds are
//
//     eta_{ikt} = AXsi_{ik} + sum_d B_{ikd} * theta_{td},
//     AXsi_{ik} = sum_p A_{ikp} * xsi_p,
//
// and the category probability is the softmax over k:
//
//     P(X_i = k | theta_t) = exp(eta_{ikt}) / sum_h exp(eta_{iht}).
//
// The softmax subtracts the per-(item, node) maximum log-odds before
// exponentiating, which is numerically stable and leaves the ratio unchanged.
// Multidimensional arrays A (I x maxK x nPar), B (I x maxK x D) and the output
// probability cube (nSel x maxK x nNodes) are passed as column-major flat
// vectors; the index arithmetic below matches that layout.

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_calc_prob
// [[Rcpp::export]]
Rcpp::List irtc_rcpp_calc_prob( Rcpp::NumericVector A, Rcpp::IntegerVector dimA,
            Rcpp::NumericVector xsi, Rcpp::IntegerVector maxcat,
            Rcpp::NumericMatrix AXsi0, Rcpp::IntegerVector iIndex,
            Rcpp::NumericMatrix theta, Rcpp::NumericVector B )
{
    const int n_items = dimA[0];
    const int n_cat   = dimA[1];
    const int n_par   = dimA[2];
    const int n_dim   = theta.ncol();
    const int n_nodes = theta.nrow();
    const int n_sel   = iIndex.size();
    const int slab    = n_items * n_cat;        // stride between slabs of A / B

    // AXsi keeps the supplied baseline for items that are not re-estimated and
    // is overwritten for the selected items below.
    Rcpp::NumericMatrix AXsi = Rcpp::clone( AXsi0 );
    Rcpp::NumericVector rprobs( n_sel * n_cat * n_nodes );

    // intercept term AXsi_{ik} = sum_p A_{ikp} xsi_p (selected items only)
    for (int s = 0; s < n_sel; s++){
        const int it = iIndex[s] - 1;
        for (int k = 0; k < maxcat[it]; k++){
            double acc = 0.0;
            for (int p = 0; p < n_par; p++){
                const double a = A[ it + k*n_items + p*slab ];
                if (a != 0.0){ acc += a * xsi[p]; }
            }
            AXsi(it, k) = acc;
        }
    }

    // stabilized softmax over the response categories at every ability node
    std::vector<double> eta( n_cat );
    for (int s = 0; s < n_sel; s++){
        const int it = iIndex[s] - 1;
        const int K  = maxcat[it];
        for (int t = 0; t < n_nodes; t++){
            double emax = R_NegInf;
            for (int k = 0; k < K; k++){
                double e = AXsi(it, k);
                for (int d = 0; d < n_dim; d++){
                    const double b = B[ it + k*n_items + d*slab ];
                    if (b != 0.0){ e += b * theta(t, d); }
                }
                eta[k] = e;
                if (e > emax){ emax = e; }
            }
            double denom = 0.0;
            for (int k = 0; k < K; k++){
                eta[k] = std::exp( eta[k] - emax );
                denom += eta[k];
            }
            for (int k = 0; k < K; k++){
                rprobs[ s + k*n_sel + t*n_sel*n_cat ] = eta[k] / denom;
            }
        }
    }

    return Rcpp::List::create( Rcpp::Named("AXsi") = AXsi,
                               Rcpp::Named("rprobs") = rprobs );
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_calc_prob_subtract_max
// Row layout of rr0M is (category-major within item): row = k*NI + i.
// For every (item, node) subtract the maximum log-odds across categories,
// ignoring NA (padding) categories and propagating NA unchanged.
// [[Rcpp::export]]
Rcpp::NumericMatrix irtc_rcpp_calc_prob_subtract_max( Rcpp::NumericMatrix rr0M,
        int NI, int NK, int TP)
{
    Rcpp::NumericMatrix out( rr0M.nrow(), TP );
    for (int i = 0; i < NI; i++){
        for (int t = 0; t < TP; t++){
            double m = R_NegInf;
            for (int k = 0; k < NK; k++){
                const double v = rr0M( k*NI + i, t );
                if ( !R_IsNA(v) && v > m ){ m = v; }
            }
            for (int k = 0; k < NK; k++){
                const int r = k*NI + i;
                const double v = rr0M( r, t );
                out( r, t ) = R_IsNA(v) ? NA_REAL : v - m;
            }
        }
    }
    return out;
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_calc_prob_subtract_max_exp
// As above but on a flat (NI x NK x TP) cube, returning exp(v - max) so the
// caller can normalize directly. NA entries stay NA.
// [[Rcpp::export]]
Rcpp::NumericVector irtc_rcpp_calc_prob_subtract_max_exp( Rcpp::NumericVector rr0,
        Rcpp::IntegerVector dim_rr )
{
    const int NI = dim_rr[0];
    const int NK = dim_rr[1];
    const int TP = dim_rr[2];
    const int slab = NI * NK;
    Rcpp::NumericVector out( slab * TP );
    for (int i = 0; i < NI; i++){
        for (int t = 0; t < TP; t++){
            double m = R_NegInf;
            for (int k = 0; k < NK; k++){
                const double v = rr0[ i + k*NI + t*slab ];
                if ( !R_IsNA(v) && v > m ){ m = v; }
            }
            for (int k = 0; k < NK; k++){
                const int idx = i + k*NI + t*slab;
                const double v = rr0[ idx ];
                out[ idx ] = R_IsNA(v) ? NA_REAL : std::exp( v - m );
            }
        }
    }
    return out;
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_irtc_mml_calc_prob_R_outer_Btheta
// Per-dimension contribution B_{ik} * theta_t to the log-odds, expanded over
// the node grid. dim_Btheta = c(nSel, maxK, nNodes); the first argument is
// unused and kept only for call-site compatibility.
// [[Rcpp::export]]
Rcpp::NumericVector irtc_rcpp_irtc_mml_calc_prob_R_outer_Btheta(
        Rcpp::NumericVector Btheta, Rcpp::NumericVector B_dd,
        Rcpp::NumericVector theta_dd, Rcpp::IntegerVector dim_Btheta )
{
    const int LI = dim_Btheta[0];
    const int maxK = dim_Btheta[1];
    const int nnodes = dim_Btheta[2];
    const int slab = LI * maxK;
    Rcpp::NumericVector out( slab * nnodes );   // zero-initialised
    for (int i = 0; i < LI; i++){
        for (int k = 0; k < maxK; k++){
            const double b = B_dd[ i + k*LI ];
            if (b != 0.0){
                for (int t = 0; t < nnodes; t++){
                    out[ i + k*LI + t*slab ] = b * theta_dd[t];
                }
            }
        }
    }
    return out;
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_irtc_mml_calc_prob_R_normalize_rprobs
// Normalize unnormalised category weights to sum to one over categories, per
// (item, node). NA (padding) categories are excluded from the sum and returned
// as NA. dim_rr = c(I, K, TP).
// [[Rcpp::export]]
Rcpp::NumericVector irtc_rcpp_irtc_mml_calc_prob_R_normalize_rprobs(
        Rcpp::NumericVector rr, Rcpp::IntegerVector dim_rr)
{
    const int I = dim_rr[0];
    const int K = dim_rr[1];
    const int TP = dim_rr[2];
    const int slab = I * K;
    Rcpp::NumericVector out( slab * TP );
    for (int i = 0; i < I; i++){
        for (int t = 0; t < TP; t++){
            double s = 0.0;
            for (int k = 0; k < K; k++){
                const double v = rr[ i + k*I + t*slab ];
                if ( !R_IsNA(v) ){ s += v; }
            }
            for (int k = 0; k < K; k++){
                const int idx = i + k*I + t*slab;
                const double v = rr[ idx ];
                out[ idx ] = R_IsNA(v) ? NA_REAL : v / s;
            }
        }
    }
    return out;
}
///********************************************************************
