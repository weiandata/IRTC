# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_ic_criteria.R

irtc_mml_ic_criteria <- function(ic)
{
    deviance <- ic$deviance
    parameter_count <- ic$np

    ic$AIC <- deviance + 2 * parameter_count
    ic$AIC3 <- deviance + 3 * parameter_count
    ic$BIC <- deviance + log(ic$n) * parameter_count
    ic$aBIC <- deviance + log((ic$n - 2) / 24) * parameter_count
    ic$CAIC <- deviance + (log(ic$n) + 1) * parameter_count
    ic$AICc <- ic$AIC + (
        2 * parameter_count * (parameter_count + 1) /
        (ic$n - parameter_count - 1)
    )

    if (!is.null(ic$ghp_obs)) {
        ic$GHP <- ic$AIC / (2 * ic$ghp_obs)
    }

    ic
}
