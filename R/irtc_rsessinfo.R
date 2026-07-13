# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_rsessinfo.R

irtc_rsessinfo <- function()
{
    system <- Sys.info()
    session <- utils::sessionInfo()
    paste0(
        session$R.version$version.string, " ", session$R.version$system,
        " | nodename=", system["nodename"],
        " | login=", system["login"]
    )
}
