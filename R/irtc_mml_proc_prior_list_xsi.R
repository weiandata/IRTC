# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_proc_prior_list_xsi.R

irtc_mml_proc_prior_list_xsi <- function(prior_list_xsi, xsi)
{
    NX <- length(xsi)
    is_prior <- !is.null(prior_list_xsi)
    if (!is_prior) {
        prior_list_xsi <- list()
    }

    prior_entries <- NULL
    if (is_prior) {
        prior_sequence <- 1:length(prior_list_xsi)
        for (parameter in prior_sequence) {
            if (!is.null(prior_list_xsi[[parameter]])) {
                prior_entries <- c(prior_entries, parameter)
                prior_list_xsi[[parameter]][[2]][["x"]] <- NA
            }
        }
    }

    attr(prior_list_xsi, "dim_parameter") <- NX
    attr(prior_list_xsi, "is_prior") <- is_prior
    attr(prior_list_xsi, "prior_entries") <- prior_entries
    attr(prior_list_xsi, "length_prior_entries") <- length(prior_entries)
    prior_list_xsi
}
