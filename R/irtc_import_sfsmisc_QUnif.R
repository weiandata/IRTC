# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_import_sfsmisc_QUnif.R

irtc_import_sfsmisc_QUnif <- function(n, min=0, max=1, n.min=1, p,
    leap=409, ...)
{
    require_namespace_msg("sfsmisc")
    sfsmisc::QUnif(n=n, min=min, max=max, n.min=n.min, p=p, leap=leap, ...)
}
