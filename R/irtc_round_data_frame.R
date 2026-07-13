# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_round_data_frame.R

irtc_round_data_frame <- function(obji, from=1, to=ncol(obji), digits=3,
    rownames_null=FALSE)
{
    is_tabular <- is.matrix(obji) || is.data.frame(obji)
    if (is_tabular) {
        for (column in from:to) {
            obji[, column] <- round(obji[, column], digits)
        }
        if (rownames_null) {
            rownames(obji) <- NULL
        }
    }

    if (is.vector(obji)) {
        obji <- round(obji, digits)
    }

    obji
}
