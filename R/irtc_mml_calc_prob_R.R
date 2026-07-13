# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_calc_prob_R.R

# Pure-R fallback for the E-step response probabilities (see the C++ kernel
# irtc_rcpp_calc_prob for the math). Builds the log-odds cube
#   eta[i, k, t] = AXsi_{ik} + sum_d B_{ikd} theta_{td}
# for the selected items, then turns it into a normalized category-probability
# cube with a numerically stable softmax. Returns the probability cube and the
# (possibly refreshed) AXsi intercept matrix.
irtc_mml_calc_prob_R <- function(iIndex, A, AXsi, B, xsi, theta,
            nnodes, maxK, recalc=TRUE, avoid_outer=FALSE )
{
    n_dim <- ncol(theta)
    n_sel <- length(iIndex)

    #--- intercept term AXsi_{ik} = sum_p A_{ikp} xsi_p (constant across nodes)
    if (recalc){
        n_par <- dim(A)[3]
        axsi_sel <- matrix(0, nrow=n_sel, ncol=maxK)
        for (k in seq_len(maxK)){
            axsi_sel[, k] <- matrix(A[iIndex, k, ], nrow=n_sel, ncol=n_par) %*% xsi
        }
        AXsi[iIndex, ] <- axsi_sel
    } else {
        axsi_sel <- matrix(AXsi[iIndex, ], nrow=n_sel, ncol=maxK)
    }
    # broadcast the intercept over the node grid (column-major recycling)
    eta <- array(axsi_sel, dim=c(n_sel, maxK, nnodes))

    #--- slope term sum_d B_{ikd} theta_{td}, accumulated dimension by dimension
    dim_eta <- c(n_sel, maxK, nnodes)
    for (d in seq_len(n_dim)){
        B_d <- B[iIndex, , d, drop=FALSE]
        if (avoid_outer){
            add <- irtc_rcpp_irtc_mml_calc_prob_R_outer_Btheta( Btheta=eta,
                        B_dd=B_d, theta_dd=theta[, d], dim_Btheta=dim_eta )
        } else {
            add <- B_d %o% theta[, d]
        }
        eta <- eta + array(add, dim=dim_eta)
    }

    #--- stabilized softmax over categories (max-subtraction + normalize in C++)
    weights <- irtc_rcpp_calc_prob_subtract_max_exp( rr0=eta, dim_rr=dim_eta )
    rprobs <- irtc_rcpp_irtc_mml_calc_prob_R_normalize_rprobs( rr=weights,
                    dim_rr=dim_eta )
    rprobs <- array(rprobs, dim=dim_eta)

    list("rprobs"=rprobs, "AXsi"=AXsi)
}
