# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_import_MASS_ginv.R

irtc_import_MASS_ginv <- function(X, ...)
{
    require_namespace_msg("MASS")
    MASS::ginv(X=X, ...)
}
