# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_stud_prior_multiple_groups.R

irtc_stud_prior_multiple_groups <- function(theta, Y, beta, variance, nstud,
            nnodes, ndim, YSD, unidim_simplify, G, group_indices, snodes=0,
            normalize=FALSE )
{
    if (G == 1) {
        gwt <- irtc_stud_prior(
            theta=theta, Y=Y, beta=beta, variance=variance,
            nstud=nstud, nnodes=nnodes, ndim=ndim, YSD=YSD,
            unidim_simplify=unidim_simplify, snodes=snodes,
            normalize=normalize
        )
    }

    if (G > 1) {
        gwt <- matrix(NA, nrow=nstud, ncol=nnodes)
        for (group_index in 1:G) {
            students <- group_indices[[group_index]]
            group_variance <- matrix(
                variance[group_index, , ], nrow=ndim, ncol=ndim
            )
            group_density <- irtc_stud_prior(
                theta=theta, Y=Y[students, , drop=FALSE], beta=beta,
                variance=group_variance, nstud=length(students),
                nnodes=nnodes, ndim=ndim, YSD=YSD,
                unidim_simplify=unidim_simplify, snodes=snodes,
                normalize=normalize
            )
            gwt[students, ] <- group_density
        }
    }

    gwt
}
