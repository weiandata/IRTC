// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_calc_exp.cpp

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_calc_exp
// Expected sufficient statistics that feed the Newton update of the item
// intercept parameters xsi. For each estimated parameter p and every item i in
// its parameter group, at ability node t define
//   lin_{it}  = sum_c A_{icp}   P(X_i = c | theta_t)     (expected design score)
//   quad_{it} = sum_c A_{icp}^2 P(X_i = c | theta_t)
// weighted by the expected item-node count ITEMWT(t, i). The accumulated
//   xbar[p]  = sum_{t,i} lin  * w          (gradient term)
//   xbar2[p] = sum_{t,i} lin^2 * w         (first part of the information)
//   xxf[p]   = sum_{t,i} quad * w          (second part of the information)
// A and rprobs are flat (nItems x nCat x .) arrays.
// [[Rcpp::export]]
Rcpp::List irtc_rcpp_calc_exp( int NP, Rcpp::NumericVector rprobs,
    Rcpp::NumericVector A, Rcpp::NumericMatrix INDEXIPNO,
    Rcpp::NumericVector INDEXIPLIST2, Rcpp::NumericVector ESTXSIINDEX,
    int C, Rcpp::NumericMatrix ITEMWT, int NR, int TP)
{
    Rcpp::NumericVector xbar(NP);
    Rcpp::NumericVector xbar2(NP);
    Rcpp::NumericVector xxf(NP);

    const int n_items = NR / C;
    const int slab = n_items * C;              // stride for a parameter/node slab
    const int n_est = ESTXSIINDEX.size();

    for (int e = 0; e < n_est; e++){
        const int p  = ESTXSIINDEX[e] - 1;
        const int g0 = INDEXIPNO(p, 0) - 1;    // first item-group entry (0-based)
        const int g1 = INDEXIPNO(p, 1) - 1;    // last item-group entry (inclusive)
        double s_bar = 0.0, s_bar2 = 0.0, s_xxf = 0.0;

        for (int t = 0; t < TP; t++){
            for (int g = g0; g <= g1; g++){
                const int i = INDEXIPLIST2[g] - 1;
                double lin = 0.0, quad = 0.0;
                for (int c = 0; c < C; c++){
                    const double a  = A[ i + c*n_items + p*slab ];
                    const double ap = a * rprobs[ i + c*n_items + t*slab ];
                    lin  += ap;
                    quad += a * ap;
                }
                const double w = ITEMWT(t, i);
                s_bar  += lin * w;
                s_bar2 += lin * lin * w;
                s_xxf  += quad * w;
            }
        }
        xbar[p]  = s_bar;
        xbar2[p] = s_bar2;
        xxf[p]   = s_xxf;
    }

    return Rcpp::List::create( Rcpp::Named("xbar")  = xbar,
                               Rcpp::Named("xbar2") = xbar2,
                               Rcpp::Named("xxf")   = xxf );
}
///********************************************************************

///********************************************************************
///** irtc_rcpp_calc_exp_redefine_vector_na
// Replace NA entries of a vector with a fixed value; pass others through.
// [[Rcpp::export]]
Rcpp::NumericVector irtc_rcpp_calc_exp_redefine_vector_na( Rcpp::NumericVector A,
         double val )
{
    const int N = A.size();
    Rcpp::NumericVector out(N);
    for (int n = 0; n < N; n++){
        out[n] = R_IsNA( A[n] ) ? val : A[n];
    }
    return out;
}
///********************************************************************
