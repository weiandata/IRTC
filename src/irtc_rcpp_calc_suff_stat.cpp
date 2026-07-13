// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_calc_suff_stat.cpp

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_calc_suff_stat
// Observed sufficient statistics for the item parameters. cResp one-hot encodes
// each observed response into I*maxK category slots; the weighted category
// counts are then mapped through the design matrix cA to give the item score
// vector ItemScore = cA^T %*% (sum_n pweights_n * cResp_n).
// [[Rcpp::export]]
Rcpp::List irtc_rcpp_calc_suff_stat( Rcpp::IntegerMatrix resp,
        Rcpp::IntegerMatrix resp_ind, int maxK, int nitems,
        Rcpp::NumericVector pweights, Rcpp::NumericMatrix cA )
{
    const int N = resp.nrow();
    const int I = nitems;
    const int ncol = I * maxK;
    Rcpp::IntegerMatrix cResp(N, ncol);
    Rcpp::NumericVector wcol(ncol);             // weighted column sums of cResp

    for (int i = 0; i < I; i++){
        for (int n = 0; n < N; n++){
            if ( resp_ind(n, i) == 1 ){
                const int col = resp(n, i) + i*maxK;   // one-hot category slot
                cResp(n, col) = 1;
                wcol[col] += pweights[n];
            }
        }
    }

    const int NP = cA.ncol();
    Rcpp::NumericVector ItemScore(NP);
    for (int p = 0; p < NP; p++){
        double acc = 0.0;
        for (int h = 0; h < ncol; h++){
            const double a = cA(h, p);
            if (a != 0.0){ acc += wcol[h] * a; }
        }
        ItemScore[p] = acc;
    }

    return Rcpp::List::create( Rcpp::Named("cResp") = cResp,
                               Rcpp::Named("ItemScore") = ItemScore );
}
///********************************************************************
