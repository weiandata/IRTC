# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_summary_print_ic.R

irtc_summary_print_ic <- function(object, digits_ic=0, digits_values=2,
    bayes_crit=FALSE)
{
    ic <- object$ic
    should_calculate <- object$calc_ic
    if (is.null(should_calculate)) should_calculate <- TRUE

    if (should_calculate) {
        supported <- c("AIC", "AIC3", "AICc", "BIC", "aBIC", "CAIC", "GHP")
        available <- intersect(names(ic), supported)
        for (criterion in available) {
            irtc_summary_print_ic_one_ic(
                ic=ic,
                crit=criterion,
                digits_ic=digits_ic,
                digits_penalty=digits_values
            )
        }
        cat("\n")

        if (bayes_crit) {
            cat("Criteria based on Fully Bayesian Inference\n")
            cat("\nDbar", "=", round(ic$Dbar, digits_values))
            cat("\nDhat", "=", round(ic$Dhat, digits_values))
            cat("\npD", "=", round(ic$pD, digits_values))
            cat(
                "\nDIC", "=", round(ic$DIC, digits_ic), " | penalty=",
                round(2 * ic$pD, digits_values)
            )
            cat("   | DIC=Dhat + 2*pD\n\n")
        }
    }
}
