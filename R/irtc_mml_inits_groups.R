# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_inits_groups.R

irtc_mml_inits_groups <- function(group)
{
    if (is.null(group)) {
        return(list(G=1, groups=NULL, group=NULL, var.indices=NULL))
    }

    group_labels <- sort(unique(group))
    group_codes <- match(group, group_labels)
    group_count <- length(group_labels)

    if (group_count == 0L) {
        first_members <- NA_real_
    } else {
        first_members <- vapply(
            seq_len(group_count),
            function(code) which(group_codes == code)[1L],
            numeric(1L)
        )
    }

    list(
        G=group_count,
        groups=group_labels,
        group=group_codes,
        var.indices=first_members
    )
}
