# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_deviance_history_init.R

irtc_deviance_history_init <- function(maxiter)
{
    row_count <- nrow(matrix(numeric(), nrow=maxiter, ncol=0L))
    cbind(iter=seq_len(row_count), deviance=numeric(row_count))
}
