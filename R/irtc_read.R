# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_read.R
## Part of the IRTC package
## Unified data import with automatic cleaning for the usability layer.
## Supports file paths (.xlsx/.xls, .csv/.tsv/.txt, .sav/.dta/.sas7bdat)
## and in-memory objects (data.frame, matrix, tibble). Every cleaning
## action is recorded in a bilingual log attached to the returned object.

irtc_read <- function(x, sheet=1, id=NULL, missing_codes=c(-9, -99, 99, 999),
    na_strings=c("", "NA", "N/A", "n/a", ".", "*", "\u7f3a\u5931", "\u65e0", "\u7a7a"),
    guess_id=TRUE, clean=TRUE, recode=TRUE, verbose=TRUE)
{
    log <- irtc_log_new()

    ## --- 1. Obtain a raw data frame -------------------------------------
    if (is.character(x)) {
        if (length(x) != 1L || is.na(x)) {
            irtc_stop(code="E102",
                en="'x' must be a single file path or a data object.",
                zh="\u53c2\u6570 'x' \u5fc5\u987b\u662f\u5355\u4e2a\u6587\u4ef6\u8def\u5f84\u6216\u4e00\u4e2a\u6570\u636e\u5bf9\u8c61\u3002",
                fix_en="Pass one file path, e.g. irtc_read(\"data.xlsx\").",
                fix_zh="\u8bf7\u4f20\u5165\u4e00\u4e2a\u6587\u4ef6\u8def\u5f84\uff0c\u4f8b\u5982 irtc_read(\"data.xlsx\")\u3002",
                class="irtc_error_data_format")
        }
        if (!file.exists(x)) {
            irtc_stop(code="E103",
                en=paste0("File not found: '", x, "'."),
                zh=paste0("\u627e\u4e0d\u5230\u6587\u4ef6\uff1a'", x, "'\u3002"),
                fix_en="Check the path and the working directory (getwd()).",
                fix_zh="\u8bf7\u68c0\u67e5\u6587\u4ef6\u8def\u5f84\u548c\u5f53\u524d\u5de5\u4f5c\u76ee\u5f55\uff08getwd()\uff09\u3002",
                class="irtc_error_data_format", data=list(path=x))
        }
        raw <- irtc_read_file(x, sheet=sheet, na_strings=na_strings)
        source_label <- x
        log <- irtc_log_add(log, "read", "I100",
            en=paste0("Read ", nrow(raw), " rows x ", ncol(raw),
                " columns from '", basename(x), "'."),
            zh=paste0("\u4ece\u6587\u4ef6 '", basename(x), "' \u8bfb\u5165 ", nrow(raw),
                " \u884c x ", ncol(raw), " \u5217\u3002"))
    } else if (is.matrix(x) || is.data.frame(x)) {
        raw <- as.data.frame(x, stringsAsFactors=FALSE)
        source_label <- "<R object>"
        log <- irtc_log_add(log, "read", "I101",
            en=paste0("Received an R object with ", nrow(raw), " rows x ",
                ncol(raw), " columns."),
            zh=paste0("\u63a5\u6536 R \u5bf9\u8c61\u6570\u636e\uff1a", nrow(raw), " \u884c x ", ncol(raw),
                " \u5217\u3002"))
    } else {
        irtc_stop(code="E101",
            en=paste0("Unsupported input of class '", class(x)[1L], "'."),
            zh=paste0("\u4e0d\u652f\u6301\u7684\u8f93\u5165\u7c7b\u578b\uff1a'", class(x)[1L], "'\u3002"),
            fix_en=paste0("Supply a file path (.xlsx, .xls, .csv, .tsv, ",
                ".txt, .sav, .dta, .sas7bdat) or a data.frame/matrix."),
            fix_zh=paste0("\u8bf7\u63d0\u4f9b\u6587\u4ef6\u8def\u5f84\uff08\u652f\u6301 .xlsx\u3001.xls\u3001.csv\u3001.tsv\u3001",
                ".txt\u3001.sav\u3001.dta\u3001.sas7bdat\uff09\u6216 data.frame/matrix\u3002"),
            class="irtc_error_data_format")
    }
    if (nrow(raw) == 0L || ncol(raw) == 0L) {
        irtc_stop(code="E104",
            en="The input data is empty (no rows or no columns).",
            zh="\u8f93\u5165\u6570\u636e\u4e3a\u7a7a\uff08\u6ca1\u6709\u884c\u6216\u6ca1\u6709\u5217\uff09\u3002",
            fix_en="Check that the file or object actually contains data.",
            fix_zh="\u8bf7\u68c0\u67e5\u6587\u4ef6\u6216\u5bf9\u8c61\u4e2d\u662f\u5426\u786e\u5b9e\u5305\u542b\u6570\u636e\u3002",
            class="irtc_error_data_format")
    }

    ## Normalise: factors to character, ensure column names exist
    for (j in seq_along(raw)) {
        if (is.factor(raw[[j]])) raw[[j]] <- as.character(raw[[j]])
    }
    if (is.null(colnames(raw)) || any(!nzchar(colnames(raw)))) {
        empty <- which(!nzchar(colnames(raw)))
        colnames(raw)[empty] <- paste0("V", empty)
    }

    ## --- 2. Split off person identifier ---------------------------------
    pid <- NULL
    dropped <- list()
    id_result <- irtc_split_id(raw, id=id, guess_id=guess_id, log=log)
    raw <- id_result$resp
    pid <- id_result$pid
    dropped <- id_result$dropped
    log <- id_result$log

    ## --- 3. Cleaning -----------------------------------------------------
    if (clean) {
        cl <- irtc_clean_resp(raw, missing_codes=missing_codes,
            na_strings=na_strings, recode=recode, log=log)
        raw <- cl$resp
        log <- cl$log
        ## keep the person ID aligned when empty rows were dropped
        if (!is.null(pid) && !is.null(cl$rows_kept)) {
            pid <- pid[cl$rows_kept]
        }
    }

    out <- list(resp=raw, pid=pid, dropped=dropped, log=log,
        source=source_label, clean=clean)
    class(out) <- "irtc_data"
    if (verbose) {
        print(out)
    }
    invisible(out)
}

## --------------------------------------------------------------------------
## File readers
## --------------------------------------------------------------------------

irtc_read_file <- function(path, sheet=1, na_strings=character(0))
{
    ext <- tolower(tools::file_ext(path))
    if (ext %in% c("xlsx", "xls")) {
        irtc_require("readxl",
            purpose_en="read Excel files",
            purpose_zh="\u8bfb\u53d6 Excel \u6587\u4ef6")
        df <- readxl::read_excel(path, sheet=sheet, na=na_strings,
            .name_repair="minimal")
        return(as.data.frame(df, stringsAsFactors=FALSE))
    }
    if (ext %in% c("csv", "tsv", "txt", "dat")) {
        return(irtc_read_delim(path, na_strings=na_strings))
    }
    if (ext %in% c("sav", "zsav", "por", "dta", "sas7bdat", "xpt")) {
        irtc_require("haven",
            purpose_en="read SPSS/Stata/SAS files",
            purpose_zh="\u8bfb\u53d6 SPSS/Stata/SAS \u6587\u4ef6")
        df <- switch(ext,
            sav=haven::read_sav(path),
            zsav=haven::read_sav(path),
            por=haven::read_por(path),
            dta=haven::read_dta(path),
            sas7bdat=haven::read_sas(path),
            xpt=haven::read_xpt(path))
        df <- haven::zap_labels(haven::zap_missing(df))
        return(as.data.frame(df, stringsAsFactors=FALSE))
    }
    irtc_stop(code="E105",
        en=paste0("Unsupported file extension '.", ext, "'."),
        zh=paste0("\u4e0d\u652f\u6301\u7684\u6587\u4ef6\u6269\u5c55\u540d\uff1a'.", ext, "'\u3002"),
        fix_en=paste0("Supported: .xlsx, .xls, .csv, .tsv, .txt, .dat, ",
            ".sav, .por, .dta, .sas7bdat, .xpt."),
        fix_zh=paste0("\u652f\u6301\u7684\u683c\u5f0f\uff1a.xlsx\u3001.xls\u3001.csv\u3001.tsv\u3001.txt\u3001.dat\u3001",
            ".sav\u3001.por\u3001.dta\u3001.sas7bdat\u3001.xpt\u3002"),
        class="irtc_error_data_format", data=list(path=path, ext=ext))
}

## Delimited text reader with encoding and delimiter detection.
irtc_read_delim <- function(path, na_strings=character(0))
{
    enc <- irtc_detect_encoding(path)
    lines <- readLines(path, n=50L, warn=FALSE, encoding="bytes")
    if (identical(enc, "UTF-8-BOM")) {
        ## "UTF-8-BOM" is a fileEncoding for read.table(), not an iconv
        ## encoding: strip the BOM bytes for delimiter detection only
        if (length(lines) > 0L) {
            lines[1L] <- sub("^\xEF\xBB\xBF", "", lines[1L], useBytes=TRUE)
        }
        Encoding(lines) <- "UTF-8"
    } else if (!identical(enc, "UTF-8")) {
        lines <- iconv(lines, from=enc, to="UTF-8")
    } else {
        Encoding(lines) <- "UTF-8"
    }
    lines <- lines[nzchar(trimws(lines))]
    if (length(lines) == 0L) {
        irtc_stop(code="E104",
            en="The input data is empty (no rows or no columns).",
            zh="\u8f93\u5165\u6570\u636e\u4e3a\u7a7a\uff08\u6ca1\u6709\u884c\u6216\u6ca1\u6709\u5217\uff09\u3002",
            fix_en="Check that the file actually contains data.",
            fix_zh="\u8bf7\u68c0\u67e5\u6587\u4ef6\u4e2d\u662f\u5426\u786e\u5b9e\u5305\u542b\u6570\u636e\u3002",
            class="irtc_error_data_format")
    }
    sep <- irtc_detect_delimiter(lines)
    df <- utils::read.table(path, header=TRUE, sep=sep, na.strings=na_strings,
        stringsAsFactors=FALSE, check.names=FALSE, fileEncoding=enc,
        quote="\"", comment.char="", fill=TRUE, blank.lines.skip=TRUE)
    df
}

## Detect UTF-8 (with or without BOM) versus GBK/GB18030 text.
irtc_detect_encoding <- function(path)
{
    n <- min(file.info(path)$size, 65536)
    bytes <- readBin(path, what="raw", n=n)
    if (length(bytes) >= 3L && bytes[1L] == as.raw(0xEF) &&
        bytes[2L] == as.raw(0xBB) && bytes[3L] == as.raw(0xBF)) {
        return("UTF-8-BOM")
    }
    bytes <- bytes[bytes != as.raw(0L)]
    txt <- rawToChar(bytes)
    Encoding(txt) <- "UTF-8"
    if (validUTF8(txt)) {
        return("UTF-8")
    }
    "GB18030"
}

## Choose the delimiter that yields the most consistent field count.
irtc_detect_delimiter <- function(lines)
{
    candidates <- c(",", "\t", ";", "|")
    best <- ","
    best_score <- -1
    for (sep in candidates) {
        counts <- vapply(lines, function(line) {
            length(strsplit(line, sep, fixed=TRUE)[[1L]])
        }, integer(1L), USE.NAMES=FALSE)
        if (max(counts) <= 1L) next
        score <- mean(counts == counts[1L]) * counts[1L]
        if (score > best_score) {
            best_score <- score
            best <- sep
        }
    }
    if (best_score < 0) {
        ## single-column file; any separator works
        best <- ","
    }
    best
}

## --------------------------------------------------------------------------
## Identifier handling
## --------------------------------------------------------------------------

irtc_id_name_pool <- function()
{
    c("id", "pid", "sid", "uid", "person", "personid", "person_id",
      "student", "studentid", "student_id", "subject", "subjectid",
      "case", "caseid", "name", "\u7f16\u53f7", "\u5b66\u53f7", "\u59d3\u540d", "\u8003\u53f7", "\u8003\u751f\u53f7",
      "\u51c6\u8003\u8bc1", "\u51c6\u8003\u8bc1\u53f7", "\u5e8f\u53f7", "\u5de5\u53f7", "\u88ab\u8bd5", "\u88ab\u8bd5\u7f16\u53f7")
}

irtc_split_id <- function(resp, id=NULL, guess_id=TRUE, log)
{
    pid <- NULL
    dropped <- list()
    if (!is.null(id)) {
        if (is.numeric(id)) id <- colnames(resp)[id]
        missing_cols <- setdiff(id, colnames(resp))
        if (length(missing_cols) > 0L) {
            irtc_stop(code="E106",
                en=paste0("ID column(s) not found: ",
                    paste(missing_cols, collapse=", "), "."),
                zh=paste0("\u627e\u4e0d\u5230\u6307\u5b9a\u7684 ID \u5217\uff1a",
                    paste(missing_cols, collapse="\u3001"), "\u3002"),
                fix_en="Check colnames() of your data for the exact name.",
                fix_zh="\u8bf7\u7528 colnames() \u67e5\u770b\u6570\u636e\u7684\u5b9e\u9645\u5217\u540d\u3002",
                class="irtc_error_data_format", data=list(id=missing_cols))
        }
        pid <- resp[[id[1L]]]
        for (extra_col in id[-1L]) dropped[[extra_col]] <- resp[[extra_col]]
        log <- irtc_log_add(log, "id", "I110",
            en=paste0("Used column '", id[1L], "' as the person ID."),
            zh=paste0("\u4f7f\u7528\u5217 '", id[1L], "' \u4f5c\u4e3a\u4e2a\u6848 ID\u3002"))
        resp <- resp[, setdiff(colnames(resp), id), drop=FALSE]
    } else if (guess_id) {
        hits <- which(tolower(trimws(colnames(resp))) %in% irtc_id_name_pool())
        if (length(hits) > 0L) {
            first <- hits[1L]
            pid <- resp[[first]]
            log <- irtc_log_add(log, "id", "I111",
                en=paste0("Detected column '", colnames(resp)[first],
                    "' as the person ID and set it aside."),
                zh=paste0("\u81ea\u52a8\u8bc6\u522b\u5217 '", colnames(resp)[first],
                    "' \u4e3a\u4e2a\u6848 ID\uff0c\u5df2\u4ece\u4f5c\u7b54\u6570\u636e\u4e2d\u5206\u79bb\u3002"))
            for (h in hits[-1L]) {
                dropped[[colnames(resp)[h]]] <- resp[[h]]
                log <- irtc_log_add(log, "id", "I112",
                    en=paste0("Set aside non-response column '",
                        colnames(resp)[h], "'."),
                    zh=paste0("\u5206\u79bb\u975e\u4f5c\u7b54\u5217 '", colnames(resp)[h], "'\u3002"))
            }
            resp <- resp[, -hits, drop=FALSE]
        }
    }
    if (!is.null(pid) && anyDuplicated(pid) > 0L) {
        log <- irtc_log_add(log, "id", "W113",
            en=paste0("The person ID contains ",
                sum(duplicated(pid)), " duplicated value(s)."),
            zh=paste0("\u4e2a\u6848 ID \u4e2d\u6709 ", sum(duplicated(pid)),
                " \u4e2a\u91cd\u590d\u503c\uff0c\u8bf7\u6838\u5bf9\u3002"))
    }
    list(resp=resp, pid=pid, dropped=dropped, log=log)
}

## --------------------------------------------------------------------------
## Cleaning engine
## --------------------------------------------------------------------------

irtc_clean_resp <- function(resp, missing_codes=c(-9, -99, 99, 999),
    na_strings=character(0), recode=TRUE, log)
{
    ## 3a. drop all-empty rows and columns
    all_na_col <- vapply(resp, function(col) {
        all(is.na(col) | (is.character(col) & !nzchar(trimws(col))))
    }, logical(1L))
    if (any(all_na_col)) {
        log <- irtc_log_add(log, "clean", "I120",
            en=paste0("Dropped ", sum(all_na_col), " completely empty ",
                "column(s): ",
                paste(colnames(resp)[all_na_col], collapse=", "), "."),
            zh=paste0("\u5220\u9664\u5b8c\u5168\u4e3a\u7a7a\u7684\u5217 ", sum(all_na_col), " \u4e2a\uff1a",
                paste(colnames(resp)[all_na_col], collapse="\u3001"), "\u3002"))
        resp <- resp[, !all_na_col, drop=FALSE]
    }
    rows_kept <- rep(TRUE, nrow(resp))
    if (ncol(resp) > 0L && nrow(resp) > 0L) {
        empty_cell <- vapply(resp, function(col) {
            if (is.character(col)) {
                is.na(col) | !nzchar(trimws(col))
            } else {
                is.na(col)
            }
        }, logical(nrow(resp)))
        empty_cell <- matrix(empty_cell, nrow=nrow(resp))
        all_na_row <- rowSums(!empty_cell) == 0L
        if (any(all_na_row)) {
            log <- irtc_log_add(log, "clean", "I121",
                en=paste0("Dropped ", sum(all_na_row),
                    " completely empty row(s)."),
                zh=paste0("\u5220\u9664\u5b8c\u5168\u4e3a\u7a7a\u7684\u884c ", sum(all_na_row), " \u884c\u3002"))
            resp <- resp[!all_na_row, , drop=FALSE]
            rows_kept <- !all_na_row
        }
    }

    ## 3b. character columns: strip whitespace, map NA strings,
    ##     convert numeric-like columns to numeric
    for (j in seq_along(resp)) {
        col <- resp[[j]]
        if (!is.character(col)) next
        col <- trimws(col)
        col[col %in% na_strings] <- NA_character_
        converted <- suppressWarnings(as.numeric(col))
        ok <- is.na(col) | !is.na(converted)
        if (all(ok)) {
            if (any(!is.na(converted))) {
                resp[[j]] <- converted
                log <- irtc_log_add(log, "clean", "I122",
                    en=paste0("Converted text column '", colnames(resp)[j],
                        "' to numeric."),
                    zh=paste0("\u5c06\u6587\u672c\u5217 '", colnames(resp)[j],
                        "' \u8f6c\u6362\u4e3a\u6570\u503c\u3002"))
            }
        } else {
            resp[[j]] <- col
        }
    }

    ## 3c. numeric missing codes -> NA (guarded per column)
    if (length(missing_codes) > 0L) {
        n_replaced <- 0L
        for (j in seq_along(resp)) {
            col <- resp[[j]]
            if (!is.numeric(col)) next
            for (code_val in missing_codes) {
                hit <- !is.na(col) & col == code_val
                if (!any(hit)) next
                other <- col[!hit]
                other <- other[!is.na(other)]
                ## Replace only when the code is clearly outside the
                ## observed response range: negative codes always, positive
                ## codes only when far above all remaining values.
                if (code_val < 0 ||
                    length(other) == 0L || code_val > max(other) + 1) {
                    col[hit] <- NA_real_
                    n_replaced <- n_replaced + sum(hit)
                }
            }
            resp[[j]] <- col
        }
        if (n_replaced > 0L) {
            log <- irtc_log_add(log, "clean", "I123",
                en=paste0("Recoded ", n_replaced, " missing-code value(s) (",
                    paste(missing_codes, collapse=", "), ") to NA."),
                zh=paste0("\u5c06 ", n_replaced, " \u4e2a\u7f3a\u5931\u7801\u53d6\u503c\uff08",
                    paste(missing_codes, collapse="\u3001"), "\uff09\u8f6c\u6362\u4e3a NA\u3002"))
        }
    }

    ## 3d. category recoding for integer response columns
    if (recode) {
        for (j in seq_along(resp)) {
            col <- resp[[j]]
            if (!is.numeric(col)) next
            vals <- col[!is.na(col)]
            if (length(vals) == 0L) next
            if (any(vals != round(vals))) next
            uv <- sort(unique(vals))
            if (min(uv) == 0 && identical(uv, seq(0, max(uv)))) next
            if (length(uv) > 30L) next
            mapped <- match(col, uv) - 1L
            mapped[is.na(col)] <- NA_integer_
            resp[[j]] <- as.numeric(mapped)
            log <- irtc_log_add(log, "clean", "I124",
                en=paste0("Recoded item '", colnames(resp)[j],
                    "' categories (", paste(uv, collapse=","),
                    ") to consecutive scores starting at 0."),
                zh=paste0("\u5c06\u9898\u76ee '", colnames(resp)[j], "' \u7684\u7c7b\u522b\u53d6\u503c\uff08",
                    paste(uv, collapse="\u3001"),
                    "\uff09\u91cd\u7f16\u7801\u4e3a\u4ece 0 \u5f00\u59cb\u7684\u8fde\u7eed\u5206\u6570\u3002"))
        }
    }

    list(resp=resp, log=log, rows_kept=rows_kept)
}

## --------------------------------------------------------------------------
## Cleaning log helpers
## --------------------------------------------------------------------------

irtc_log_new <- function()
{
    data.frame(step=character(0), code=character(0),
        message_en=character(0), message_zh=character(0),
        stringsAsFactors=FALSE)
}

irtc_log_add <- function(log, step, code, en, zh)
{
    rbind(log, data.frame(step=step, code=code, message_en=en,
        message_zh=zh, stringsAsFactors=FALSE))
}

## --------------------------------------------------------------------------
## Print method
## --------------------------------------------------------------------------

print.irtc_data <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("IRTC data object", "IRTC \u6570\u636e\u5bf9\u8c61", lang), "\n", sep="")
    cat("  ", irtc_tr("Source", "\u6570\u636e\u6765\u6e90", lang), ": ", x$source, "\n",
        sep="")
    cat("  ", irtc_tr("Persons", "\u6837\u672c\u6570", lang), ": ", nrow(x$resp),
        "  ", irtc_tr("Items", "\u9898\u76ee\u6570", lang), ": ", ncol(x$resp), "\n",
        sep="")
    cat("  ", irtc_tr("Person ID", "\u4e2a\u6848 ID", lang), ": ",
        if (is.null(x$pid)) irtc_tr("none", "\u65e0", lang)
        else irtc_tr("yes", "\u6709", lang), "\n", sep="")
    if (nrow(x$log) > 0L) {
        cat(irtc_tr("Cleaning log:", "\u6e05\u6d17\u65e5\u5fd7\uff1a", lang), "\n", sep="")
        msgs <- if (identical(lang, "zh")) x$log$message_zh else
            x$log$message_en
        for (i in seq_along(msgs)) {
            cat("  [", x$log$code[i], "] ", msgs[i], "\n", sep="")
        }
    }
    invisible(x)
}
