# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_rowMaxs.R

irtc_rowMaxs <- function(mat, na.rm=FALSE)
{
    row_count <- nrow(mat)
    column_count <- ncol(mat)

    if (column_count == 0) {
        return(matrix(mat[FALSE], nrow=0, ncol=row_count))
    }
    if (row_count == 0) {
        stop("argument lengths differ")
    }
    if (length(na.rm) == 1 && is.logical(na.rm) && is.na(na.rm)) {
        ordered_observed <- mat[FALSE]
        for (row in seq_len(row_count)) {
            ordered_observed <- c(
                ordered_observed,
                sort(mat[row, ], na.last=NA)
            )
        }
        recycled_rows <- matrix(
            ordered_observed,
            nrow=column_count,
            ncol=row_count
        )
        return(recycled_rows[column_count, ])
    }

    unlist(
        lapply(seq_len(row_count), function(row) {
            values <- mat[row, ]
            missing <- is.na(values)
            if (any(missing)) {
                if (!na.rm) {
                    return(values[utils::tail(which(missing), 1)])
                }
                values <- values[!missing]
                if (length(values) == 0) {
                    return(mat[row, column_count])
                }
            }
            values[which.max(values)]
        }),
        use.names=FALSE
    )
}

rowMaxs <- irtc_rowMaxs
