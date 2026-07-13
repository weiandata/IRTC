# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

irtc_rmvnorm <- function(n, mean=NULL, sigma=NULL, ...)
{
    dimension <- if (is.null(sigma)) length(mean) else ncol(sigma)
    if (is.null(mean)) {
        mean <- rep(0, dimension)
    }
    if (is.null(sigma)) {
        sigma <- diag(dimension)
    }

    MASS::mvrnorm(n=n, mu=mean, Sigma=sigma)
}

irtc_require_namespace <- function(pkg)
{
    for (package in pkg) {
        if (!requireNamespace(package, quietly=TRUE)) {
            message <- paste0(
                "Package '", package, "' is needed. Please install it."
            )
            stop(message, call.=FALSE)
        }
    }

    invisible(TRUE)
}
