# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_trim_increment.R

irtc_trim_increment <- function(increment, max.increment, trim_increment="cut",
    trim_incr_factor=2, eps=1E-10, avoid_na=FALSE)
{
    limit <- abs(max.increment)
    magnitude <- abs(increment)

    if (trim_increment == "half") {
        divisions <- ceiling(magnitude / (limit + eps))
        increment <- ifelse(
            magnitude > limit,
            increment / (trim_incr_factor * divisions),
            increment
        )
    }
    if (trim_increment == "cut") {
        increment <- ifelse(
            magnitude > limit,
            sign(increment) * max.increment,
            increment
        )
    }
    if (avoid_na) {
        increment <- ifelse(is.na(increment), 0, increment)
    }

    increment
}
