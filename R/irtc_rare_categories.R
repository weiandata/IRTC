# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_rare_categories.R
## Part of the IRTC package
## Robust handling of score categories that nobody reached (nobody fully
## correct / nobody partially correct / nobody wrong). Two strategies:
##   collapse (default) - merge unobserved categories into their lower
##     neighbour and annotate the mapping in the item output;
##   prior - keep the observed category structure and stabilise the
##     thresholds of in-range empty categories: a N(0, sd=2) prior on the
##     irtc.mml path (1PL/PCM), a fixed value of 0 (the prior mean) on
##     the irtc.mml.2pl path (2PL/GPCM), whose core does not evaluate
##     priors. Categories above the observed maximum have no parameter in
##     either mode; they are reported as a reduced maximum score.

## --------------------------------------------------------------------------
## Scan: compare declared and observed categories per item
## --------------------------------------------------------------------------

irtc_rare_scan <- function(resp, q=NULL)
{
    items <- colnames(resp)
    out <- data.frame(item=items, max_declared=NA_integer_,
        max_observed=NA_integer_, unobserved="", needs_collapse=FALSE,
        top_reduced=FALSE, stringsAsFactors=FALSE)
    empty_in_range <- vector("list", length(items))
    names(empty_in_range) <- items
    for (i in seq_along(items)) {
        col <- resp[[items[i]]]
        vals <- col[!is.na(col)]
        if (length(vals) == 0L || !is.numeric(vals)) next
        if (any(vals != round(vals)) || any(vals < 0)) next
        obs <- sort(unique(as.integer(vals)))
        obs_max <- max(obs)
        declared <- obs_max
        if (!is.null(q)) {
            ms <- q$max_score[items[i]]
            if (!is.na(ms)) {
                declared <- max(as.integer(ms), obs_max)
            } else if (isTRUE(unname(q$partial[items[i]]))) {
                declared <- max(2L, obs_max)
            }
        }
        gaps <- setdiff(0:obs_max, obs)
        above <- if (declared > obs_max) (obs_max + 1L):declared else
            integer(0)
        empty_in_range[[items[i]]] <- gaps
        out$max_declared[i] <- declared
        out$max_observed[i] <- obs_max
        out$needs_collapse[i] <- length(gaps) > 0L
        out$top_reduced[i] <- length(above) > 0L
        miss <- c(gaps, above)
        if (length(miss) > 0L) {
            out$unobserved[i] <- paste(miss, collapse=",")
        }
    }
    attr(out, "empty_in_range") <- empty_in_range
    out
}

## --------------------------------------------------------------------------
## Collapse mode
## --------------------------------------------------------------------------

irtc_rare_collapse <- function(resp, scan)
{
    scan$collapse_map <- ""
    log <- irtc_log_new()
    hit <- character(0)
    for (i in seq_len(nrow(scan))) {
        if (!scan$needs_collapse[i]) next
        item <- scan$item[i]
        col <- resp[[item]]
        uv <- sort(unique(col[!is.na(col)]))
        mapped <- match(col, uv) - 1L
        mapped[is.na(col)] <- NA_integer_
        resp[[item]] <- as.numeric(mapped)
        map_str <- paste(paste0(uv, "->", seq_along(uv) - 1L),
            collapse=", ")
        scan$collapse_map[i] <- map_str
        hit <- c(hit, item)
        log <- irtc_log_add(log, "categories", "W425",
            en=paste0("Item '", item, "': unobserved categor(y/ies) ",
                scan$unobserved[i], " collapsed; recoded ", map_str,
                " (declared maximum ", scan$max_declared[i], ")."),
            zh=paste0("\u9898\u76ee '", item, "'\uff1a\u7c7b\u522b ",
                scan$unobserved[i],
                " \u65e0\u4eba\u5f97\u5230\uff0c\u5df2\u6298\u53e0\u5408\u5e76\uff1b\u91cd\u7f16\u7801 ", map_str,
                "\uff08\u58f0\u660e\u6ee1\u5206 ", scan$max_declared[i], "\uff09\u3002"))
    }
    for (i in seq_len(nrow(scan))) {
        if (!scan$top_reduced[i] || scan$needs_collapse[i]) next
        log <- irtc_log_add(log, "categories", "W425",
            en=paste0("Item '", scan$item[i], "': top categor(y/ies) ",
                scan$unobserved[i], " unobserved; estimated with maximum ",
                "score ", scan$max_observed[i], " instead of the declared ",
                scan$max_declared[i], "."),
            zh=paste0("\u9898\u76ee '", scan$item[i], "'\uff1a\u6700\u9ad8\u7c7b\u522b ",
                scan$unobserved[i],
                " \u65e0\u4eba\u5f97\u5230\uff0c\u6309\u6700\u9ad8\u5206 ", scan$max_observed[i],
                " \u4f30\u8ba1\uff08\u58f0\u660e\u6ee1\u5206 ", scan$max_declared[i],
                "\uff09\u3002"))
    }
    list(resp=resp, scan=scan, log=log, collapsed_items=hit)
}

## --------------------------------------------------------------------------
## Prior mode: stabilise thresholds of in-range empty categories
## --------------------------------------------------------------------------

## Map (item, step) to the xsi parameter index of the default PCM-type
## design matrix: parameters are ordered item by item, steps 1..maxKi.
irtc_rare_affected_xsi <- function(resp, scan)
{
    empty_in_range <- attr(scan, "empty_in_range")
    maxKi <- vapply(seq_len(ncol(resp)), function(j) {
        max(resp[[j]], na.rm=TRUE)
    }, numeric(1L))
    offset <- cumsum(c(0, maxKi))
    idx <- integer(0)
    labels <- character(0)
    for (j in seq_len(ncol(resp))) {
        item <- colnames(resp)[j]
        gaps <- empty_in_range[[item]]
        if (length(gaps) == 0L) next
        steps <- unique(pmax(1L, as.integer(gaps)))
        steps <- steps[steps <= maxKi[j]]
        idx <- c(idx, offset[j] + steps)
        labels <- c(labels, paste0(item, "_Cat", steps))
    }
    list(index=idx, labels=labels, n_parameters=sum(maxKi))
}

irtc_rare_prior_args <- function(resp, scan, model, prior_mean=0,
    prior_sd=2, weak_sd=1000)
{
    aff <- irtc_rare_affected_xsi(resp, scan)
    if (length(aff$index) == 0L) {
        return(NULL)
    }
    two_pl <- model %in% c("2PL", "GPCM")
    out <- list(affected_index=aff$index, affected_labels=aff$labels,
        two_pl=two_pl)
    if (two_pl) {
        ## the 2PL/GPCM core does not evaluate priors: fix the thresholds
        ## at the prior mean instead
        out$xsi.fixed <- cbind(aff$index, prior_mean)
    } else {
        prior_list <- lapply(seq_len(aff$n_parameters), function(k) {
            list("norm", list(mean=prior_mean, sd=weak_sd, x=NA))
        })
        for (k in aff$index) {
            prior_list[[k]] <- list("norm",
                list(mean=prior_mean, sd=prior_sd, x=NA))
        }
        out$prior_list_xsi <- prior_list
    }
    out
}

## --------------------------------------------------------------------------
## Orchestration used by irtc()
## --------------------------------------------------------------------------

## Returns list(resp=..., fit_extra=..., info=..., log=...).
## 'fit_extra' holds additions for the estimation call (control entries
## or xsi.fixed); 'info' is the per-item annotation table consumed by
## irtc_results() and the reports.
irtc_rare_apply <- function(resp, q=NULL, mode=c("collapse", "prior"),
    model="1PL", custom_design=FALSE)
{
    mode <- match.arg(mode)
    scan <- irtc_rare_scan(resp, q=q)
    scan$prior_dominated <- FALSE
    any_gap <- any(scan$needs_collapse)
    any_top <- any(scan$top_reduced)
    if (!any_gap && !any_top) {
        scan$collapse_map <- ""
        return(list(resp=resp, fit_extra=NULL, info=scan,
            log=irtc_log_new()))
    }
    if (identical(mode, "prior") && custom_design) {
        ## a user-supplied design (A) or a PCM2/RSM parameterisation
        ## breaks the default xsi index mapping
        irtc_warn(code="W426",
            en=paste0("rare_categories=\"prior\" only supports the default",
                " design of models 1PL/PCM/2PL/GPCM; falling back to ",
                "\"collapse\"."),
            zh=paste0("rare_categories=\"prior\" \u4ec5\u652f\u6301 1PL/PCM/2PL/GPCM \u7684\u9ed8\u8ba4\u8bbe\u8ba1\u77e9\u9635\uff1b\u5df2\u6539\u7528 \"collapse\" \u5904\u7406\u3002"),
            fix_en="Collapse the categories or drop the custom design.",
            fix_zh="\u8bf7\u6539\u7528\u6298\u53e0\u65b9\u6848\uff0c\u6216\u4e0d\u4f7f\u7528\u81ea\u5b9a\u4e49\u8bbe\u8ba1\u77e9\u9635\u3002",
            class="irtc_warning_estimation")
        mode <- "collapse"
    }
    if (identical(mode, "collapse")) {
        res <- irtc_rare_collapse(resp, scan)
        affected <- unique(c(res$collapsed_items,
            scan$item[scan$top_reduced]))
        irtc_warn(code="W425",
            en=paste0("Unobserved score categories were collapsed or ",
                "reduced for item(s): ", paste(affected, collapse=", "),
                ". See the cleaning log and the item output columns ",
                "'categories_unobserved'/'categories_collapsed'."),
            zh=paste0("\u4ee5\u4e0b\u9898\u76ee\u5b58\u5728\u65e0\u4eba\u5f97\u5230\u7684\u5206\u6570\u7c7b\u522b\uff0c\u5df2\u6298\u53e0\u6216\u964d\u6863\u5904\u7406\uff1a",
                paste(affected, collapse="\u3001"),
                "\u3002\u8be6\u89c1\u6e05\u6d17\u65e5\u5fd7\u53ca\u9898\u76ee\u8f93\u51fa\u7684 'categories_unobserved'/'categories_collapsed' \u5217\u3002"),
            fix_en=paste0("This is expected with small samples; collect ",
                "more responses to keep all categories."),
            fix_zh=paste0("\u5c0f\u6837\u672c\u4e0b\u5c5e\u6b63\u5e38\u73b0\u8c61\uff1b\u5982\u9700\u4fdd\u7559\u5168\u90e8\u7c7b\u522b\uff0c\u8bf7\u589e\u52a0\u6837\u672c\u91cf\u3002"),
            class="irtc_warning_estimation", data=list(items=affected))
        return(list(resp=res$resp, fit_extra=NULL, info=res$scan,
            log=res$log))
    }
    ## prior mode
    log <- irtc_log_new()
    fit_extra <- irtc_rare_prior_args(resp, scan, model=model)
    scan$collapse_map <- ""
    if (!is.null(fit_extra)) {
        gap_items <- scan$item[scan$needs_collapse]
        scan$prior_dominated <- scan$needs_collapse
        mode_lab_en <- if (fit_extra$two_pl) {
            "fixed at the prior mean 0 (the 2PL/GPCM core does not evaluate priors)"
        } else {
            "given a N(0, 4) prior"
        }
        mode_lab_zh <- if (fit_extra$two_pl) {
            "\u56fa\u5b9a\u5728\u5148\u9a8c\u5747\u503c 0\uff082PL/GPCM \u6838\u5fc3\u4e0d\u652f\u6301\u5148\u9a8c\u8bc4\u4f30\uff09"
        } else {
            "\u65bd\u52a0 N(0, 4) \u5148\u9a8c"
        }
        irtc_warn(code="W425",
            en=paste0("Unobserved in-range categories kept for item(s): ",
                paste(gap_items, collapse=", "), "; their threshold(s) ",
                paste(fit_extra$affected_labels, collapse=", "), " were ",
                mode_lab_en, ". Interpret these thresholds with caution."),
            zh=paste0("\u4ee5\u4e0b\u9898\u76ee\u4fdd\u7559\u4e86\u65e0\u4eba\u5f97\u5230\u7684\u7c7b\u522b\uff1a",
                paste(gap_items, collapse="\u3001"),
                "\uff1b\u5bf9\u5e94\u9608\u503c ",
                paste(fit_extra$affected_labels, collapse="\u3001"),
                " \u5df2", mode_lab_zh,
                "\u3002\u8bf7\u8c28\u614e\u89e3\u91ca\u8fd9\u4e9b\u9608\u503c\u3002"),
            fix_en="Use rare_categories=\"collapse\" for plain estimates.",
            fix_zh=paste0("\u5982\u9700\u5e38\u89c4\u4f30\u8ba1\uff0c\u8bf7\u4f7f\u7528 rare_categories=",
                "\"collapse\"\u3002"),
            class="irtc_warning_estimation",
            data=list(items=gap_items, labels=fit_extra$affected_labels))
        log <- irtc_log_add(log, "categories", "W425",
            en=paste0("Kept unobserved categories; stabilised threshold(s) ",
                paste(fit_extra$affected_labels, collapse=", "), "."),
            zh=paste0("\u4fdd\u7559\u65e0\u4eba\u5f97\u5230\u7684\u7c7b\u522b\uff1b\u5df2\u7a33\u5b9a\u5316\u9608\u503c ",
                paste(fit_extra$affected_labels, collapse="\u3001"),
                "\u3002"))
    }
    for (i in seq_len(nrow(scan))) {
        if (!scan$top_reduced[i]) next
        log <- irtc_log_add(log, "categories", "W425",
            en=paste0("Item '", scan$item[i], "': top categor(y/ies) ",
                scan$unobserved[i], " unobserved; no parameter exists, so ",
                "the item is estimated with maximum score ",
                scan$max_observed[i], "."),
            zh=paste0("\u9898\u76ee '", scan$item[i], "'\uff1a\u6700\u9ad8\u7c7b\u522b ",
                scan$unobserved[i],
                " \u65e0\u4eba\u5f97\u5230\uff0c\u65e0\u5bf9\u5e94\u53c2\u6570\uff0c\u6309\u6700\u9ad8\u5206 ",
                scan$max_observed[i], " \u4f30\u8ba1\u3002"))
    }
    list(resp=resp, fit_extra=fit_extra, info=scan, log=log)
}
