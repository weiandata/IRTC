# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_parameter_change.R

irtc_parameter_change <- function(xsi, oldxsi)
{
    difference <- as.vector(xsi) - as.vector(oldxsi)
    max(abs(difference))
}
