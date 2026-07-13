# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_round_data_frame_print.R

irtc_round_data_frame_print <- function(obji, from=1, to=ncol(obji), digits=3,
    rownames_null=FALSE)
{
    rounded <- irtc_round_data_frame(
        obji=obji,
        from=from,
        to=to,
        digits=digits,
        rownames_null=rownames_null
    )
    print(rounded)
    invisible(rounded)
}
