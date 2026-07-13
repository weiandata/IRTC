# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_assign_list_elements.R

irtc_assign_list_elements <- function(x, envir)
{
    element_names <- names(x)
    values <- unname(x)

    for (position in 1:length(values)) {
        assign(element_names[position], values[[position]], envir=envir)
    }
}
