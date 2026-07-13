# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_person_SD_EAP.R

irtc_mml_person_SD_EAP <- function( hwt, theta, EAP )
{
    person_count <- nrow(hwt)
    node_count <- ncol(hwt)
    squared_nodes <- matrix(
        as.vector(theta)^2,
        nrow=person_count, ncol=node_count, byrow=TRUE
    )
    sqrt(rowSums(hwt * squared_nodes) - EAP^2)
}
