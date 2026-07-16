# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_ctt.R
## Part of the IRTC package
## Classical test theory statistics: item difficulty (p-values), corrected
## item-total correlations, Cronbach's alpha and alpha-if-item-deleted.
## These feed the plain-language item quality table.

irtc_ctt <- function(x, key=NULL)
{
    if (inherits(x, "irtc_data")) {
        resp <- x$resp
    } else if (is.matrix(x) || is.data.frame(x)) {
        resp <- as.data.frame(x, stringsAsFactors=FALSE)
    } else if (inherits(x, "irtc")) {
        resp <- as.data.frame(x$resp, stringsAsFactors=FALSE)
    } else {
        irtc_stop(code="E301",
            en="'x' must be an irtc_data object, data frame, matrix or irtc model.",
            zh="\u53c2\u6570 'x' \u5fc5\u987b\u662f irtc_data \u5bf9\u8c61\u3001data.frame\u3001matrix \u6216 irtc \u6a21\u578b\u3002",
            fix_en="Read the data first with irtc_read().",
            fix_zh="\u8bf7\u5148\u7528 irtc_read() \u8bfb\u5165\u6570\u636e\u3002",
            class="irtc_error_data_format")
    }
    if (!is.null(key)) {
        resp <- irtc_score(resp, key=key)
        attr(resp, "scoring_log") <- NULL
    }
    numeric_ok <- vapply(resp, is.numeric, logical(1L))
    if (!all(numeric_ok)) {
        irtc_stop(code="E305",
            en=paste0("Non-numeric item column(s): ",
                paste(names(resp)[!numeric_ok], collapse=", "), "."),
            zh=paste0("\u5b58\u5728\u975e\u6570\u503c\u9898\u76ee\u5217\uff1a",
                paste(names(resp)[!numeric_ok], collapse="\u3001"), "\u3002"),
            fix_en="Score raw responses first with irtc_score(x, key=...).",
            fix_zh="\u8bf7\u5148\u7528 irtc_score(x, key=...) \u5bf9\u539f\u59cb\u4f5c\u7b54\u8ba1\u5206\u3002",
            class="irtc_error_data_format")
    }
    if (ncol(resp) < 2L) {
        irtc_stop(code="E302",
            en="Fewer than 2 item columns; CTT statistics need at least 2 items.",
            zh="\u9898\u76ee\u5217\u5c11\u4e8e 2 \u4e2a\uff0cCTT \u7edf\u8ba1\u81f3\u5c11\u9700\u8981 2 \u4e2a\u9898\u76ee\u3002",
            fix_en="Check that item columns were not dropped during import.",
            fix_zh="\u8bf7\u68c0\u67e5\u6570\u636e\u5bfc\u5165\u65f6\u9898\u76ee\u5217\u662f\u5426\u88ab\u8bef\u5220\u3002",
            class="irtc_error_data_format")
    }

    resp_mat <- as.matrix(resp)
    n_items <- ncol(resp_mat)
    item_max <- apply(resp_mat, 2L, function(col) {
        vals <- col[!is.na(col)]
        if (length(vals) == 0L) NA_real_ else max(vals)
    })

    n_obs <- colSums(!is.na(resp_mat))
    item_mean <- colMeans(resp_mat, na.rm=TRUE)
    pvalue <- ifelse(!is.na(item_max) & item_max > 0,
        item_mean / item_max, NA_real_)

    ## corrected item-total (item-rest) correlation
    total <- rowSums(resp_mat, na.rm=TRUE)
    n_answered <- rowSums(!is.na(resp_mat))
    discr <- rep(NA_real_, n_items)
    for (j in seq_len(n_items)) {
        rest <- total - ifelse(is.na(resp_mat[, j]), 0, resp_mat[, j])
        use <- !is.na(resp_mat[, j]) & n_answered > 1L
        if (sum(use) > 2L && stats::sd(resp_mat[use, j]) > 0 &&
            stats::sd(rest[use]) > 0) {
            discr[j] <- stats::cor(resp_mat[use, j], rest[use])
        }
    }

    ## Cronbach's alpha (pairwise-complete covariances)
    alpha <- irtc_ctt_alpha(resp_mat)
    alpha_drop <- rep(NA_real_, n_items)
    if (n_items > 2L) {
        for (j in seq_len(n_items)) {
            alpha_drop[j] <- irtc_ctt_alpha(resp_mat[, -j, drop=FALSE])
        }
    }

    items <- data.frame(
        item=colnames(resp_mat),
        N=n_obs,
        miss_rate=round(1 - n_obs / nrow(resp_mat), 4),
        max_score=item_max,
        M=round(item_mean, 4),
        pvalue=round(pvalue, 4),
        discr=round(discr, 4),
        alpha_if_deleted=round(alpha_drop, 4),
        stringsAsFactors=FALSE, row.names=NULL
    )
    out <- list(items=items, alpha=alpha, n_persons=nrow(resp_mat),
        n_items=n_items)
    class(out) <- "irtc_ctt"
    out
}

irtc_ctt_alpha <- function(resp_mat)
{
    k <- ncol(resp_mat)
    if (k < 2L) return(NA_real_)
    cov_mat <- suppressWarnings(stats::cov(resp_mat,
        use="pairwise.complete.obs"))
    if (anyNA(cov_mat)) {
        complete <- stats::complete.cases(resp_mat)
        if (sum(complete) < 3L) return(NA_real_)
        cov_mat <- stats::cov(resp_mat[complete, , drop=FALSE])
    }
    total_var <- sum(cov_mat)
    if (!is.finite(total_var) || total_var <= 0) return(NA_real_)
    round(k / (k - 1) * (1 - sum(diag(cov_mat)) / total_var), 4)
}

print.irtc_ctt <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("Classical item statistics", "\u7ecf\u5178\u6d4b\u91cf\uff08CTT\uff09\u9898\u76ee\u7edf\u8ba1",
        lang), "\n", sep="")
    cat("  ", irtc_tr("Persons", "\u6837\u672c\u6570", lang), ": ", x$n_persons,
        "  ", irtc_tr("Items", "\u9898\u76ee\u6570", lang), ": ", x$n_items, "\n",
        sep="")
    cat("  Cronbach alpha: ",
        ifelse(is.na(x$alpha), "NA", format(x$alpha, nsmall=3)), "\n",
        sep="")
    print(x$items, row.names=FALSE)
    invisible(x)
}
