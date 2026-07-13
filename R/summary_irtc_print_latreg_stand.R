# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: summary_irtc_print_latreg_stand.R

summary_irtc_print_latreg_stand <- function(object, digits_stand=4)
{
    standardized <- object$latreg_stand
    if (is.null(standardized)) return(invisible(NULL))

    cat("------------------------------------------------------------\n")
    cat("Standardized Coefficients\n")
    irtc_round_data_frame_print(
        obji=standardized$beta_stand, digits=digits_stand, from=3
    )
    cat("\n** Explained Variance R^2\n")
    irtc_round_data_frame_print(
        obji=standardized$R2_theta, digits=digits_stand
    )
    cat("** SD Theta\n")
    irtc_round_data_frame_print(
        obji=standardized$sd_theta, digits=digits_stand
    )
    cat("** SD Predictors\n")
    irtc_round_data_frame_print(obji=standardized$sd_x, digits=digits_stand)
}
