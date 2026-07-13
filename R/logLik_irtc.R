# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: logLik_irtc.R

logLik_irtc <- function(object, ...)
{
    likelihood <- -object$ic$deviance / 2
    structure(
        likelihood,
        df=object$ic$Npars,
        nobs=object$ic$n,
        class="logLik"
    )
}

logLik.irtc <- logLik_irtc
