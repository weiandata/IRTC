# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_proc_xsi_parameter_index_A.R

irtc_mml_proc_xsi_parameter_index_A <- function(A, np)
{
    indexIP <- colSums(aperm(A, c(2, 1, 3)) != 0, na.rm=TRUE)

    parameter_sequence <- 1:np
    indexIP.list <- list(parameter_sequence)
    for (parameter in parameter_sequence) {
        indexIP.list[[parameter]] <- which(indexIP[, parameter] > 0)
    }

    lipl <- cumsum(lengths(indexIP.list))
    indexIP.list2 <- unlist(indexIP.list)
    first_positions <- c(1, lipl[-length(lipl)] + 1)
    indexIP.no <- as.matrix(cbind(first_positions, lipl))
    colnames(indexIP.no) <- c("", "lipl")

    list(
        indexIP=indexIP, indexIP.list=indexIP.list,
        indexIP.list2=indexIP.list2, indexIP.no=indexIP.no
    )
}
