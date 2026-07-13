# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_proc_unidim_simplify.R

irtc_mml_proc_unidim_simplify <- function(Y, A, G, beta.fixed)
{
    eps <- 1E-15
    YSD <- max(apply(Y, 2, stats::sd))
    if (YSD > eps) {
        YSD <- TRUE
    } else {
        YSD <- FALSE
    }

    Avector <- as.vector(A)
    Avector[is.na(Avector)] <- 0

    unidim_simplify <- TRUE
    if (G > 1) {
        unidim_simplify <- FALSE
    }
    if (YSD) {
        unidim_simplify <- FALSE
    }
    if (is.null(beta.fixed)) {
        unidim_simplify <- FALSE
    }

    list(unidim_simplify=unidim_simplify, YSD=YSD, Avector=Avector)
}
