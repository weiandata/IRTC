# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_itempartable.R
irtc_itempartable <- function( resp, maxK, AXsi, B, ndim,
            resp.ind, rprobs=NULL, n.ik=NULL, pi.k=NULL, order=FALSE,
            pweights=rep(1,nrow(resp) ) )
{
    if (is.null(dimnames(B)[[1]])) {
        dimnames(B)[[1]] <- colnames(resp)
    }

    item_table <- data.frame("item"=dimnames(B)[[1]])
    response_weight <- resp.ind * pweights
    item_table$N <- colSums(response_weight)
    item_table$M <- (
        colSums(resp.ind * resp * pweights, na.rm=TRUE) /
        colSums(resp.ind*pweights)
    )

    highest_category <- rowSums(1 - is.na(AXsi)) - 1
    item_count <- nrow(item_table)
    item_table$xsi.item <- -AXsi[
        cbind(1:item_count, highest_category + 1)
    ] / highest_category

    b0 <- sum(B[, 1, ], na.rm=TRUE)
    a0 <- 0
    if (b0 + a0 > 0) {
        category_indices <- 0:(maxK - 1)
    } else {
        category_indices <- 1:(maxK - 1)
    }

    for (category in category_indices) {
        item_table[, paste0("AXsi_.Cat", category)] <- (
            -AXsi[, category + 1]
        )
    }
    for (category in category_indices) {
        for (dimension in 1:ndim) {
            item_table[, paste0("B.Cat", category, ".Dim", dimension)] <- (
                B[, category + 1, dimension]
            )
        }
    }

    item_table <- item_table[item_table$N > 0, ]
    rownames(item_table) <- paste(item_table$item)
    if (order) {
        item_table <- item_table[order(paste(item_table$item)), ]
    }

    item_table[item_table == -99] <- NA
    item_table
}

.IRTC.itempartable <- irtc_itempartable
