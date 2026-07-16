# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_check_data.R
## Part of the IRTC package
## Pre-estimation diagnostics. Returns a machine-readable issue table plus a
## human-readable print method, so that survey staff and AI agents can both
## verify a data set before fitting a model.

irtc_check_data <- function(x, key=NULL, verbose=TRUE)
{
    if (inherits(x, "irtc_data")) {
        resp <- x$resp
        pid <- x$pid
    } else if (is.matrix(x) || is.data.frame(x)) {
        resp <- as.data.frame(x, stringsAsFactors=FALSE)
        pid <- NULL
    } else {
        irtc_stop(code="E301",
            en="'x' must be an irtc_data object, data frame or matrix.",
            zh="\u53c2\u6570 'x' \u5fc5\u987b\u662f irtc_data \u5bf9\u8c61\u3001data.frame \u6216 matrix\u3002",
            fix_en="Read the data first with irtc_read().",
            fix_zh="\u8bf7\u5148\u7528 irtc_read() \u8bfb\u5165\u6570\u636e\u3002",
            class="irtc_error_data_format")
    }

    issues <- irtc_issue_new()
    n_persons <- nrow(resp)
    n_items <- ncol(resp)

    ## structural checks -----------------------------------------------------
    if (n_items < 2L) {
        issues <- irtc_issue_add(issues, "E302", "error", "data", "",
            en="Fewer than 2 item columns; an IRT model cannot be estimated.",
            zh="\u9898\u76ee\u5217\u5c11\u4e8e 2 \u4e2a\uff0c\u65e0\u6cd5\u4f30\u8ba1 IRT \u6a21\u578b\u3002",
            fix_en="Check that item columns were not dropped during import.",
            fix_zh="\u8bf7\u68c0\u67e5\u6570\u636e\u5bfc\u5165\u65f6\u9898\u76ee\u5217\u662f\u5426\u88ab\u8bef\u5220\u3002")
    }
    if (n_persons < 2L) {
        issues <- irtc_issue_add(issues, "E303", "error", "data", "",
            en="Fewer than 2 persons; estimation is impossible.",
            zh="\u6837\u672c\u91cf\u5c11\u4e8e 2 \u4eba\uff0c\u65e0\u6cd5\u4f30\u8ba1\u3002",
            fix_en="Provide the full response data set.",
            fix_zh="\u8bf7\u63d0\u4f9b\u5b8c\u6574\u7684\u4f5c\u7b54\u6570\u636e\u3002")
    } else if (n_persons < 30L) {
        issues <- irtc_issue_add(issues, "W304", "warning", "data", "",
            en=paste0("Only ", n_persons, " persons; parameter estimates",
                " will be unstable (>= 100 recommended)."),
            zh=paste0("\u6837\u672c\u91cf\u4ec5 ", n_persons,
                " \u4eba\uff0c\u53c2\u6570\u4f30\u8ba1\u4f1a\u5f88\u4e0d\u7a33\u5b9a\uff08\u5efa\u8bae\u81f3\u5c11 100 \u4eba\uff09\u3002"),
            fix_en="Interpret results with caution or collect more data.",
            fix_zh="\u8bf7\u8c28\u614e\u89e3\u8bfb\u7ed3\u679c\uff0c\u6216\u6269\u5927\u6837\u672c\u91cf\u3002")
    }

    ## column type checks ----------------------------------------------------
    char_cols <- names(resp)[!vapply(resp, is.numeric, logical(1L))]
    if (length(char_cols) > 0L) {
        if (is.null(key)) {
            issues <- irtc_issue_add(issues, "E305", "error", "item",
                paste(char_cols, collapse=","),
                en=paste0("Non-numeric item column(s): ",
                    paste(char_cols, collapse=", "),
                    ". These look like raw responses (e.g. A/B/C/D)."),
                zh=paste0("\u5b58\u5728\u975e\u6570\u503c\u9898\u76ee\u5217\uff1a",
                    paste(char_cols, collapse="\u3001"),
                    "\u3002\u8fd9\u4e9b\u770b\u8d77\u6765\u662f\u539f\u59cb\u4f5c\u7b54\uff08\u5982 A/B/C/D\uff09\u3002"),
                fix_en=paste0("Score them first: irtc_score(data, ",
                    "key=...), or pass key= to irtc()."),
                fix_zh=paste0("\u8bf7\u5148\u8ba1\u5206\uff1airtc_score(data, key=...)\uff0c",
                    "\u6216\u5728 irtc() \u4e2d\u63d0\u4f9b key= \u53c2\u6570\u3002"))
        } else {
            issues <- irtc_issue_add(issues, "I306", "info", "item",
                paste(char_cols, collapse=","),
                en=paste0(length(char_cols), " raw response column(s) will",
                    " be scored with the supplied answer key."),
                zh=paste0(length(char_cols),
                    " \u4e2a\u539f\u59cb\u4f5c\u7b54\u5217\u5c06\u4f7f\u7528\u63d0\u4f9b\u7684\u7b54\u6848\u952e\u8ba1\u5206\u3002"),
                fix_en="", fix_zh="")
        }
    }

    num_cols <- names(resp)[vapply(resp, is.numeric, logical(1L))]
    for (item in num_cols) {
        vals <- resp[[item]][!is.na(resp[[item]])]
        if (length(vals) == 0L) {
            issues <- irtc_issue_add(issues, "W307", "warning", "item", item,
                en=paste0("Item '", item, "' has no observed responses."),
                zh=paste0("\u9898\u76ee '", item, "' \u6ca1\u6709\u4efb\u4f55\u6709\u6548\u4f5c\u7b54\u3002"),
                fix_en="This item will be removed before estimation.",
                fix_zh="\u4f30\u8ba1\u524d\u4f1a\u81ea\u52a8\u5254\u9664\u8be5\u9898\u3002")
            next
        }
        if (any(vals < 0)) {
            issues <- irtc_issue_add(issues, "E308", "error", "item", item,
                en=paste0("Item '", item, "' contains negative values."),
                zh=paste0("\u9898\u76ee '", item, "' \u542b\u6709\u8d1f\u6570\u53d6\u503c\u3002"),
                fix_en=paste0("Recode missing codes such as -9 to NA, e.g.",
                    " via irtc_read(..., missing_codes=c(-9))."),
                fix_zh=paste0("\u8bf7\u5c06 -9 \u7b49\u7f3a\u5931\u7801\u8f6c\u6362\u4e3a NA\uff0c\u4f8b\u5982\u4f7f\u7528 ",
                    "irtc_read(..., missing_codes=c(-9))\u3002"))
        }
        if (any(vals != round(vals))) {
            issues <- irtc_issue_add(issues, "E309", "error", "item", item,
                en=paste0("Item '", item, "' contains non-integer values;",
                    " responses must be integer categories (0, 1, 2, ...)."),
                zh=paste0("\u9898\u76ee '", item, "' \u542b\u6709\u975e\u6574\u6570\u53d6\u503c\uff1b\u4f5c\u7b54\u5fc5\u987b\u662f",
                    "\u6574\u6570\u7c7b\u522b\uff080\u30011\u30012\u2026\u2026\uff09\u3002"),
                fix_en="Check the scoring of this item.",
                fix_zh="\u8bf7\u68c0\u67e5\u8be5\u9898\u7684\u8ba1\u5206\u65b9\u5f0f\u3002")
        }
        if (length(unique(vals)) == 1L) {
            issues <- irtc_issue_add(issues, "W310", "warning", "item", item,
                en=paste0("Item '", item, "' has zero variance (all",
                    " responses equal ", unique(vals), ")."),
                zh=paste0("\u9898\u76ee '", item, "' \u6ca1\u6709\u533a\u5206\u5ea6\uff08\u6240\u6709\u4f5c\u7b54\u90fd\u662f ",
                    unique(vals), "\uff09\u3002"),
                fix_en=paste0("The item carries no information and will be",
                    " removed before estimation."),
                fix_zh="\u8be5\u9898\u4e0d\u542b\u4efb\u4f55\u4fe1\u606f\uff0c\u4f30\u8ba1\u524d\u4f1a\u81ea\u52a8\u5254\u9664\u3002")
        }
        miss_rate <- mean(is.na(resp[[item]]))
        if (miss_rate > 0.9) {
            issues <- irtc_issue_add(issues, "W311", "warning", "item", item,
                en=paste0("Item '", item, "' is ",
                    round(100 * miss_rate), "% missing."),
                zh=paste0("\u9898\u76ee '", item, "' \u7f3a\u5931\u7387\u8fbe ",
                    round(100 * miss_rate), "%\u3002"),
                fix_en="Check whether this item was actually administered.",
                fix_zh="\u8bf7\u786e\u8ba4\u8be5\u9898\u662f\u5426\u786e\u5b9e\u65bd\u6d4b\u8fc7\u3002")
        }
        if (length(vals) > 0L && length(unique(vals)) > 1L) {
            tab <- table(vals)
            sparse <- names(tab)[tab < 5L]
            if (length(sparse) > 0L && length(tab) > 2L) {
                issues <- irtc_issue_add(issues, "I312", "info", "item", item,
                    en=paste0("Item '", item, "' has sparse categories (",
                        paste(sparse, collapse=","),
                        " observed fewer than 5 times)."),
                    zh=paste0("\u9898\u76ee '", item, "' \u5b58\u5728\u7a00\u758f\u7c7b\u522b\uff08\u53d6\u503c ",
                        paste(sparse, collapse="\u3001"),
                        " \u51fa\u73b0\u4e0d\u8db3 5 \u6b21\uff09\u3002"),
                    fix_en="Consider collapsing adjacent categories.",
                    fix_zh="\u53ef\u8003\u8651\u5408\u5e76\u76f8\u90bb\u7c7b\u522b\u3002")
            }
        }
    }

    ## person checks ---------------------------------------------------------
    if (length(num_cols) > 0L && n_persons > 0L) {
        resp_num <- resp[, num_cols, drop=FALSE]
        all_na_person <- rowSums(!is.na(resp_num)) == 0L
        if (any(all_na_person)) {
            issues <- irtc_issue_add(issues, "W313", "warning", "person",
                paste(which(all_na_person), collapse=","),
                en=paste0(sum(all_na_person), " person(s) answered no items",
                    " at all."),
                zh=paste0(sum(all_na_person),
                    " \u4e2a\u6837\u672c\u6ca1\u6709\u4f5c\u7b54\u4efb\u4f55\u9898\u76ee\u3002"),
                fix_en="These persons receive no ability estimate.",
                fix_zh="\u8fd9\u4e9b\u6837\u672c\u5c06\u6ca1\u6709\u80fd\u529b\u4f30\u8ba1\u503c\u3002")
        }
    }
    if (!is.null(pid) && anyDuplicated(pid) > 0L) {
        issues <- irtc_issue_add(issues, "W314", "warning", "person", "",
            en=paste0("The person ID contains ", sum(duplicated(pid)),
                " duplicated value(s)."),
            zh=paste0("\u4e2a\u6848 ID \u4e2d\u6709 ", sum(duplicated(pid)),
                " \u4e2a\u91cd\u590d\u503c\u3002"),
            fix_en="Check for duplicated records before merging results.",
            fix_zh="\u5408\u5e76\u7ed3\u679c\u524d\u8bf7\u6838\u67e5\u662f\u5426\u5b58\u5728\u91cd\u590d\u8bb0\u5f55\u3002")
    }

    out <- list(
        ok=!any(issues$severity == "error"),
        n_persons=n_persons,
        n_items=n_items,
        n_errors=sum(issues$severity == "error"),
        n_warnings=sum(issues$severity == "warning"),
        issues=issues
    )
    class(out) <- "irtc_check"
    if (verbose) print(out)
    invisible(out)
}

irtc_issue_new <- function()
{
    data.frame(code=character(0), severity=character(0), scope=character(0),
        where=character(0), message_en=character(0), message_zh=character(0),
        fix_en=character(0), fix_zh=character(0), stringsAsFactors=FALSE)
}

irtc_issue_add <- function(issues, code, severity, scope, where, en, zh,
    fix_en="", fix_zh="")
{
    rbind(issues, data.frame(code=code, severity=severity, scope=scope,
        where=where, message_en=en, message_zh=zh, fix_en=fix_en,
        fix_zh=fix_zh, stringsAsFactors=FALSE))
}

print.irtc_check <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("IRTC data check", "IRTC \u6570\u636e\u9884\u68c0", lang), "\n", sep="")
    cat("  ", irtc_tr("Persons", "\u6837\u672c\u6570", lang), ": ", x$n_persons,
        "  ", irtc_tr("Items", "\u9898\u76ee\u6570", lang), ": ", x$n_items, "\n",
        sep="")
    status <- if (x$ok) {
        irtc_tr("PASS - the data can be estimated",
            "\u901a\u8fc7 \u2014\u2014 \u6570\u636e\u53ef\u4ee5\u8fdb\u884c\u4f30\u8ba1", lang)
    } else {
        irtc_tr("FAIL - fix the errors below first",
            "\u672a\u901a\u8fc7 \u2014\u2014 \u8bf7\u5148\u89e3\u51b3\u4e0b\u5217\u9519\u8bef", lang)
    }
    cat("  ", irtc_tr("Result", "\u7ed3\u8bba", lang), ": ", status, "\n", sep="")
    if (nrow(x$issues) == 0L) {
        cat("  ", irtc_tr("No issues found.", "\u672a\u53d1\u73b0\u4efb\u4f55\u95ee\u9898\u3002", lang),
            "\n", sep="")
        return(invisible(x))
    }
    sev_label <- c(error=irtc_tr("ERROR", "\u9519\u8bef", lang),
        warning=irtc_tr("WARNING", "\u8b66\u544a", lang),
        info=irtc_tr("NOTE", "\u63d0\u793a", lang))
    for (i in seq_len(nrow(x$issues))) {
        row <- x$issues[i, ]
        msg <- if (identical(lang, "zh")) row$message_zh else row$message_en
        fix <- if (identical(lang, "zh")) row$fix_zh else row$fix_en
        cat("  [", row$code, " ", sev_label[[row$severity]], "] ", msg, "\n",
            sep="")
        if (nzchar(fix)) {
            cat("      ", irtc_tr("Fix", "\u5efa\u8bae", lang), ": ", fix, "\n",
                sep="")
        }
    }
    invisible(x)
}
