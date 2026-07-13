# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_dtnorm.R

irtc_dtnorm <- function(x, mean=0, sd=1, lower=-Inf, upper=Inf, log=FALSE)
{
    density <- numeric(length(x))
    outside <- x < lower | x > upper
    density[outside] <- if (log) -Inf else 0
    density[upper < lower] <- NaN

    inside <- x >= lower & x <= upper
    if (any(inside)) {
        probability <- stats::pnorm(q=upper, mean=mean, sd=sd) -
            stats::pnorm(q=lower, mean=mean, sd=sd)
        unscaled <- stats::dnorm(x=x, mean=mean, sd=sd, log=log)
        scaled <- if (log) unscaled - base::log(probability) else
            unscaled / probability

        density[x >= lower & x <= upper] <- scaled[inside]
    }

    density
}
