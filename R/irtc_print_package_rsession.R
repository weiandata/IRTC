# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_print_package_rsession.R

irtc_print_package_rsession <- function(pack)
{
    for (package in pack) {
        cat(irtc_packageinfo(pack=package), "\n")
    }
    cat(irtc_rsessinfo(), "\n\n")
}
