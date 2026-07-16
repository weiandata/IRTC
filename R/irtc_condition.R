# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_condition.R
## Part of the IRTC package
## Structured condition system: every error and warning raised by the
## usability layer carries a machine-readable code, reason and fix so that
## automated callers (including AI agents) can react programmatically.
##
## Code ranges:
##   E001-E099  general / missing optional dependency
##   E100-E199  data reading (irtc_read)
##   E200-E299  scoring (irtc_score)
##   E300-E399  data validation (irtc_check_data / irtc)
##   E400-E499  estimation wrapper (irtc)
##   E500-E599  export and reporting (irtc_excel / irtc_report / irtc_json)
##   W###       corresponding warning codes in the same ranges.

irtc_condition_message <- function(code, reason, fix)
{
    msg <- paste0("[", code, "] ", reason)
    if (length(fix) == 1L && !is.na(fix) && nzchar(fix)) {
        msg <- paste0(msg, "\n  ", irtc_tr("Fix", "\u5efa\u8bae"), ": ", fix)
    }
    msg
}

irtc_stop <- function(code, en, zh, fix_en="", fix_zh="", class=NULL,
    data=list(), lang=irtc_lang())
{
    reason <- irtc_tr(en, zh, lang)
    fix <- irtc_tr(fix_en, fix_zh, lang)
    cond <- structure(
        class=c(class, "irtc_error", "error", "condition"),
        list(message=irtc_condition_message(code, reason, fix), call=NULL,
             code=code, reason=reason, fix=fix, reason_en=en, fix_en=fix_en,
             data=data)
    )
    stop(cond)
}

irtc_warn <- function(code, en, zh, fix_en="", fix_zh="", class=NULL,
    data=list(), lang=irtc_lang())
{
    reason <- irtc_tr(en, zh, lang)
    fix <- irtc_tr(fix_en, fix_zh, lang)
    cond <- structure(
        class=c(class, "irtc_warning", "warning", "condition"),
        list(message=irtc_condition_message(code, reason, fix), call=NULL,
             code=code, reason=reason, fix=fix, reason_en=en, fix_en=fix_en,
             data=data)
    )
    warning(cond)
}

## Require an optional (Suggests) package with a friendly, actionable error.
irtc_require <- function(pkg, purpose_en, purpose_zh)
{
    if (!requireNamespace(pkg, quietly=TRUE)) {
        irtc_stop(
            code="E001",
            en=paste0("The optional package '", pkg, "' is required to ",
                purpose_en, ", but it is not installed."),
            zh=paste0("\u9700\u8981\u5b89\u88c5\u53ef\u9009\u4f9d\u8d56\u5305 '",
                pkg, "' \u624d\u80fd", purpose_zh,
                "\uff0c\u4f46\u5f53\u524d\u672a\u5b89\u88c5\u3002"),
            fix_en=paste0("Run install.packages(\"", pkg, "\") and retry."),
            fix_zh=paste0("\u8bf7\u5148\u8fd0\u884c install.packages(\"", pkg,
                "\") \u5b89\u88c5\u540e\u91cd\u8bd5\u3002"),
            class="irtc_error_missing_package",
            data=list(package=pkg)
        )
    }
    invisible(TRUE)
}
