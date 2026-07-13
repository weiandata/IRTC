// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

// SP5.2 dimension-factorized streaming E-step kernel.
// Per person: per-dim likelihoods L_d, a pass over the Q^D grid forming the joint
// (using the person's pattern grid weights), scattering to D marginals + second
// moments, accumulating WEIGHTED expected counts / per-group second moments / EAP.
// Memory: per-thread accumulators + per-person length-Q*D scratch.
#include <Rcpp.h>
#include <thread>
#include <vector>
#include <cmath>
#include <algorithm>
using namespace Rcpp;

struct Accum {                       // per-thread accumulators
    std::vector<double> nik;         // I*maxK*Q expected counts (weighted)
    std::vector<double> M2;          // G*D*D per-group second moments (weighted)
    std::vector<double> wsum;        // length G per-group weight sums
    std::vector<double> nodeocc;     // length TP aggregate posterior occupancy (gated)
    double dev;                      // weighted sum of -2*log(normalizer)
};

static void estep_block(int p0, int p1,
        const int* resp, int N, int I, int D, int Q, int maxK, long TP, int G,
        const int* dimj,             // length I, 0-based dimension per item
        const double* probs,         // I*maxK*Q  (item,cat,node)
        const int* gridcoord,        // TP*D, 0-based node index per grid point per dim
        const double* gw_mat,        // TP*npat, column = a pattern's grid weights
        const int* pattern,          // length N, 0-based pattern (column) per person
        const double* pw,            // length N, case weights
        const int* group,            // length N, 0-based group per person
        const double* xnode,         // length Q, node coordinates
        Accum& acc, double* eap)     // eap: N*D output (or NULL)
{
    std::vector<double> L((size_t)D * Q);
    std::vector<double> marg((size_t)D * Q);
    std::vector<double> m2p((size_t)D * D);
    std::vector<int> cc(D);
    for (int p = p0; p < p1; p++){
        const double* gw = gw_mat + (long)pattern[p] * TP;   // person's pattern weights
        const double w = pw[p];
        const int gp = group[p];
        // per-dim likelihood vectors
        for (long i = 0; i < (long)D*Q; i++) L[i] = 1.0;
        for (int j = 0; j < I; j++){
            int d = dimj[j];
            int c = resp[p + (long)j*N];
            const double* pj = probs + ((long)j*maxK + c)*Q;
            double* Ld = &L[(long)d*Q];
            for (int q = 0; q < Q; q++) Ld[q] *= pj[q];
        }
        // grid pass: joint, normalizer, marginals, person-local M2
        for (long i = 0; i < (long)D*Q; i++) marg[i] = 0.0;
        for (long i = 0; i < (long)D*D; i++) m2p[i] = 0.0;
        double norm = 0.0;
        for (long g = 0; g < TP; g++){
            for (int d = 0; d < D; d++) cc[d] = gridcoord[g + (long)d*TP];
            double jnt = gw[g];
            for (int d = 0; d < D; d++) jnt *= L[(long)d*Q + cc[d]];
            if (jnt == 0.0) continue;
            norm += jnt;
            for (int d = 0; d < D; d++) marg[(long)d*Q + cc[d]] += jnt;
            for (int d = 0; d < D; d++){
                double xd = xnode[cc[d]];
                for (int e = d; e < D; e++) m2p[d*D + e] += jnt * xd * xnode[cc[e]];
            }
        }
        if (norm <= 0.0) continue;
        double inv = 1.0 / norm;
        for (long i = 0; i < (long)D*Q; i++) marg[i] *= inv;
        double* M2g = &acc.M2[(size_t)gp*D*D];
        for (int d = 0; d < D; d++)
            for (int e = d; e < D; e++) M2g[d*D + e] += w * m2p[d*D + e] * inv;
        acc.wsum[gp] += w;
        acc.dev += -2.0 * w * std::log(norm);
        if (!acc.nodeocc.empty()){                  // gated: aggregate posterior per node
            for (long g = 0; g < TP; g++){
                for (int d = 0; d < D; d++) cc[d] = gridcoord[g + (long)d*TP];
                double jnt = gw[g];
                for (int d = 0; d < D; d++) jnt *= L[(long)d*Q + cc[d]];
                if (jnt != 0.0) acc.nodeocc[g] += w * jnt * inv;
            }
        }
        // per-person EAP = posterior mean of theta per dimension (unweighted)
        if (eap != NULL){
            for (int d = 0; d < D; d++){
                double e_d = 0.0; const double* md = &marg[(long)d*Q];
                for (int q = 0; q < Q; q++) e_d += md[q] * xnode[q];
                eap[p + (long)d*N] = e_d;
            }
        }
        // weighted expected counts
        for (int j = 0; j < I; j++){
            int d = dimj[j];
            int c = resp[p + (long)j*N];
            const double* md = &marg[(long)d*Q];
            double* nik = &acc.nik[((long)j*maxK + c)*Q];
            for (int q = 0; q < Q; q++) nik[q] += w * md[q];
        }
    }
}

// [[Rcpp::export]]
Rcpp::List irtc_rcpp_proto_estep(IntegerMatrix resp, IntegerVector dimj,
        NumericVector probs, IntegerMatrix gridcoord, NumericMatrix gw_mat,
        IntegerVector pattern, NumericVector pweights, IntegerVector group, int ngroup,
        NumericVector xnode, int Q, int maxK, int n_threads=1, int want_eap=0,
        int want_nodeocc=0)
{
    int N = resp.nrow(), I = resp.ncol(), D = gridcoord.ncol(), G = ngroup;
    long TP = gridcoord.nrow();
    int nt = n_threads < 1 ? 1 : std::min(n_threads, 2);
    if (nt > N) nt = N;
    std::vector<Accum> accs(nt);
    for (auto& a : accs){
        a.nik.assign((size_t)I*maxK*Q, 0.0);
        a.M2.assign((size_t)G*D*D, 0.0);
        a.wsum.assign((size_t)G, 0.0);
        if (want_nodeocc) a.nodeocc.assign((size_t)TP, 0.0);
        a.dev = 0.0;
    }
    NumericMatrix eap_mat(want_eap ? N : 0, want_eap ? D : 0);
    double* eap_ptr = want_eap ? eap_mat.begin() : (double*)NULL;
    const int* presp = resp.begin();
    const long block_size = 100000;
    for (long bstart = 0; bstart < N; bstart += block_size){
        long bend = std::min((long)N, bstart + block_size);
        long bn = bend - bstart;
        std::vector<std::thread> pool;
        long per = (bn + nt - 1)/nt;
        for (int t = 0; t < nt; t++){
            long p0 = bstart + (long)t*per, p1 = std::min(bend, p0 + per);
            if (p0 >= p1) break;
            pool.emplace_back(estep_block, (int)p0, (int)p1, presp, N, I, D, Q, maxK, TP, G,
                dimj.begin(), probs.begin(), gridcoord.begin(), gw_mat.begin(),
                pattern.begin(), pweights.begin(), group.begin(), xnode.begin(),
                std::ref(accs[t]), eap_ptr);
        }
        for (auto& th : pool) th.join();
        Rcpp::checkUserInterrupt();
    }

    NumericVector nik((R_xlen_t)I*maxK*Q);
    NumericVector M2((R_xlen_t)G*D*D);
    NumericVector wsum((R_xlen_t)G);
    NumericVector nodeocc(want_nodeocc ? (R_xlen_t)TP : 0);
    double dev=0;
    for (auto& a : accs){
        for (size_t i=0;i<a.nik.size();i++) nik[i]+=a.nik[i];
        for (size_t i=0;i<a.M2.size();i++) M2[i]+=a.M2[i];
        for (size_t i=0;i<a.wsum.size();i++) wsum[i]+=a.wsum[i];
        for (size_t i=0;i<a.nodeocc.size();i++) nodeocc[i]+=a.nodeocc[i];
        dev += a.dev;
    }
    return List::create(_["nik"]=nik, _["M2"]=M2, _["deviance"]=dev, _["wsum"]=wsum,
                        _["eap"]=eap_mat, _["nodeocc"]=nodeocc,
                        _["dims"]=IntegerVector::create(I,maxK,Q,D,G));
}
