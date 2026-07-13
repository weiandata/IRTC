# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_print_call.R

irtc_print_call <- function(CALL)
{
    call_text <- paste0(CALL, collapse=" ")
    if (nchar(call_text) < 3000) {
        rendered <- paste(deparse(CALL), collapse="\n")
        cat("\nCall:\n", rendered, "\n\n", sep="")
    }
}
