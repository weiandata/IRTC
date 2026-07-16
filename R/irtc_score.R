# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_score.R
## Part of the IRTC package
## Score raw multiple-choice responses against an answer key (0/1), or map
## responses to partial-credit scores through a scoring rules table.

irtc_score <- function(resp, key=NULL, rules=NULL, na_as_wrong=FALSE)
{
    is_irtc_data <- inherits(resp, "irtc_data")
    if (is_irtc_data) {
        data_obj <- resp
        resp <- data_obj$resp
    } else if (is.matrix(resp) || is.data.frame(resp)) {
        resp <- as.data.frame(resp, stringsAsFactors=FALSE)
    } else {
        irtc_stop(code="E201",
            en="'resp' must be an irtc_data object, data frame or matrix.",
            zh="\u53c2\u6570 'resp' \u5fc5\u987b\u662f irtc_data \u5bf9\u8c61\u3001data.frame \u6216 matrix\u3002",
            fix_en="Read the data first, e.g. resp <- irtc_read(\"data.xlsx\").",
            fix_zh="\u8bf7\u5148\u8bfb\u5165\u6570\u636e\uff0c\u4f8b\u5982 resp <- irtc_read(\"data.xlsx\")\u3002",
            class="irtc_error_data_format")
    }
    if (is.null(key) && is.null(rules)) {
        irtc_stop(code="E202",
            en="Either 'key' (answer key) or 'rules' (scoring table) is required.",
            zh="\u5fc5\u987b\u63d0\u4f9b 'key'\uff08\u7b54\u6848\u952e\uff09\u6216 'rules'\uff08\u8ba1\u5206\u89c4\u5219\u8868\uff09\u4e4b\u4e00\u3002",
            fix_en=paste0("Example: irtc_score(resp, key=c(Q1=\"A\", ",
                "Q2=\"C\", ...))."),
            fix_zh=paste0("\u793a\u4f8b\uff1airtc_score(resp, key=c(Q1=\"A\", ",
                "Q2=\"C\", ...))\u3002"),
            class="irtc_error_scoring")
    }

    if (!is.null(rules)) {
        scored <- irtc_score_rules(resp, rules)
    } else {
        scored <- irtc_score_key(resp, key, na_as_wrong=na_as_wrong)
    }

    if (is_irtc_data) {
        data_obj$resp <- scored$resp
        data_obj$log <- rbind(data_obj$log, scored$log)
        return(data_obj)
    }
    out <- scored$resp
    attr(out, "scoring_log") <- scored$log
    out
}

## Normalise a raw response value: trim, upper-case, convert full-width
## characters (e.g. \uff21 -> A, \uff11 -> 1) to half-width.
irtc_score_normalize <- function(x)
{
    x <- trimws(as.character(x))
    fw <- c("\uff21\uff22\uff23\uff24\uff25\uff26\uff27\uff28",
        "\uff41\uff42\uff43\uff44\uff45\uff46\uff47\uff48",
        "\uff10\uff11\uff12\uff13\uff14\uff15\uff16\uff17\uff18\uff19")
    hw <- c("ABCDEFGH", "abcdefgh", "0123456789")
    x <- chartr(paste(fw, collapse=""), paste(hw, collapse=""), x)
    toupper(x)
}

irtc_score_key <- function(resp, key, na_as_wrong=FALSE)
{
    log <- irtc_log_new()
    key <- unlist(key)
    if (is.null(names(key)) || !any(nzchar(names(key)))) {
        if (length(key) != ncol(resp)) {
            irtc_stop(code="E203",
                en=paste0("Unnamed 'key' has length ", length(key),
                    " but the data has ", ncol(resp), " item columns."),
                zh=paste0("\u672a\u547d\u540d\u7684 'key' \u957f\u5ea6\u4e3a ", length(key),
                    "\uff0c\u4f46\u6570\u636e\u6709 ", ncol(resp), " \u4e2a\u9898\u76ee\u5217\u3002"),
                fix_en=paste0("Use a named key, e.g. c(Q1=\"A\", Q2=\"B\"),",
                    " or match the key length to the item columns."),
                fix_zh=paste0("\u8bf7\u4f7f\u7528\u5e26\u9898\u540d\u7684 key\uff08\u5982 c(Q1=\"A\", ",
                    "Q2=\"B\")\uff09\uff0c\u6216\u8ba9 key \u957f\u5ea6\u4e0e\u9898\u76ee\u5217\u6570\u4e00\u81f4\u3002"),
                class="irtc_error_scoring",
                data=list(key_length=length(key), n_items=ncol(resp)))
        }
        names(key) <- colnames(resp)
    }
    unknown <- setdiff(names(key), colnames(resp))
    if (length(unknown) > 0L) {
        irtc_stop(code="E204",
            en=paste0("Key item(s) not found in the data: ",
                paste(unknown, collapse=", "), "."),
            zh=paste0("\u7b54\u6848\u952e\u4e2d\u7684\u9898\u76ee\u5728\u6570\u636e\u4e2d\u4e0d\u5b58\u5728\uff1a",
                paste(unknown, collapse="\u3001"), "\u3002"),
            fix_en="Check colnames() of your data against names(key).",
            fix_zh="\u8bf7\u6838\u5bf9\u6570\u636e\u5217\u540d colnames() \u4e0e names(key) \u662f\u5426\u4e00\u81f4\u3002",
            class="irtc_error_scoring", data=list(items=unknown))
    }
    ## as.character() inside the normaliser drops names; restore them
    key_norm <- irtc_score_normalize(key)
    names(key_norm) <- names(key)
    for (item in names(key)) {
        col <- irtc_score_normalize(resp[[item]])
        col[col %in% c("NA", "")] <- NA_character_
        scored <- ifelse(is.na(col), NA_real_,
            as.numeric(col == key_norm[[item]]))
        if (na_as_wrong) scored[is.na(scored)] <- 0
        resp[[item]] <- scored
    }
    log <- irtc_log_add(log, "score", "I200",
        en=paste0("Scored ", length(key), " item(s) against the answer key",
            if (na_as_wrong) " (missing responses counted as wrong)" else "",
            "."),
        zh=paste0("\u5df2\u6309\u7b54\u6848\u952e\u5bf9 ", length(key), " \u4e2a\u9898\u76ee\u8ba1\u5206",
            if (na_as_wrong) "\uff08\u7f3a\u5931\u4f5c\u7b54\u6309 0 \u5206\u8ba1\uff09" else "", "\u3002"))
    list(resp=resp, log=log)
}

irtc_score_rules <- function(resp, rules)
{
    log <- irtc_log_new()
    rules <- as.data.frame(rules, stringsAsFactors=FALSE)
    needed <- c("item", "response", "score")
    if (!all(needed %in% colnames(rules))) {
        irtc_stop(code="E205",
            en=paste0("'rules' must have columns: item, response, score."),
            zh="\u8ba1\u5206\u89c4\u5219\u8868 'rules' \u5fc5\u987b\u5305\u542b item\u3001response\u3001score \u4e09\u5217\u3002",
            fix_en=paste0("Example: data.frame(item=\"Q1\", ",
                "response=c(\"A\",\"B\"), score=c(2,1))."),
            fix_zh=paste0("\u793a\u4f8b\uff1adata.frame(item=\"Q1\", ",
                "response=c(\"A\",\"B\"), score=c(2,1))\u3002"),
            class="irtc_error_scoring")
    }
    rules$score <- suppressWarnings(as.numeric(rules$score))
    if (anyNA(rules$score)) {
        irtc_stop(code="E206",
            en="Column 'score' in 'rules' contains non-numeric values.",
            zh="\u8ba1\u5206\u89c4\u5219\u8868\u7684 score \u5217\u5305\u542b\u975e\u6570\u503c\u3002",
            fix_en="All scores must be numbers (e.g. 0, 1, 2).",
            fix_zh="score \u5217\u5fc5\u987b\u5168\u90e8\u4e3a\u6570\u5b57\uff08\u5982 0\u30011\u30012\uff09\u3002",
            class="irtc_error_scoring")
    }
    unknown <- setdiff(unique(rules$item), colnames(resp))
    if (length(unknown) > 0L) {
        irtc_stop(code="E204",
            en=paste0("Rule item(s) not found in the data: ",
                paste(unknown, collapse=", "), "."),
            zh=paste0("\u8ba1\u5206\u89c4\u5219\u8868\u4e2d\u7684\u9898\u76ee\u5728\u6570\u636e\u4e2d\u4e0d\u5b58\u5728\uff1a",
                paste(unknown, collapse="\u3001"), "\u3002"),
            fix_en="Check colnames() of your data against rules$item.",
            fix_zh="\u8bf7\u6838\u5bf9\u6570\u636e\u5217\u540d colnames() \u4e0e rules$item \u662f\u5426\u4e00\u81f4\u3002",
            class="irtc_error_scoring", data=list(items=unknown))
    }
    unmatched <- character(0)
    for (item in unique(rules$item)) {
        sub <- rules[rules$item == item, , drop=FALSE]
        map_from <- irtc_score_normalize(sub$response)
        col <- irtc_score_normalize(resp[[item]])
        col[col %in% c("NA", "")] <- NA_character_
        idx <- match(col, map_from)
        miss <- !is.na(col) & is.na(idx)
        if (any(miss)) {
            unmatched <- c(unmatched, paste0(item, ": ",
                paste(sort(unique(col[miss])), collapse="/")))
        }
        resp[[item]] <- sub$score[idx]
    }
    if (length(unmatched) > 0L) {
        irtc_warn(code="W207",
            en=paste0("Some observed responses had no scoring rule and were",
                " set to NA - ", paste(unmatched, collapse="; "), "."),
            zh=paste0("\u90e8\u5206\u4f5c\u7b54\u6ca1\u6709\u5bf9\u5e94\u7684\u8ba1\u5206\u89c4\u5219\uff0c\u5df2\u8bb0\u4e3a NA \u2014\u2014 ",
                paste(unmatched, collapse="\uff1b"), "\u3002"),
            fix_en="Add rows to 'rules' covering these responses.",
            fix_zh="\u8bf7\u5728 rules \u4e2d\u8865\u5145\u8fd9\u4e9b\u4f5c\u7b54\u7684\u8ba1\u5206\u89c4\u5219\u3002",
            class="irtc_warning_scoring", data=list(unmatched=unmatched))
    }
    log <- irtc_log_add(log, "score", "I201",
        en=paste0("Applied scoring rules to ",
            length(unique(rules$item)), " item(s)."),
        zh=paste0("\u5df2\u6309\u8ba1\u5206\u89c4\u5219\u8868\u5bf9 ", length(unique(rules$item)),
            " \u4e2a\u9898\u76ee\u8ba1\u5206\u3002"))
    list(resp=resp, log=log)
}
