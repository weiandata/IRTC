# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_args_replace_value.R

irtc_args_replace_value <- function(args, variable=NULL, value=NULL)
{
    if (is.null(variable)) {
        return(args)
    }

    args[[variable]] <- value
    args
}
