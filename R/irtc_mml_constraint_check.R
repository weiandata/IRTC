# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_constraint_check.R

irtc_mml_constraint_check <- function(constraint)
{
    if (constraint == "item") {
        constraint <- "items"
    }
    if (constraint == "case") {
        constraint <- "cases"
    }

    allowed <- c("items", "cases")
    if (!(constraint %in% allowed)) {
        choices <- paste(allowed, collapse="' or '")
        stop(paste0("Please choose one of the constraints: '", choices, "'\n"))
    }

    constraint
}
