# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_calc_prob_helper_subtract_max.R

# Subtract, per (item, node), the maximum log-odds across response categories.
# Reshapes the (I x K x TP) cube to an (I*K) x TP matrix for the C++ kernel and
# reshapes the result back.
irtc_calc_prob_helper_subtract_max <- function( rr0 )
{
    d <- dim(rr0)
    flat <- matrix( rr0, nrow = d[1] * d[2], ncol = d[3] )
    shifted <- irtc_rcpp_calc_prob_subtract_max( rr0M=flat, NI=d[1], NK=d[2], TP=d[3] )
    array( shifted, dim = d )
}
