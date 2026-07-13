// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

// E-step posterior kernel: for each (person, node), multiply the response
// probabilities across items. Parallelized over node columns (disjoint
// memory => race-free and bit-identical regardless of thread count).
// Workers touch only raw arrays; all R API use is on the main thread.

#include <Rcpp.h>
#include <thread>
#include <vector>
#include <algorithm>

// Accumulate the product into res[ , l] for node columns [l0, l1).
static void irtc_calcfx_block(double* res, const double* rii, const int* resp,
        int nresp, int nnodes, int nitems, int ncats,
        const std::vector<const int*>& ni, const std::vector<int>& nlen,
        int l0, int l1)
{
    const long stride = (long)nitems * ncats;
    for (int i = 0; i < nitems; i++){
        const int* nii = ni[i];
        const int len = nlen[i];
        for (int k = 0; k < len; k++){
            const int p = nii[k] - 1;                 // 0-based person index
            const int cat = resp[p + (long)i*nresp];  // response category
            const long ridx0 = i + (long)cat*nitems;  // node-independent part
            for (int l = l0; l < l1; l++){
                res[p + (long)l*nresp] *= rii[ridx0 + (long)l*stride];
            }
        }
    }
}

// [[Rcpp::export]]
SEXP irtc_calcfx(SEXP sFx, SEXP sRprobs, SEXP sRespIndList, SEXP sResp,
                 int n_threads = 1)
{
    SEXP dim = Rf_getAttrib(sRprobs, R_DimSymbol);
    int nitems = INTEGER(dim)[0];
    int ncats  = INTEGER(dim)[1];
    int nnodes = INTEGER(dim)[2];
    int nresp  = INTEGER(Rf_getAttrib(sResp, R_DimSymbol))[0];

    SEXP sResult = PROTECT(Rf_allocVector(REALSXP, (R_xlen_t)nresp * nnodes));
    double* res        = REAL(sResult);
    const double* fxin = REAL(sFx);
    const double* rii  = REAL(sRprobs);
    const int* resp    = INTEGER(sResp);

    for (R_xlen_t j = 0; j < (R_xlen_t)nresp * nnodes; j++) res[j] = fxin[j];

    // Extract resp.ind.list pointers on the MAIN thread (no R API in workers).
    std::vector<const int*> ni(nitems);
    std::vector<int> nlen(nitems);
    for (int i = 0; i < nitems; i++){
        SEXP el = VECTOR_ELT(sRespIndList, i);
        ni[i]   = INTEGER(el);
        nlen[i] = LENGTH(el);
    }

    int nt = n_threads < 1 ? 1 : std::min(n_threads, 2);
    if (nt > nnodes) nt = nnodes;
    const long work = (long)nresp * nnodes;
    const long THRESHOLD = 2000000;  // small problems stay single-threaded
    if (nt <= 1 || work < THRESHOLD){
        irtc_calcfx_block(res, rii, resp, nresp, nnodes, nitems, ncats, ni, nlen,
                          0, nnodes);
    } else {
        std::vector<std::thread> pool;
        const int per = (nnodes + nt - 1) / nt;
        for (int t = 0; t < nt; t++){
            int l0 = t * per, l1 = std::min(nnodes, l0 + per);
            if (l0 >= l1) break;
            pool.emplace_back(irtc_calcfx_block, res, rii, resp, nresp, nnodes,
                              nitems, ncats, std::cref(ni), std::cref(nlen), l0, l1);
        }
        for (auto& th : pool) th.join();
    }

    SEXP dims = PROTECT(Rf_allocVector(INTSXP, 2));
    INTEGER(dims)[0] = nresp; INTEGER(dims)[1] = nnodes;
    Rf_setAttrib(sResult, R_DimSymbol, dims);
    UNPROTECT(2);
    return sResult;
}
