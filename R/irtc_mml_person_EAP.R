# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_person_EAP.R

irtc_mml_person_EAP <- function( hwt, theta )
{
    person_count <- nrow(hwt)
    node_count <- ncol(hwt)
    node_values <- matrix(
        as.vector(theta), nrow=person_count, ncol=node_count, byrow=TRUE
    )
    rowSums(hwt * node_values)
}
