# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_audit.R
## Part of the IRTC package
## Retrospective check of a saved analysis against the answer-key defect
## fixed in 1.1.2: up to and including 1.1.1, irtc_read() renumbered an item's
## categories to consecutive scores starting at 0 and irtc_score() then matched
## the answer key against the renumbered values, so a key written in the data
## file's own coding selected the wrong option. Nothing warned, and the
## resulting 0/1 matrix looks entirely plausible.
##
## The risk condition is narrow and mechanically checkable: an item was scored
## against a key or rules table AND its categories were renumbered. Both facts
## are recorded in the cleaning log that every irtc() fit carries, so an
## analysis can be triaged without re-running it.

irtc_audit_version_fixed <- "1.1.2"

irtc_audit_scoring <- function(x)
{
    parts <- irtc_audit_extract(x)
    scored <- parts$scored
    recoded <- parts$recoded
    version <- parts$version

    affected <- intersect(scored, recoded)
    if (length(scored) == 0L) {
        status <- "not_scored"
    } else if (!is.na(version) && isTRUE(tryCatch(
        utils::compareVersion(version, irtc_audit_version_fixed) >= 0,
        error=function(e) FALSE))) {
        status <- "ok_fixed"
    } else if (length(affected) > 0L) {
        ## without a version stamp the object could predate the fix or not;
        ## say so rather than accusing a sound analysis
        status <- if (is.na(version)) "affected_if_before_1.1.2" else "affected"
    } else {
        status <- "not_affected"
    }

    ## the field names what needs re-running, so it is empty unless the
    ## verdict is actually a risk one; the per-item detail stays in `items`
    if (!status %in% c("affected", "affected_if_before_1.1.2")) {
        affected <- character(0)
    }

    items <- data.frame(
        item=scored,
        categories_renumbered=scored %in% recoded,
        stringsAsFactors=FALSE, row.names=NULL
    )
    if (nrow(items) > 0L) {
        items$original_categories <- vapply(items$item, function(it) {
            cats <- parts$categories[[it]]
            if (is.null(cats)) NA_character_ else paste(cats, collapse=",")
        }, character(1L))
    }

    out <- list(status=status, affected_items=affected, items=items,
        package_version=version, n_scored=length(scored),
        n_recoded=length(recoded))
    class(out) <- "irtc_audit"
    out
}

## Pull the scored items, the renumbered items and the recording version out of
## whatever the caller has kept: a fitted model, the irtc_data object, or the
## irtc_results() list (which carries the cleaning log).
irtc_audit_extract <- function(x)
{
    log <- NULL
    scored <- character(0)
    version <- NA_character_
    categories <- list()

    if (inherits(x, "irtc")) {
        log <- x$usability$data_log
        scored <- x$usability$score_info$scored_items
        version <- x$usability$package_version
        categories <- x$usability$recode_map
    } else if (inherits(x, "irtc_data")) {
        log <- x$log
        scored <- x$score_info$scored_items
        version <- x$package_version
        categories <- x$recode_map
    } else if (inherits(x, "irtc_results")) {
        log <- x$cleaning_log
        version <- x$model_info$package_version
    } else if (is.data.frame(x) &&
        all(c("code", "step") %in% colnames(x))) {
        log <- x                                   # a bare cleaning log
    } else {
        irtc_stop(code="E411",
            en=paste0("'x' must be a fitted irtc model, an irtc_data object, ",
                "an irtc_results list, or a cleaning log data frame."),
            zh=paste0("\u53c2\u6570 'x' \u5fc5\u987b\u662f\u5df2\u4f30\u8ba1\u7684 irtc \u6a21\u578b\u3001irtc_data ",
                "\u5bf9\u8c61\u3001irtc_results \u7ed3\u679c\uff0c\u6216\u6e05\u6d17\u65e5\u5fd7 data.frame\u3002"),
            fix_en=paste0("Load the saved model, e.g. ",
                "irtc_audit_scoring(readRDS(\"model.rds\"))."),
            fix_zh=paste0("\u8bf7\u8f7d\u5165\u4fdd\u5b58\u7684\u6a21\u578b\uff0c\u4f8b\u5982 ",
                "irtc_audit_scoring(readRDS(\"model.rds\"))\u3002"),
            class="irtc_error_input")
    }

    ## items whose categories were renumbered, read back from the log; the
    ## item name is single-quoted in both language versions of the I124 entry
    recoded <- character(0)
    if (!is.null(log) && nrow(log) > 0L) {
        i124 <- log[log$code == "I124", , drop=FALSE]
        if (nrow(i124) > 0L) {
            msg <- if ("message_en" %in% colnames(i124)) i124$message_en else
                i124[[ncol(i124)]]
            recoded <- sub("^[^']*'([^']*)'.*$", "\\1", msg)
            recoded <- recoded[nzchar(recoded) & recoded != msg]
        }
        ## an object recorded before scoring existed still logs I200
        if (length(scored) == 0L && any(log$code == "I200")) {
            scored <- recoded
        }
    }
    if (is.null(scored)) scored <- character(0)
    if (is.null(categories)) categories <- list()
    ## a fit from before 1.1.2 carries no version stamp at all
    version <- if (length(version) != 1L) NA_character_ else
        as.character(version)
    list(scored=scored, recoded=recoded, version=version,
        categories=categories)
}

print.irtc_audit <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("IRTC scoring audit (answer key vs category renumbering)",
        "IRTC \u8ba1\u5206\u6838\u67e5\uff08\u7b54\u6848\u952e\u4e0e\u7c7b\u522b\u91cd\u7f16\u7801\uff09", lang),
        "\n", sep="")
    ver <- if (is.na(x$package_version)) irtc_tr("not recorded", "\u672a\u8bb0\u5f55", lang)
        else x$package_version
    cat("  ", irtc_tr("Produced by IRTC", "\u4ea7\u51fa\u7248\u672c", lang), ": ", ver,
        "\n", sep="")
    cat("  ", irtc_tr("Items scored by key/rules", "\u6309\u7b54\u6848\u952e\u6216\u89c4\u5219\u8ba1\u5206\u7684\u9898\u76ee"),
        ": ", x$n_scored, "\n", sep="")

    if (x$status == "ok_fixed") {
        cat(irtc_tr(
            "\n  OK. Produced by IRTC 1.1.2 or later, where the answer key is\n  applied in the coding of the data file itself.\n",
            "\n  \u7ed3\u8bba\uff1a\u65e0\u95ee\u9898\u3002\u7531 IRTC 1.1.2 \u53ca\u4ee5\u540e\u7684\u7248\u672c\u4ea7\u51fa\uff0c\n  \u7b54\u6848\u952e\u6309\u6570\u636e\u6587\u4ef6\u81ea\u8eab\u7684\u7f16\u7801\u5e94\u7528\u3002\n",
            lang))
    } else if (x$status == "not_scored") {
        cat(irtc_tr(
            "\n  OK. No answer key or scoring rules were used, so the defect\n  cannot apply: the responses were already scored.\n",
            "\n  \u7ed3\u8bba\uff1a\u4e0d\u53d7\u5f71\u54cd\u3002\u672a\u4f7f\u7528\u7b54\u6848\u952e\u6216\u8ba1\u5206\u89c4\u5219\uff0c\n  \u4f5c\u7b54\u6570\u636e\u672c\u5df2\u8ba1\u5206\uff0c\u8be5\u7f3a\u9677\u65e0\u4ece\u53d1\u751f\u3002\n",
            lang))
    } else if (x$status == "not_affected") {
        cat(irtc_tr(
            "\n  OK. A key was used, but no scored item had its categories\n  renumbered, so the key applied to the intended options.\n",
            "\n  \u7ed3\u8bba\uff1a\u4e0d\u53d7\u5f71\u54cd\u3002\u867d\u4f7f\u7528\u4e86\u7b54\u6848\u952e\uff0c\u4f46\u53c2\u4e0e\u8ba1\u5206\u7684\u9898\u76ee\n  \u90fd\u672a\u53d1\u751f\u7c7b\u522b\u91cd\u7f16\u7801\uff0c\u7b54\u6848\u952e\u4f5c\u7528\u5728\u4e86\u6b63\u786e\u7684\u9009\u9879\u4e0a\u3002\n",
            lang))
    } else {
        if (x$status == "affected") {
            cat(irtc_tr(
                "\n  AFFECTED. These items were scored against a key while their\n  categories had been renumbered, so the key selected the wrong\n  option. Re-run the analysis with IRTC 1.1.2 or later.\n",
                "\n  \u7ed3\u8bba\uff1a\u53d7\u5f71\u54cd\u3002\u4ee5\u4e0b\u9898\u76ee\u5728\u7c7b\u522b\u88ab\u91cd\u7f16\u7801\u540e\u53c8\u6309\u7b54\u6848\u952e\u8ba1\u5206\uff0c\n  \u7b54\u6848\u952e\u5b9e\u9645\u4f5c\u7528\u5728\u4e86\u9519\u8bef\u7684\u9009\u9879\u4e0a\u3002\u8bf7\u7528 IRTC 1.1.2 \u53ca\u4ee5\u540e\n  \u7684\u7248\u672c\u91cd\u8dd1\u8be5\u5206\u6790\u3002\n",
                lang))
        } else {
            cat(irtc_tr(
                "\n  AT RISK. These items were scored against a key while their\n  categories had been renumbered. The recording version is not\n  known: if this analysis was run with IRTC 1.1.1 or earlier the\n  key selected the wrong option and it must be re-run; from 1.1.2\n  on it is correct.\n",
                "\n  \u7ed3\u8bba\uff1a\u5b58\u5728\u98ce\u9669\u3002\u4ee5\u4e0b\u9898\u76ee\u5728\u7c7b\u522b\u88ab\u91cd\u7f16\u7801\u540e\u53c8\u6309\u7b54\u6848\u952e\u8ba1\u5206\uff0c\n  \u4f46\u65e0\u6cd5\u786e\u8ba4\u4ea7\u51fa\u7248\u672c\uff1a\u82e5\u8be5\u5206\u6790\u7531 IRTC 1.1.1 \u53ca\u4ee5\u524d\u7684\n  \u7248\u672c\u8dd1\u51fa\uff0c\u5219\u7b54\u6848\u952e\u4f5c\u7528\u5728\u4e86\u9519\u8bef\u9009\u9879\u4e0a\uff0c\u5fc5\u987b\u91cd\u8dd1\uff1b\n  1.1.2 \u53ca\u4ee5\u540e\u7684\u7248\u672c\u5219\u65e0\u95ee\u9898\u3002\n",
                lang))
        }
        aff <- x$items[x$items$categories_renumbered, , drop=FALSE]
        print(aff, row.names=FALSE)
    }
    invisible(x)
}
