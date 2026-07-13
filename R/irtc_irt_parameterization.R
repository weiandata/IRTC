# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_irt_parameterization.R

irtc_irt_parameterization <- function(resp, maxK, B, AXsi, irtmodel="2PL",
    irtc_function="irtc.mml", skillspace="normal")
{
    items <- colnames(resp)
    item_count <- length(items)
    item_irt <- NULL
    is_polytomous <- maxK > 2
    compute_parameters <- TRUE

    if (dim(B)[3] > 1) {
        compute_parameters <- FALSE
    }
    if (irtmodel == "irtc.mml.2pl") {
        if (irtc_function == "2PL") {
            compute_parameters <- FALSE
        }
    }
    if (irtmodel == "irtc.mml.3pl") {
        if (skillspace != "normal") {
            compute_parameters <- FALSE
        }
    }

    if (compute_parameters) {
        output_columns <- maxK + 1
        if (!is_polytomous) {
            output_columns <- 2
        }

        AXsi <- - AXsi
        item_irt <- matrix(NA, nrow=item_count, ncol=output_columns)
        threshold_labels <- NULL
        if (is_polytomous) {
            threshold_labels <- paste0("tau.Cat", 1:(maxK - 1))
        }
        colnames(item_irt) <- c("alpha", "beta", threshold_labels)
        item_irt <- data.frame(item=items, item_irt)

        alpha <- B[, 2, 1]
        item_irt$alpha <- alpha
        xsi_irt <- AXsi / alpha

        for (item in 1:item_count) {
            item_intercepts <- xsi_irt[item, ]
            highest_category <- sum(1 - is.na(item_intercepts)) - 1
            location <- (
                item_intercepts[highest_category + 1] / highest_category
            )
            item_irt[item, "beta"] <- location

            if (highest_category > 1) {
                for (category in 1:highest_category) {
                    item_irt[item, paste0("tau.Cat", category)] <- (
                        item_intercepts[category + 1] - location -
                        item_intercepts[category]
                    )
                }
            }
        }
    }

    item_irt
}
