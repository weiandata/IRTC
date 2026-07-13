// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_rowcumsums.cpp

#include <Rcpp.h>

using namespace Rcpp;

///********************************************************************
///** irtc_rcpp_rowCumsums
// Left-to-right cumulative sum along each row: output(i, j) = sum_{c<=j} input(i, c).
// [[Rcpp::export]]
Rcpp::NumericMatrix irtc_rcpp_rowCumsums( Rcpp::NumericMatrix input )
{
    const int nr = input.nrow();
    const int nc = input.ncol();
    Rcpp::NumericMatrix output( nr, nc );
    for (int i = 0; i < nr; i++){
        double running = 0.0;
        for (int j = 0; j < nc; j++){
            running += input(i, j);
            output(i, j) = running;
        }
    }
    return output;
}
///********************************************************************
