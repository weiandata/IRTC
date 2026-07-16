# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_lang.R
## Part of the IRTC package
## Language selection and bilingual string helper for user-facing output.

irtc_lang <- function()
{
    lang <- getOption("irtc.lang", "zh")
    if (!is.character(lang) || length(lang) != 1L || is.na(lang) ||
        !(lang %in% c("zh", "en"))) {
        lang <- "zh"
    }
    lang
}

irtc_tr <- function(en, zh, lang=irtc_lang())
{
    if (identical(lang, "zh")) zh else en
}
