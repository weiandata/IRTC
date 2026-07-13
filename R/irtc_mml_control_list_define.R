# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_control_list_define.R

irtc_mml_control_list_define <- function(control, envir, irtc_fct,
        prior_list_xsi)
{
    available_cores <- tryCatch(parallel::detectCores(), error=function(e) 1L)
    if (is.na(available_cores) || available_cores < 1L) {
        available_cores <- 1L
    }

    con <- list(
        nodes=seq(-6, 6, length.out=21), snodes=0, QMC=TRUE,
        convD=1E-3, conv=1E-4, convM=1E-4,
        Msteps=4, maxiter=1000, max.increment=1, min.variance=1E-3,
        progress=TRUE, ridge=0, xsi.start0=FALSE,
        n_threads=min(as.integer(available_cores), 2L),
        fast=FALSE, fast_threshold=1E-6, increment.factor=1,
        fac.oldxsi=0, acceleration="none", dev_crit="absolute",
        trim_increment="half"
    )

    if (irtc_fct %in% "irtc.mml") {
        con$mstep_intercept_method <- if (is.null(prior_list_xsi)) "R" else "optim"
    }

    con[names(control)] <- control
    con$n_threads <- suppressWarnings(as.integer(con$n_threads)[1L])
    if (is.na(con$n_threads) || con$n_threads < 1L) {
        con$n_threads <- 1L
    }
    con$n_threads <- min(con$n_threads, 2L)
    con$fac.oldxsi <- max(0, min(c(con$fac.oldxsi, .95)))

    if (con$progress == "F") {
        con$progress <- FALSE
    }
    if (con$progress == "T") {
        con$progress <- TRUE
    }

    irtc_assign_list_elements(con, envir=envir)
    list(con=con, con1a=con)
}
