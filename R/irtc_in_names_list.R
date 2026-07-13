# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_in_names_list.R

irtc_in_names_list <- function(list, variable)
{
    available_names <- names(list)
    if (is.null(available_names)) {
        return(FALSE)
    }

    variable %in% available_names
}
