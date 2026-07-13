# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_create_nodes_multidim_nodes.R

irtc_mml_create_nodes_multidim_nodes <- function(nodes, ndim)
{
    if (ndim == 1) {
        return(matrix(nodes, ncol=1))
    }

    if (ndim > 1 && is.matrix(nodes)) {
        return(nodes)
    }

    if (ndim == 0) {
        return(matrix(logical(), nrow=0, ncol=0,
                      dimnames=list(NULL, NULL)))
    }

    axis <- as.vector(matrix(nodes, ncol=1))
    dimensions <- rep(list(axis), ndim)
    names(dimensions) <- paste0("V", seq_along(dimensions))

    as.matrix(do.call(expand.grid, dimensions))
}
