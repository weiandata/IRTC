# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_person_EAP_rel.R

irtc_mml_person_EAP_rel <- function(EAP, SD.EAP, pweights=NULL)
{
    if (is.null(pweights)) {
        pweights <- rep(1, length(EAP))
    }

    score_variance <- (
        weighted_mean(EAP^2, pweights) - weighted_mean(EAP, pweights)^2
    )
    posterior_error <- weighted_mean(SD.EAP^2, pweights)
    score_variance / (score_variance + posterior_error)
}
