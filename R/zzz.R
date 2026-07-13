# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: zzz.R

version <- function(pkg="IRTC")
{
    library_path <- dirname(system.file(package=pkg))
    description <- utils::packageDescription(pkg)
    paste(
        description$Package,
        description$Version,
        description$Date,
        library_path
    )
}

.onAttach <- function(libname, pkgname)
{
    description <- utils::packageDescription("IRTC")
    packageStartupMessage(paste0(
        "* ", description$Package, " ", description$Version,
        " (", description$Date, ")"
    ))
}

xx <- function(f1=1, f2=1)
{
    paste0(strrep(" ", f1), "=", strrep(" ", f2))
}
