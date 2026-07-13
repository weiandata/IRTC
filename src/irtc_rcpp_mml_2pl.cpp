// IRTC
// Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
// SPDX-License-Identifier: GPL-2.0-or-later
// See inst/COPYRIGHTS for licensing details.

//// File Name: irtc_rcpp_mml_2pl.cpp

#include <Rcpp.h>
#include <algorithm>
#include <thread>
#include <vector>

using namespace Rcpp;

// Per-item sufficient statistics for the 2PL/GPCM slope M-step.
// [[Rcpp::export]]
Rcpp::List irtc_rcpp_mml_2pl_mstep_item_slopes_suffstat( Rcpp::NumericVector rprobs,
        Rcpp::IntegerVector items_temp, Rcpp::NumericMatrix theta, int dd, int LIT, int TP,
        int nitems, Rcpp::IntegerVector maxcat, int maxK, Rcpp::NumericMatrix itemwt,
        Rcpp::NumericMatrix xxf_, Rcpp::NumericMatrix xbar_, Rcpp::NumericMatrix xbar2_,
        Rcpp::CharacterVector irtmodel, Rcpp::NumericMatrix xtemp_,
        Rcpp::IntegerVector items_conv, int n_threads=1)
{
    const int converged_count = items_conv.size();
    Rcpp::NumericMatrix xbar(nitems, maxK);
    Rcpp::NumericMatrix xbar2(nitems, maxK);
    Rcpp::NumericMatrix xxf(nitems, maxK);
    const int node_columns = xtemp_.ncol();
    Rcpp::NumericMatrix xtemp(xtemp_.nrow(), node_columns);

    const bool is_2pl = (irtmodel[0] == "2PL");
    const bool is_gpcm = (
        (irtmodel[0] == "GPCM") || (irtmodel[0] == "GPCM.design")
    );

    // Copy and clear using the R API before any worker threads start.
    for (int category=0; category<maxK; ++category) {
        xbar(_, category) = xbar_(_, category);
        xxf(_, category) = xxf_(_, category);
        xbar2(_, category) = xbar2_(_, category);
        for (int index=0; index<converged_count; ++index) {
            const int item = items_conv[index] - 1;
            if (item >= 0) {
                xbar(item, category) = 0;
                xxf(item, category) = 0;
                xbar2(item, category) = 0;
            }
        }
    }
    if (is_gpcm) {
        for (int node=0; node<node_columns; ++node) {
            xtemp(_, node) = xtemp_(_, node);
        }
    }

    double* xbar_data = xbar.begin();
    double* xbar2_data = xbar2.begin();
    double* xxf_data = xxf.begin();
    double* xtemp_data = xtemp.begin();
    const double* probability_data = rprobs.begin();
    const double* theta_data = theta.begin();
    const double* weight_data = itemwt.begin();
    const int* item_data = items_temp.begin();
    const int* category_count_data = maxcat.begin();
    const int theta_rows = theta.nrow();
    const int weight_rows = itemwt.nrow();
    const int xtemp_rows = xtemp.nrow();

    // Each worker owns distinct item rows and does not call the R API.
    auto accumulate = [&](int begin, int end) {
        for (int selected=begin; selected<end; ++selected) {
            const int item = item_data[selected] - 1;
            for (int category=0; category<maxK; ++category) {
                const long output_offset = item + (long)category*nitems;
                xbar_data[output_offset] = 0;
                xxf_data[output_offset] = 0;
                xbar2_data[output_offset] = 0;

                if (category < category_count_data[item]) {
                    const double category_squared = (
                        (double)category * (double)category
                    );
                    double xbar_sum = 0.0;
                    double xxf_sum = 0.0;
                    double xbar2_sum = 0.0;

                    for (int node=0; node<TP; ++node) {
                        const double probability = probability_data[
                            selected + category*LIT + (long)node*LIT*maxK
                        ];
                        const double weighted_probability = probability * weight_data[
                            node + (long)item*weight_rows
                        ];
                        const double node_value = theta_data[
                            node + (long)dd*theta_rows
                        ];
                        const double first_moment = node_value * weighted_probability;
                        xbar_sum += first_moment;
                        const double second_moment = first_moment * node_value;
                        xxf_sum += second_moment;

                        if (is_2pl) {
                            xbar2_sum += probability * second_moment;
                        }
                        if (is_gpcm) {
                            xtemp_data[item + (long)node*xtemp_rows] += (
                                node_value * probability * category
                            );
                        }
                    }

                    xbar_data[output_offset] = xbar_sum;
                    xbar2_data[output_offset] = xbar2_sum;
                    xxf_data[output_offset] = (
                        is_gpcm ? xxf_sum * category_squared : xxf_sum
                    );
                }
            }
        }
    };

    int thread_count = n_threads < 1 ? 1 : std::min(n_threads, 2);
    if (thread_count > LIT) {
        thread_count = LIT;
    }
    const long work_size = (long)LIT * maxK * TP;
    const long parallel_threshold = 2000000;
    if (thread_count <= 1 || work_size < parallel_threshold) {
        accumulate(0, LIT);
    } else {
        std::vector<std::thread> workers;
        const int items_per_thread = (LIT + thread_count - 1) / thread_count;
        for (int thread=0; thread<thread_count; ++thread) {
            const int begin = thread * items_per_thread;
            const int end = std::min(LIT, begin + items_per_thread);
            if (begin >= end) {
                break;
            }
            workers.emplace_back(accumulate, begin, end);
        }
        for (auto& worker : workers) {
            worker.join();
        }
    }

    return Rcpp::List::create(
        Rcpp::Named("xxf") = xxf,
        Rcpp::Named("xbar") = xbar,
        Rcpp::Named("xbar2") = xbar2,
        Rcpp::Named("xtemp") = xtemp
    );
}
