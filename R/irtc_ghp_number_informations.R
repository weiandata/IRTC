# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_ghp_number_informations.R

irtc_ghp_number_informations <- function(pweights, resp.ind)
{
    if (is.null(resp.ind)) {
        return(NULL)
    }

    sum(pweights * resp.ind)
}
