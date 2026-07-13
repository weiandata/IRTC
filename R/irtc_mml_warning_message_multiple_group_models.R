# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_warning_message_multiple_group_models.R

irtc_mml_warning_message_multiple_group_models <- function(ndim, G, disable=FALSE)
{
    unsupported <- !disable && ndim > 1 && G > 1
    if (unsupported) {
        stop(paste0(
            "Multiple group estimation is not (yet) supported for \n",
            "  multidimensional models. Use 'irtc.mml.3pl' instead."
        ))
    }
}
