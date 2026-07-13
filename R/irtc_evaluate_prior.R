# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_evaluate_prior.R

irtc_evaluate_prior <- function(prior_list, parameter, derivatives=TRUE, h=1E-4)
{
    NP <- length(parameter)
    d0 <- d1 <- d2 <- rep(0, NP)

    if (!is.null(prior_list)) {
        is_prior <- attr(prior_list, "is_prior")
        prior_entries <- attr(prior_list, "prior_entries")
        LPE <- attr(prior_list, "length_prior_entries")

        if (LPE > 0) {
            for (pp in seq_len(LPE)) {
                entry_pp <- prior_entries[pp]
                prior_pp <- prior_list[[entry_pp]]
                density_pp <- prior_pp[[1]]
                args_pp <- prior_pp[[2]]
                parameter_pp <- parameter[pp]
                d0[entry_pp] <- irtc_prior_eval_log_density_one_parameter(
                    density_pp=density_pp, args_pp=args_pp,
                    parameter_pp=parameter_pp
                )
                if (derivatives) {
                    d1[entry_pp] <- irtc_prior_eval_log_density_one_parameter(
                        density_pp=density_pp, args_pp=args_pp,
                        parameter_pp=parameter_pp + h, deriv=1
                    )
                    d2[entry_pp] <- irtc_prior_eval_log_density_one_parameter(
                        density_pp=density_pp, args_pp=args_pp,
                        parameter_pp=parameter_pp - h, deriv=2
                    )
                }
            }
        }
    }

    list(d0=d0, d1=d1, d2=d2)
}
