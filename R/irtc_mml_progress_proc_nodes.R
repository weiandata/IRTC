# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_progress_proc_nodes.R

irtc_mml_progress_proc_nodes <- function(progress, snodes, nnodes, maxnodes=8000,
    skillspace="normal", QMC=FALSE)
{
    if (!progress || skillspace != "normal") return(invisible(NULL))

    method <- if (snodes == 0) {
        "Numerical integration with "
    } else if (QMC) {
        "Quasi Monte Carlo integration with "
    } else {
        "Monte Carlo integration with "
    }
    cat(paste0("    * ", method, nnodes, " nodes\n"))

    if (nnodes > maxnodes) {
        cat("      @ Are you sure that you want so many nodes?\n")
        cat("      @ Maybe you want to use Quasi Monte Carlo integration with fewer nodes.\n")
    }
}
