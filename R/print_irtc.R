# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: print_irtc.R

print_irtc <- function(x, ...)
{
    cat(irtc_packageinfo("IRTC"), "\n")
    irtc_print_call(x$CALL)

    cat("Multidimensional Item Response Model in IRTC \n")
    cat("\nDeviance=", round(x$deviance, 2), " | ")
    cat("Log Likelihood=", round(-x$deviance / 2, 2), "\n")
    cat("Number of persons used=", x$ic$n, "\n")
    cat("Number of estimated parameters=", x$ic$Npars, "\n")
    cat("AIC=", round(x$ic$AIC, 0), "\n")
    cat("BIC=", round(x$ic$BIC, 0), "\n")
}

print.irtc <- print_irtc
