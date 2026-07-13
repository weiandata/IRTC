# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_progress_em0.R

irtc_mml_progress_em0 <- function(progress, iter, disp, print_estep=TRUE)
{
    if (!progress) return(invisible(NULL))

    cat(disp)
    cat("Iteration", iter, "   ", paste(Sys.time()))
    if (print_estep) cat("\nE Step\n")
    utils::flush.console()
}
