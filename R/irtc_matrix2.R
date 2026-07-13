# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_matrix2.R

irtc_matrix2 <- function(x, nrow=NULL, ncol=NULL)
{
    column_count <- if (is.null(ncol)) length(x) else ncol
    row_count <- if (is.null(nrow)) 1 else nrow

    matrix(x, nrow=row_count, ncol=column_count, byrow=TRUE)
}
