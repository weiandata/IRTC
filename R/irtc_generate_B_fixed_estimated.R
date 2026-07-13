# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_generate_B_fixed_estimated.R

irtc_generate_B_fixed_estimated <- function(B)
{
    dimensions <- dim(B)
    item_count <- dimensions[1]
    category_count <- dimensions[2]
    latent_dimensions <- dimensions[3]
    parameter_table <- matrix(
        0, nrow=item_count * category_count * latent_dimensions, ncol=4
    )

    row_index <- 1
    for (item in 1:item_count) {
        for (category in 1:category_count) {
            for (dimension in 1:latent_dimensions) {
                parameter_table[row_index, 1:4] <- c(
                    item, category, dimension, B[item, category, dimension]
                )
                row_index <- row_index + 1
            }
        }
    }

    parameter_table
}
