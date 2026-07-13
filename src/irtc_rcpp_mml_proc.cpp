// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_mml_proc.cpp

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_mml_maxcat
// Number of response categories per item, read from the design array A
// (flattened I x maxK x .): the highest category index with a non-NA design
// entry, plus one. Items whose higher categories are all NA keep the value 0.
// [[Rcpp::export]]
Rcpp::IntegerVector irtc_rcpp_mml_maxcat( Rcpp::NumericVector A, Rcpp::IntegerVector dimA )
{
    const int I = dimA[0];
    const int K = dimA[1];
    Rcpp::IntegerVector maxcat(I);
    for (int i = 0; i < I; i++){
        int mc = 0;
        for (int k = 1; k < K; k++){
            if ( !R_IsNA( A[ i + k*I ] ) ){ mc = k + 1; }
        }
        maxcat[i] = mc;
    }
    return maxcat;
}
///********************************************************************
