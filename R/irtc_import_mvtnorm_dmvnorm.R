# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_import_mvtnorm_dmvnorm.R

irtc_import_mvtnorm_dmvnorm <- function(...)
{
    require_namespace_msg("mvtnorm")
    mvtnorm::dmvnorm(...)
}
