# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_qmatrix.R
## Part of the IRTC package
## Q-matrix import from files or R objects, with validation, an optional
## partial-credit declaration column, and alignment against the observed
## response data. The dimension column headers become the dimension names
## used in all downstream person-level output.

## --------------------------------------------------------------------------
## Column-name pools
## --------------------------------------------------------------------------

irtc_q_item_name_pool <- function()
{
    c("item", "items", "item_id", "itemid", "question", "question_id",
      "\u9898\u76ee", "\u9898\u53f7", "\u9898\u76ee\u7f16\u53f7",
      "\u9898\u540d", "\u9898\u7801", "\u8bd5\u9898")
}

irtc_q_partial_name_pool <- function()
{
    c("partial", "partial_credit", "partialcredit", "polytomous",
      "max_score", "maxscore", "full_score", "fullscore",
      "\u5206\u90e8\u8ba1\u5206", "\u90e8\u5206\u8ba1\u5206", "\u591a\u7ea7\u8ba1\u5206",
      "\u5206\u7ea7\u8ba1\u5206", "\u6ee1\u5206", "\u6700\u9ad8\u5206")
}

## --------------------------------------------------------------------------
## Reader
## --------------------------------------------------------------------------

irtc_read_q <- function(x, sheet=1)
{
    log <- irtc_log_new()

    ## --- 1. obtain a raw data frame --------------------------------------
    if (is.character(x)) {
        if (length(x) != 1L || is.na(x) || !file.exists(x)) {
            irtc_stop(code="E103",
                en=paste0("Q-matrix file not found: '", x[1L], "'."),
                zh=paste0("\u627e\u4e0d\u5230 Q \u77e9\u9635\u6587\u4ef6\uff1a'",
                    x[1L], "'\u3002"),
                fix_en="Check the path and the working directory (getwd()).",
                fix_zh=paste0("\u8bf7\u68c0\u67e5\u6587\u4ef6\u8def\u5f84\u548c\u5f53\u524d\u5de5\u4f5c\u76ee\u5f55",
                    "\uff08getwd()\uff09\u3002"),
                class="irtc_error_data_format", data=list(path=x))
        }
        raw <- irtc_read_file(x, sheet=sheet, na_strings=c("", "NA"))
        source_label <- x
    } else if (is.matrix(x)) {
        ## a numeric matrix with rownames is already a Q matrix
        if (is.numeric(x) && !is.null(rownames(x))) {
            return(irtc_q_finish(Q=x, partial=NULL, max_score=NULL,
                log=log, source="<matrix>"))
        }
        raw <- as.data.frame(x, stringsAsFactors=FALSE)
        source_label <- "<matrix>"
    } else if (is.data.frame(x)) {
        raw <- as.data.frame(x, stringsAsFactors=FALSE)
        source_label <- "<data.frame>"
    } else {
        irtc_stop(code="E110",
            en=paste0("Unsupported Q-matrix input of class '",
                class(x)[1L], "'."),
            zh=paste0("\u4e0d\u652f\u6301\u7684 Q \u77e9\u9635\u8f93\u5165\u7c7b\u578b\uff1a'",
                class(x)[1L], "'\u3002"),
            fix_en=paste0("Supply a file path (.xlsx, .csv, .sav, ...), a ",
                "data.frame, or a numeric matrix with item rownames."),
            fix_zh=paste0("\u8bf7\u63d0\u4f9b\u6587\u4ef6\u8def\u5f84\uff08.xlsx\u3001.csv\u3001.sav \u7b49\uff09\u3001",
                "data.frame\uff0c\u6216\u5e26\u9898\u76ee\u884c\u540d\u7684\u6570\u503c\u77e9\u9635\u3002"),
            class="irtc_error_data_format")
    }
    if (nrow(raw) == 0L || ncol(raw) == 0L) {
        irtc_stop(code="E110",
            en="The Q matrix is empty (no rows or no columns).",
            zh="Q \u77e9\u9635\u4e3a\u7a7a\uff08\u6ca1\u6709\u884c\u6216\u6ca1\u6709\u5217\uff09\u3002",
            fix_en="Check that the file or object actually contains data.",
            fix_zh="\u8bf7\u68c0\u67e5\u6587\u4ef6\u6216\u5bf9\u8c61\u4e2d\u662f\u5426\u786e\u5b9e\u5305\u542b\u6570\u636e\u3002",
            class="irtc_error_data_format")
    }
    for (j in seq_along(raw)) {
        if (is.factor(raw[[j]])) raw[[j]] <- as.character(raw[[j]])
        if (is.character(raw[[j]])) raw[[j]] <- trimws(raw[[j]])
    }

    ## --- 2. identify the item-ID column ----------------------------------
    lc <- tolower(trimws(colnames(raw)))
    id_hit <- which(lc %in% irtc_q_item_name_pool())
    if (length(id_hit) == 0L) {
        ## fall back: the first non-numeric-like column
        is_num <- vapply(raw, function(col) {
            v <- suppressWarnings(as.numeric(col))
            all(is.na(col) | !is.na(v))
        }, logical(1L))
        id_hit <- which(!is_num)
    }
    if (length(id_hit) == 0L) {
        irtc_stop(code="E111",
            en=paste0("No item-ID column found in the Q matrix. Name it ",
                "'item' (or use the first text column for item names)."),
            zh=paste0("Q \u77e9\u9635\u4e2d\u627e\u4e0d\u5230\u9898\u76ee ID \u5217\u3002\u8bf7\u5c06\u5176\u547d\u540d\u4e3a",
                " 'item' \u6216 '\u9898\u76ee'\uff08\u6216\u5c06\u7b2c\u4e00\u5217\u8bbe\u4e3a\u9898\u76ee\u540d\u6587\u672c\u5217\uff09\u3002"),
            fix_en="Add a column with the item names used in the data.",
            fix_zh=paste0("\u8bf7\u6dfb\u52a0\u4e00\u5217\uff0c\u5185\u5bb9\u4e3a\u4e0e\u4f5c\u7b54\u6570\u636e\u4e00\u81f4\u7684",
                "\u9898\u76ee\u540d\u3002"),
            class="irtc_error_data_format")
    }
    id_col <- id_hit[1L]
    items <- as.character(raw[[id_col]])
    if (anyNA(items) || any(!nzchar(items))) {
        irtc_stop(code="E111",
            en="The Q-matrix item-ID column contains empty values.",
            zh="Q \u77e9\u9635\u7684\u9898\u76ee ID \u5217\u5305\u542b\u7a7a\u503c\u3002",
            fix_en="Every row needs an item name.",
            fix_zh="\u6bcf\u4e00\u884c\u90fd\u5fc5\u987b\u6709\u9898\u76ee\u540d\u3002",
            class="irtc_error_data_format")
    }
    if (anyDuplicated(items) > 0L) {
        dup <- unique(items[duplicated(items)])
        irtc_stop(code="E112",
            en=paste0("Duplicated item ID(s) in the Q matrix: ",
                paste(dup, collapse=", "), "."),
            zh=paste0("Q \u77e9\u9635\u4e2d\u7684\u9898\u76ee ID \u91cd\u590d\uff1a",
                paste(dup, collapse="\u3001"), "\u3002"),
            fix_en="Each item may appear only once.",
            fix_zh="\u6bcf\u9053\u9898\u53ea\u80fd\u51fa\u73b0\u4e00\u6b21\u3002",
            class="irtc_error_data_format", data=list(items=dup))
    }
    rest <- raw[, -id_col, drop=FALSE]

    ## --- 3. identify the optional partial-credit column ------------------
    partial <- NULL
    max_score <- NULL
    lc_rest <- tolower(trimws(colnames(rest)))
    p_hit <- which(lc_rest %in% irtc_q_partial_name_pool())
    if (length(p_hit) > 0L) {
        p_col <- p_hit[1L]
        p_name <- colnames(rest)[p_col]
        parsed <- irtc_q_parse_partial(rest[[p_col]], column=p_name)
        partial <- parsed$partial
        max_score <- parsed$max_score
        names(partial) <- items
        names(max_score) <- items
        rest <- rest[, -p_col, drop=FALSE]
        log <- irtc_log_add(log, "qmatrix", "I132",
            en=paste0("Column '", p_name, "' declares ", sum(partial),
                " partial-credit item(s)."),
            zh=paste0("\u5217 '", p_name, "' \u58f0\u660e\u4e86 ", sum(partial),
                " \u9053\u5206\u90e8\u8ba1\u5206\u9898\u3002"))
    }

    ## --- 4. remaining columns are the dimensions --------------------------
    if (ncol(rest) == 0L) {
        irtc_stop(code="E113",
            en="The Q matrix has no dimension columns.",
            zh="Q \u77e9\u9635\u4e2d\u6ca1\u6709\u7ef4\u5ea6\u5217\u3002",
            fix_en=paste0("Add at least one numeric column; its header is ",
                "the dimension name (e.g. 'algebra')."),
            fix_zh=paste0("\u8bf7\u81f3\u5c11\u6dfb\u52a0\u4e00\u5217\u6570\u503c\u5217\uff0c\u5217\u540d\u5373\u7ef4\u5ea6\u540d",
                "\uff08\u5982 '\u4ee3\u6570'\uff09\u3002"),
            class="irtc_error_data_format")
    }
    bad_cols <- character(0)
    for (j in seq_along(rest)) {
        col <- rest[[j]]
        v <- suppressWarnings(as.numeric(col))
        if (any(!is.na(col) & is.na(v) & nzchar(as.character(col)))) {
            bad_cols <- c(bad_cols, colnames(rest)[j])
        } else {
            rest[[j]] <- v
        }
    }
    if (length(bad_cols) > 0L) {
        irtc_stop(code="E113",
            en=paste0("Non-numeric dimension column(s) in the Q matrix: ",
                paste(bad_cols, collapse=", "), "."),
            zh=paste0("Q \u77e9\u9635\u4e2d\u5b58\u5728\u975e\u6570\u503c\u7684\u7ef4\u5ea6\u5217\uff1a",
                paste(bad_cols, collapse="\u3001"), "\u3002"),
            fix_en=paste0("Dimension columns must contain numbers (usually ",
                "0/1). Remove note columns before reading."),
            fix_zh=paste0("\u7ef4\u5ea6\u5217\u5fc5\u987b\u4e3a\u6570\u503c\uff08\u901a\u5e38\u4e3a 0/1\uff09\u3002",
                "\u8bf7\u5148\u5220\u9664\u5907\u6ce8\u7b49\u6587\u672c\u5217\u3002"),
            class="irtc_error_data_format", data=list(columns=bad_cols))
    }
    Q <- as.matrix(rest)
    if (anyNA(Q)) {
        n_na <- sum(is.na(Q))
        Q[is.na(Q)] <- 0
        log <- irtc_log_add(log, "qmatrix", "I131",
            en=paste0("Treated ", n_na, " empty Q-matrix cell(s) as 0."),
            zh=paste0("\u5c06 Q \u77e9\u9635\u4e2d\u7684 ", n_na,
                " \u4e2a\u7a7a\u5355\u5143\u683c\u6309 0 \u5904\u7406\u3002"))
    }
    rownames(Q) <- items
    zero_rows <- rownames(Q)[rowSums(Q != 0) == 0L]
    if (length(zero_rows) > 0L) {
        irtc_stop(code="E114",
            en=paste0("Item(s) with no dimension loading in the Q matrix: ",
                paste(zero_rows, collapse=", "), "."),
            zh=paste0("Q \u77e9\u9635\u4e2d\u4ee5\u4e0b\u9898\u76ee\u672a\u8f7d\u8377\u4efb\u4f55\u7ef4\u5ea6\uff1a",
                paste(zero_rows, collapse="\u3001"), "\u3002"),
            fix_en="Every item must load on at least one dimension.",
            fix_zh="\u6bcf\u9053\u9898\u5fc5\u987b\u81f3\u5c11\u5c5e\u4e8e\u4e00\u4e2a\u7ef4\u5ea6\u3002",
            class="irtc_error_data_format", data=list(items=zero_rows))
    }
    log <- irtc_log_add(log, "qmatrix", "I130",
        en=paste0("Read a Q matrix with ", nrow(Q), " item(s) and ",
            ncol(Q), " dimension(s): ",
            paste(colnames(Q), collapse=", "), "."),
        zh=paste0("\u8bfb\u5165 Q \u77e9\u9635\uff1a", nrow(Q), " \u9053\u9898\u3001",
            ncol(Q), " \u4e2a\u7ef4\u5ea6\uff08",
            paste(colnames(Q), collapse="\u3001"), "\uff09\u3002"))
    irtc_q_finish(Q=Q, partial=partial, max_score=max_score, log=log,
        source=source_label)
}

## Parse the partial-credit declaration column: 0/1 flags, TRUE/FALSE,
## yes/no (EN and ZH), or integer maximum scores (>= 2 means partial).
irtc_q_parse_partial <- function(col, column)
{
    raw_chr <- tolower(trimws(as.character(col)))
    raw_chr[raw_chr %in% c("", "na")] <- NA_character_
    yes <- c("true", "t", "yes", "y", "\u662f")
    no <- c("false", "f", "no", "n", "\u5426")
    num <- suppressWarnings(as.numeric(raw_chr))
    is_txt <- !is.na(raw_chr) & is.na(num)
    bad <- is_txt & !(raw_chr %in% c(yes, no))
    if (any(bad) || any(!is.na(num) & (num < 0 | num != round(num)))) {
        bad_vals <- unique(c(raw_chr[bad],
            raw_chr[!is.na(num) & (num < 0 | num != round(num))]))
        irtc_stop(code="E115",
            en=paste0("Invalid value(s) in the partial-credit column '",
                column, "': ", paste(bad_vals, collapse=", "), "."),
            zh=paste0("\u5206\u90e8\u8ba1\u5206\u5217 '", column,
                "' \u4e2d\u5b58\u5728\u65e0\u6548\u53d6\u503c\uff1a",
                paste(bad_vals, collapse="\u3001"), "\u3002"),
            fix_en=paste0("Use 0/1, TRUE/FALSE, yes/no, or an integer ",
                "maximum score (>= 2 means partial credit)."),
            fix_zh=paste0("\u8bf7\u4f7f\u7528 0/1\u3001TRUE/FALSE\u3001\u662f/\u5426\uff0c",
                "\u6216\u6574\u6570\u6ee1\u5206\uff08>= 2 \u8868\u793a\u5206\u90e8\u8ba1\u5206\uff09\u3002"),
            class="irtc_error_data_format",
            data=list(column=column, values=bad_vals))
    }
    partial <- logical(length(col))
    max_score <- rep(NA_integer_, length(col))
    partial[is_txt & raw_chr %in% yes] <- TRUE
    num_only <- num
    ## numbers: 0/1 are flags unless any value >= 2 appears in the column,
    ## in which case the whole column is read as maximum scores
    if (any(!is.na(num_only))) {
        if (any(num_only >= 2, na.rm=TRUE)) {
            has <- !is.na(num_only)
            max_score[has] <- as.integer(num_only[has])
            partial[has] <- num_only[has] >= 2
        } else {
            has <- !is.na(num_only)
            partial[has] <- num_only[has] == 1
        }
    }
    ## missing declaration = not partial credit
    list(partial=partial, max_score=max_score)
}

irtc_q_finish <- function(Q, partial, max_score, log, source)
{
    if (is.null(partial)) {
        partial <- stats::setNames(rep(FALSE, nrow(Q)), rownames(Q))
    }
    if (is.null(max_score)) {
        max_score <- stats::setNames(rep(NA_integer_, nrow(Q)), rownames(Q))
    }
    out <- list(Q=Q, partial=partial, max_score=max_score, log=log,
        source=source)
    class(out) <- "irtc_qmatrix"
    out
}

## --------------------------------------------------------------------------
## Alignment against the response data
## --------------------------------------------------------------------------

irtc_align_q <- function(data, q, on_mismatch=c("warn", "error"))
{
    on_mismatch <- match.arg(on_mismatch)
    if (!inherits(q, "irtc_qmatrix")) {
        q <- irtc_read_q(q)
    }
    is_irtc_data <- inherits(data, "irtc_data")
    if (is_irtc_data) {
        data_obj <- data
        resp <- data_obj$resp
    } else if (is.matrix(data) || is.data.frame(data)) {
        data_obj <- NULL
        resp <- as.data.frame(data, stringsAsFactors=FALSE)
    } else {
        irtc_stop(code="E201",
            en="'data' must be an irtc_data object, data frame or matrix.",
            zh=paste0("\u53c2\u6570 'data' \u5fc5\u987b\u662f irtc_data \u5bf9\u8c61\u3001",
                "data.frame \u6216 matrix\u3002"),
            fix_en="Read the data first, e.g. irtc_read(\"data.xlsx\").",
            fix_zh=paste0("\u8bf7\u5148\u8bfb\u5165\u6570\u636e\uff0c\u4f8b\u5982 ",
                "irtc_read(\"data.xlsx\")\u3002"),
            class="irtc_error_data_format")
    }
    data_items <- colnames(resp)
    q_items <- rownames(q$Q)
    q_only <- setdiff(q_items, data_items)
    data_only <- setdiff(data_items, q_items)
    common <- intersect(data_items, q_items)

    if (length(common) < 2L) {
        irtc_stop(code="E422",
            en=paste0("The Q matrix and the response data share fewer than ",
                "2 items (Q: ", length(q_items), " item(s); data: ",
                length(data_items), " item(s); shared: ", length(common),
                ")."),
            zh=paste0("Q \u77e9\u9635\u4e0e\u4f5c\u7b54\u6570\u636e\u7684\u5171\u540c\u9898\u76ee\u4e0d\u8db3 2 \u9053",
                "\uff08Q \u77e9\u9635 ", length(q_items), " \u9053\uff0c\u6570\u636e ",
                length(data_items), " \u9053\uff0c\u5171\u540c ", length(common),
                " \u9053\uff09\u3002"),
            fix_en=paste0("Check that the Q-matrix item names match the ",
                "column names of the data."),
            fix_zh=paste0("\u8bf7\u6838\u5bf9 Q \u77e9\u9635\u7684\u9898\u76ee\u540d\u4e0e\u6570\u636e\u5217\u540d",
                "\u662f\u5426\u4e00\u81f4\u3002"),
            class="irtc_error_data_format",
            data=list(q_only=q_only, data_only=data_only))
    }
    if ((length(q_only) > 0L || length(data_only) > 0L) &&
        identical(on_mismatch, "error")) {
        irtc_stop(code="E422",
            en=paste0("Item mismatch between the Q matrix and the data. ",
                "In Q only: ",
                if (length(q_only)) paste(q_only, collapse=", ") else "-",
                "; in data only: ",
                if (length(data_only)) paste(data_only, collapse=", ")
                else "-", "."),
            zh=paste0("Q \u77e9\u9635\u4e0e\u4f5c\u7b54\u6570\u636e\u7684\u9898\u76ee\u4e0d\u4e00\u81f4\u3002\u4ec5 Q \u77e9\u9635\u6709\uff1a",
                if (length(q_only)) paste(q_only, collapse="\u3001")
                else "\u65e0",
                "\uff1b\u4ec5\u6570\u636e\u6709\uff1a",
                if (length(data_only)) paste(data_only, collapse="\u3001")
                else "\u65e0", "\u3002"),
            fix_en=paste0("Fix the item names, or use on_mismatch=\"warn\" ",
                "to keep the shared items automatically."),
            fix_zh=paste0("\u8bf7\u4fee\u6b63\u9898\u76ee\u540d\uff1b\u6216\u4f7f\u7528 on_mismatch=\"warn\" ",
                "\u81ea\u52a8\u4fdd\u7559\u5171\u540c\u9898\u76ee\u7ee7\u7eed\u3002"),
            class="irtc_error_data_format",
            data=list(q_only=q_only, data_only=data_only))
    }
    log_new <- irtc_log_new()
    if (length(q_only) > 0L) {
        irtc_warn(code="W420",
            en=paste0("Item(s) in the Q matrix but not in the data (removed",
                " from the Q matrix): ", paste(q_only, collapse=", "), "."),
            zh=paste0("\u4ee5\u4e0b\u9898\u76ee\u5728 Q \u77e9\u9635\u4e2d\u4f46\u4e0d\u5728\u6570\u636e\u4e2d\uff08\u5df2\u4ece Q ",
                "\u77e9\u9635\u79fb\u9664\uff09\uff1a", paste(q_only, collapse="\u3001"), "\u3002"),
            fix_en="Check for renamed or missing items in the data.",
            fix_zh=paste0("\u8bf7\u68c0\u67e5\u6570\u636e\u4e2d\u7684\u9898\u76ee\u662f\u5426\u6539\u540d\u6216",
                "\u7f3a\u5931\u3002"),
            class="irtc_warning_estimation", data=list(items=q_only))
        log_new <- irtc_log_add(log_new, "qmatrix", "W420",
            en=paste0("Removed from the Q matrix (not in the data): ",
                paste(q_only, collapse=", "), "."),
            zh=paste0("\u4ece Q \u77e9\u9635\u79fb\u9664\uff08\u6570\u636e\u4e2d\u6ca1\u6709\uff09\uff1a",
                paste(q_only, collapse="\u3001"), "\u3002"))
    }
    if (length(data_only) > 0L) {
        irtc_warn(code="W421",
            en=paste0("Item(s) in the data but not in the Q matrix (removed",
                " from the analysis): ", paste(data_only, collapse=", "),
                "."),
            zh=paste0("\u4ee5\u4e0b\u9898\u76ee\u5728\u6570\u636e\u4e2d\u4f46\u4e0d\u5728 Q \u77e9\u9635\u4e2d\uff08\u5df2\u4ece",
                "\u5206\u6790\u4e2d\u79fb\u9664\uff09\uff1a", paste(data_only, collapse="\u3001"),
                "\u3002"),
            fix_en="Add the items to the Q matrix if they belong in.",
            fix_zh=paste0("\u5982\u8fd9\u4e9b\u9898\u76ee\u5e94\u53c2\u4e0e\u5206\u6790\uff0c\u8bf7\u8865\u5165 Q ",
                "\u77e9\u9635\u3002"),
            class="irtc_warning_estimation", data=list(items=data_only))
        log_new <- irtc_log_add(log_new, "qmatrix", "W421",
            en=paste0("Removed from the analysis (not in the Q matrix): ",
                paste(data_only, collapse=", "), "."),
            zh=paste0("\u4ece\u5206\u6790\u4e2d\u79fb\u9664\uff08Q \u77e9\u9635\u4e2d\u6ca1\u6709\uff09\uff1a",
                paste(data_only, collapse="\u3001"), "\u3002"))
        resp <- resp[, setdiff(data_items, data_only), drop=FALSE]
    }
    ## reorder the Q matrix to the (remaining) data column order
    keep <- colnames(resp)
    q$Q <- q$Q[keep, , drop=FALSE]
    q$partial <- q$partial[keep]
    q$max_score <- q$max_score[keep]
    q$log <- rbind(q$log, log_new)
    if (is_irtc_data) {
        data_obj$resp <- resp
        data_obj$log <- rbind(data_obj$log, log_new)
    } else {
        data_obj <- resp
    }
    list(data=data_obj, q=q, common=keep, q_only=q_only,
        data_only=data_only)
}

## --------------------------------------------------------------------------
## Print method
## --------------------------------------------------------------------------

print.irtc_qmatrix <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("IRTC Q matrix", "IRTC Q \u77e9\u9635", lang), "\n", sep="")
    cat("  ", irtc_tr("Source", "\u6570\u636e\u6765\u6e90", lang), ": ", x$source,
        "\n", sep="")
    cat("  ", irtc_tr("Items", "\u9898\u76ee\u6570", lang), ": ", nrow(x$Q),
        "  ", irtc_tr("Dimensions", "\u7ef4\u5ea6\u6570", lang), ": ", ncol(x$Q),
        " (", paste(colnames(x$Q), collapse=", "), ")\n", sep="")
    n_partial <- sum(x$partial)
    cat("  ", irtc_tr("Partial-credit items", "\u5206\u90e8\u8ba1\u5206\u9898", lang), ": ",
        n_partial, "\n", sep="")
    if (n_partial > 0L) {
        pn <- names(x$partial)[x$partial]
        ms <- x$max_score[x$partial]
        lab <- ifelse(is.na(ms), pn, paste0(pn, " (",
            irtc_tr("max ", "\u6ee1\u5206 ", lang), ms, ")"))
        cat("    ", paste(lab, collapse=", "), "\n", sep="")
    }
    if (nrow(x$log) > 0L) {
        msgs <- if (identical(lang, "zh")) x$log$message_zh else
            x$log$message_en
        for (i in seq_along(msgs)) {
            cat("  [", x$log$code[i], "] ", msgs[i], "\n", sep="")
        }
    }
    invisible(x)
}
