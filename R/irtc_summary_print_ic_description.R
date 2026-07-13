# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_summary_print_ic_description.R

irtc_summary_print_ic_description <- function(crit)
{
    descriptions <- c(
        AIC="AIC=-2*LL + 2*p",
        AIC3="AIC3=-2*LL + 3*p",
        AICc="AICc=-2*LL + 2*p + 2*p*(p+1)/(n-p-1)  (bias corrected AIC)",
        BIC="BIC=-2*LL + log(n)*p",
        aBIC="aBIC=-2*LL + log((n-2)/24)*p  (adjusted BIC)",
        CAIC="CAIC=-2*LL + [log(n)+1]*p  (consistent AIC)",
        GHP="GHP=( -LL + p ) / (#Persons * #Items)  (Gilula-Haberman log penalty)"
    )
    description <- unname(descriptions[crit])
    if (length(description) == 0 || is.na(description)) NULL else description
}
