# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_report.R
## Part of the IRTC package
## Word (.docx, via the optional 'officer' package) and self-contained
## HTML analysis reports with three audience layouts:
##   decision - 1-2 page executive summary for decision makers
##   survey   - plain-language full report for survey staff
##   stat     - complete technical report for statisticians

irtc_report <- function(mod, file, format=NULL,
    audience=c("survey", "decision", "stat"), lang=irtc_lang(),
    resp=NULL, title=NULL, overwrite=FALSE, verbose=TRUE)
{
    if (!inherits(mod, "irtc")) {
        irtc_stop(code="E401",
            en="'mod' must be an irtc model object (from irtc() or irtc.mml).",
            zh="\u53c2\u6570 'mod' \u5fc5\u987b\u662f irtc \u6a21\u578b\u5bf9\u8c61\uff08\u7531 irtc() \u6216 irtc.mml \u4ea7\u751f\uff09\u3002",
            fix_en="Fit a model first, e.g. mod <- irtc(data, model=\"1PL\").",
            fix_zh="\u8bf7\u5148\u4f30\u8ba1\u6a21\u578b\uff0c\u4f8b\u5982 mod <- irtc(data, model=\"1PL\")\u3002",
            class="irtc_error_input")
    }
    audience <- match.arg(audience)
    if (is.null(format)) {
        format <- tolower(tools::file_ext(file))
    }
    if (!(format %in% c("docx", "html"))) {
        irtc_stop(code="E503",
            en=paste0("Unsupported report format '", format,
                "'; use \"docx\" or \"html\"."),
            zh=paste0("\u4e0d\u652f\u6301\u7684\u62a5\u544a\u683c\u5f0f\uff1a'", format,
                "'\uff1b\u8bf7\u4f7f\u7528 \"docx\" \u6216 \"html\"\u3002"),
            fix_en="Name the file report.docx or report.html.",
            fix_zh="\u8bf7\u5c06\u6587\u4ef6\u547d\u540d\u4e3a report.docx \u6216 report.html\u3002",
            class="irtc_error_report", data=list(format=format))
    }
    if (file.exists(file) && !overwrite) {
        irtc_stop(code="E501",
            en=paste0("Output file already exists: '", file, "'."),
            zh=paste0("\u8f93\u51fa\u6587\u4ef6\u5df2\u5b58\u5728\uff1a'", file, "'\u3002"),
            fix_en="Use overwrite=TRUE or choose another file name.",
            fix_zh="\u8bf7\u4f7f\u7528 overwrite=TRUE \u6216\u66f4\u6362\u6587\u4ef6\u540d\u3002",
            class="irtc_error_export", data=list(paths=file))
    }
    if (identical(format, "docx")) {
        irtc_require("officer",
            purpose_en="write Word reports",
            purpose_zh="\u751f\u6210 Word \u62a5\u544a")
    }
    out_dir <- dirname(file)
    if (!dir.exists(out_dir)) {
        dir.create(out_dir, recursive=TRUE)
    }
    if (is.null(resp)) resp <- mod$resp
    if (is.null(title)) {
        title <- irtc_tr("IRT Analysis Report", "IRT \u5206\u6790\u62a5\u544a", lang)
    }

    blocks <- irtc_report_blocks(mod, audience=audience, lang=lang,
        resp=resp, title=title)
    if (identical(format, "html")) {
        irtc_report_write_html(blocks, file, lang=lang)
    } else {
        irtc_report_write_docx(blocks, file)
    }
    for (block in blocks) {
        if (identical(block$type, "img") && file.exists(block$value)) {
            unlink(block$value)
        }
    }
    if (verbose) {
        message(irtc_tr(paste0("Report written to '", file, "'."),
            paste0("\u62a5\u544a\u5df2\u751f\u6210\uff1a'", file, "'\u3002"), lang))
    }
    invisible(file)
}

## ---------------------------------------------------------------------------
## Content assembly
## ---------------------------------------------------------------------------

irtc_report_figure <- function(expr, width=900, height=620, res=130)
{
    path <- tempfile(fileext=".png")
    grDevices::png(path, width=width, height=height, res=res)
    ok <- tryCatch({ force(expr); TRUE },
        error=function(e) FALSE)
    grDevices::dev.off()
    if (!ok || !file.exists(path)) return(NULL)
    path
}

irtc_report_quality_display <- function(quality, lang)
{
    tbl <- data.frame(
        a=quality$item,
        b=round(100 * quality$pvalue, 1),
        c=quality$discr,
        d=quality$outfit,
        e=quality$infit,
        f=irtc_quality_rating_label(quality$rating, lang),
        g=if (identical(lang, "zh")) quality$reasons_zh else
            quality$reasons_en,
        stringsAsFactors=FALSE
    )
    colnames(tbl) <- c(
        irtc_tr("Item", "\u9898\u53f7", lang),
        irtc_tr("Score rate (%)", "\u5f97\u5206\u7387(%)", lang),
        irtc_tr("Discrimination", "\u533a\u5206\u5ea6", lang),
        "outfit", "infit",
        irtc_tr("Rating", "\u8bc4\u7ea7", lang),
        irtc_tr("Reasons", "\u539f\u56e0", lang))
    tbl
}

irtc_decision_texts <- function(mod, quality, lang)
{
    rel <- suppressWarnings(mean(unlist(mod$EAP.rel), na.rm=TRUE))
    if (!is.finite(rel)) rel <- NA_real_
    out <- character(0)
    if (!is.null(quality)) {
        n_ok <- sum(quality$rating %in% c("good", "acceptable"))
        n_rev <- sum(quality$rating == "review")
        n_fix <- sum(quality$rating == "revise")
        out <- c(out, irtc_tr(
            paste0(n_ok, " item(s) can enter the item bank as is; ",
                n_rev, " should be reviewed by content experts; ",
                n_fix, " should be revised or replaced before reuse."),
            paste0(n_ok, " \u4e2a\u9898\u76ee\u53ef\u76f4\u63a5\u5165\u9898\u5e93\uff1b", n_rev,
                " \u4e2a\u5efa\u8bae\u7531\u5b66\u79d1\u4e13\u5bb6\u590d\u6838\uff1b", n_fix,
                " \u4e2a\u5efa\u8bae\u4fee\u6539\u6216\u66ff\u6362\u540e\u518d\u4f7f\u7528\u3002"), lang))
    }
    if (!is.na(rel)) {
        out <- c(out, if (rel >= 0.8) irtc_tr(
            paste0("Score reliability (", round(rel, 2), ") supports both",
                " group-level comparisons and individual decisions."),
            paste0("\u5206\u6570\u4fe1\u5ea6\uff08", round(rel, 2),
                "\uff09\u8db3\u4ee5\u652f\u6301\u7fa4\u4f53\u6bd4\u8f83\u548c\u4e2a\u4f53\u5c42\u9762\u7684\u51b3\u7b56\u3002"), lang)
        else if (rel >= 0.7) irtc_tr(
            paste0("Score reliability (", round(rel, 2), ") supports",
                " group-level comparisons; be cautious with high-stakes",
                " individual decisions."),
            paste0("\u5206\u6570\u4fe1\u5ea6\uff08", round(rel, 2), "\uff09\u652f\u6301\u7fa4\u4f53\u5c42\u9762\u7684\u6bd4\u8f83\uff1b",
                "\u7528\u4e8e\u9ad8\u5229\u5bb3\u7684\u4e2a\u4f53\u51b3\u7b56\u65f6\u9700\u8c28\u614e\u3002"), lang)
        else irtc_tr(
            paste0("Score reliability (", round(rel, 2), ") is low: use",
                " results for group-level insights only."),
            paste0("\u5206\u6570\u4fe1\u5ea6\uff08", round(rel, 2),
                "\uff09\u504f\u4f4e\uff1a\u5efa\u8bae\u4ec5\u7528\u4e8e\u7fa4\u4f53\u5c42\u9762\u7684\u53c2\u8003\u3002"), lang))
    }
    out
}

## Model-diagnostics section (convergence, information criteria, EAP
## reliability bands, item fit). 'detail' is TRUE for the stat audience
## (full numeric tables) and FALSE for the condensed survey/decision
## versions. Returns a list of block specs list(type, value, caption).
irtc_report_diagnostics_blocks <- function(mod, resp, lang, detail=TRUE)
{
    b <- list()
    push <- function(type, value, caption=NULL) {
        b[[length(b) + 1L]] <<- list(type=type, value=value,
            caption=caption)
    }
    push("h2", irtc_tr("Model diagnostics", "\u6a21\u578b\u8bca\u65ad", lang))

    ## convergence
    maxiter <- tryCatch(mod$control$maxiter, error=function(e) NULL)
    converged <- is.null(maxiter) || is.na(maxiter) || mod$iter < maxiter
    dh <- mod$deviance.history
    dev_change <- NA_real_
    if (!is.null(dh) && is.matrix(dh) && nrow(dh) >= 2L) {
        tail2 <- dh[(nrow(dh) - 1L):nrow(dh), "deviance"]
        dev_change <- abs(diff(tail2))
    }
    if (converged) {
        push("p", irtc_tr(
            paste0("The estimation converged after ", mod$iter,
                " iteration(s)",
                if (is.finite(dev_change)) paste0(
                    " (final deviance change ", round(dev_change, 5), ")")
                else "", "."),
            paste0("\u4f30\u8ba1\u5728\u7b2c ", mod$iter,
                " \u6b21\u8fed\u4ee3\u540e\u6536\u655b",
                if (is.finite(dev_change)) paste0(
                    "\uff08\u6700\u7ec8\u504f\u5dee\u53d8\u5316 ",
                    round(dev_change, 5), "\uff09") else "", "\u3002"),
            lang))
    } else {
        push("p", irtc_tr(
            paste0("WARNING: the estimation reached the iteration limit (",
                maxiter, ") without meeting the convergence criterion. ",
                "Interpret the parameters with caution and consider ",
                "increasing control=list(maxiter=...)."),
            paste0("\u8b66\u544a\uff1a\u4f30\u8ba1\u5df2\u8fbe\u5230\u8fed\u4ee3\u4e0a\u9650\uff08",
                maxiter, "\uff09\u4ecd\u672a\u6ee1\u8db3\u6536\u655b\u51c6\u5219\u3002",
                "\u8bf7\u8c28\u614e\u89e3\u91ca\u53c2\u6570\uff0c\u5e76\u8003\u8651\u589e\u5927 ",
                "control=list(maxiter=...)\u3002"), lang))
    }

    ## information criteria
    ic <- mod$ic
    ic_tbl <- data.frame(
        a=c("Deviance", "N parameters", "AIC", "BIC"),
        b=c(round(mod$deviance, 2), ic$Npars, round(ic$AIC, 2),
            round(ic$BIC, 2)),
        stringsAsFactors=FALSE)
    colnames(ic_tbl) <- c(irtc_tr("Statistic", "\u7edf\u8ba1\u91cf", lang),
        irtc_tr("Value", "\u53d6\u503c", lang))
    push("table", ic_tbl,
        irtc_tr("Information criteria", "\u4fe1\u606f\u51c6\u5219", lang))
    push("p", irtc_tr(
        paste0("AIC and BIC balance model fit against the number of ",
            "parameters; smaller is better. They are only comparable ",
            "between models fitted to the same responses."),
        paste0("AIC \u4e0e BIC \u5728\u6a21\u578b\u62df\u5408\u4e0e\u53c2\u6570\u6570\u91cf\u4e4b\u95f4\u6743\u8861\uff0c",
            "\u8d8a\u5c0f\u8d8a\u597d\uff1b\u4ec5\u5728\u62df\u5408\u540c\u4e00\u4f5c\u7b54\u6570\u636e\u7684",
            "\u6a21\u578b\u4e4b\u95f4\u53ef\u6bd4\u3002"), lang))

    ## EAP reliability with interpretation band
    rel <- suppressWarnings(mean(unlist(mod$EAP.rel), na.rm=TRUE))
    if (is.finite(rel)) {
        band <- if (rel >= 0.8) irtc_tr("good (>= 0.80)",
                "\u826f\u597d\uff08>= 0.80\uff09", lang)
            else if (rel >= 0.7) irtc_tr("acceptable (0.70-0.80)",
                "\u53ef\u7528\uff080.70-0.80\uff09", lang)
            else irtc_tr("low (< 0.70)", "\u504f\u4f4e\uff08< 0.70\uff09", lang)
        push("p", irtc_tr(
            paste0("EAP reliability: ", round(rel, 3), " - ", band, "."),
            paste0("EAP \u4fe1\u5ea6\uff1a", round(rel, 3), " - ", band,
                "\u3002"), lang))
    }

    ## item fit
    fit <- mod$usability$itemfit
    if (is.null(fit) && !is.null(resp)) {
        fit <- tryCatch(irtc_itemfit(mod, resp=resp), error=function(e) NULL)
    }
    if (!is.null(fit)) {
        push("p", irtc_tr(
            paste0("Infit/outfit mean squares near 1 indicate good fit; a ",
                "common acceptable range is 0.7-1.3. Values well above 1 ",
                "flag noisy items, values well below 1 flag overly ",
                "predictable items."),
            paste0("Infit/outfit \u5747\u65b9\u63a5\u8fd1 1 \u8868\u793a\u62df\u5408\u826f\u597d\uff1b",
                "\u5e38\u7528\u53ef\u63a5\u53d7\u533a\u95f4\u4e3a 0.7-1.3\u3002\u660e\u663e\u5927\u4e8e 1 ",
                "\u8868\u793a\u9898\u76ee\u566a\u58f0\u5927\uff0c\u660e\u663e\u5c0f\u4e8e 1 \u8868\u793a\u9898\u76ee",
                "\u8fc7\u4e8e\u53ef\u9884\u6d4b\u3002"), lang))
        if (detail) {
            push("table", as.data.frame(fit),
                irtc_tr("Item fit statistics", "\u9898\u76ee\u62df\u5408\u7edf\u8ba1",
                    lang))
        }
    }
    b
}

## Data-transparency section (cleaning log, item alignment, weights,
## category collapses, dropped items, scoring summary).
irtc_report_transparency_blocks <- function(mod, lang, detail=TRUE)
{
    u <- mod$usability
    b <- list()
    push <- function(type, value, caption=NULL) {
        b[[length(b) + 1L]] <<- list(type=type, value=value,
            caption=caption)
    }
    push("h2", irtc_tr("Data processing transparency",
        "\u6570\u636e\u5904\u7406\u900f\u660e\u5ea6", lang))

    ## weights
    w <- u$weights
    if (!is.null(w) && length(w) > 0L) {
        cv <- stats::sd(w) / mean(w)
        push("p", irtc_tr(
            paste0("Sampling weights were applied (weighted N = ",
                round(sum(w), 2), "; weight range ", round(min(w), 3),
                " to ", round(max(w), 3), ", CV ", round(cv, 2), ").",
                if (cv > 1) " The large weight variability may inflate the effective standard errors." else ""),
            paste0("\u5206\u6790\u5df2\u52a0\u6743\uff08\u52a0\u6743\u6837\u672c\u91cf = ",
                round(sum(w), 2), "\uff1b\u6743\u91cd\u8303\u56f4 ",
                round(min(w), 3), " \u81f3 ", round(max(w), 3),
                "\uff0c\u53d8\u5f02\u7cfb\u6570 ", round(cv, 2), "\uff09\u3002",
                if (cv > 1) "\u6743\u91cd\u53d8\u5f02\u8f83\u5927\uff0c\u53ef\u80fd\u62ac\u9ad8\u6709\u6548\u6807\u51c6\u8bef\u3002" else ""),
            lang))
    } else {
        push("p", irtc_tr("No sampling weights were used (equal weighting).",
            "\u672a\u4f7f\u7528\u6837\u672c\u6743\u91cd\uff08\u7b49\u6743\u91cd\uff09\u3002", lang))
    }

    ## item alignment against the Q matrix
    q_only <- u$q_only_items
    removed <- u$removed_items
    if (length(q_only) > 0L) {
        push("p", irtc_tr(
            paste0("Item(s) declared in the Q matrix but absent from the ",
                "data (not estimated): ", paste(q_only, collapse=", "), "."),
            paste0("Q \u77e9\u9635\u4e2d\u58f0\u660e\u4f46\u6570\u636e\u4e2d\u7f3a\u5931\u7684\u9898\u76ee",
                "\uff08\u672a\u53c2\u4e0e\u4f30\u8ba1\uff09\uff1a",
                paste(q_only, collapse="\u3001"), "\u3002"), lang))
    }
    if (length(removed) > 0L) {
        push("p", irtc_tr(
            paste0("Item(s) removed before estimation (no responses or ",
                "zero variance): ", paste(removed, collapse=", "), "."),
            paste0("\u4f30\u8ba1\u524d\u5254\u9664\u7684\u9898\u76ee\uff08\u65e0\u4f5c\u7b54\u6216\u96f6",
                "\u65b9\u5dee\uff09\uff1a", paste(removed, collapse="\u3001"),
                "\u3002"), lang))
    }

    ## category collapses
    info <- u$rare_categories
    if (!is.null(info)) {
        rows <- info[info$needs_collapse | info$top_reduced, , drop=FALSE]
        if (nrow(rows) > 0L) {
            tbl <- data.frame(
                a=rows$item,
                b=rows$max_declared,
                c=rows$max_observed,
                d=rows$unobserved,
                e=if (!is.null(rows$collapse_map)) rows$collapse_map else "",
                stringsAsFactors=FALSE)
            colnames(tbl) <- c(
                irtc_tr("Item", "\u9898\u53f7", lang),
                irtc_tr("Declared max", "\u58f0\u660e\u6ee1\u5206", lang),
                irtc_tr("Observed max", "\u89c2\u6d4b\u6700\u9ad8\u5206", lang),
                irtc_tr("Unobserved", "\u672a\u89c2\u6d4b\u7c7b\u522b", lang),
                irtc_tr("Collapse map", "\u6298\u53e0\u6620\u5c04", lang))
            push("table", tbl,
                irtc_tr("Unobserved score categories",
                    "\u65e0\u4eba\u5f97\u5230\u7684\u5206\u6570\u7c7b\u522b", lang))
        }
    }

    ## scoring summary
    si <- u$score_info
    if (!is.null(si)) {
        n_scored <- length(si$scored_items)
        n_partial <- length(si$partial_items)
        push("p", irtc_tr(
            paste0("Scoring: ", n_scored, " item(s) scored",
                if (n_partial > 0L) paste0(", of which ", n_partial,
                    " with partial credit (", paste(si$partial_items,
                    collapse=", "), ")") else "", "."),
            paste0("\u8ba1\u5206\uff1a\u5171\u5bf9 ", n_scored, " \u9053\u9898\u8ba1\u5206",
                if (n_partial > 0L) paste0("\uff0c\u5176\u4e2d ", n_partial,
                    " \u9053\u4e3a\u5206\u90e8\u8ba1\u5206\uff08",
                    paste(si$partial_items, collapse="\u3001"), "\uff09")
                else "", "\u3002"), lang))
    }

    ## full cleaning log
    log <- u$data_log
    if (detail && !is.null(log) && nrow(log) > 0L) {
        msgs <- if (identical(lang, "zh")) log$message_zh else log$message_en
        tbl <- data.frame(a=log$step, b=log$code, c=msgs,
            stringsAsFactors=FALSE)
        colnames(tbl) <- c(irtc_tr("Step", "\u9636\u6bb5", lang),
            irtc_tr("Code", "\u7f16\u7801", lang),
            irtc_tr("Message", "\u8bf4\u660e", lang))
        push("table", tbl,
            irtc_tr("Full cleaning log", "\u5b8c\u6574\u6e05\u6d17\u65e5\u5fd7", lang))
    }
    b
}

irtc_report_blocks <- function(mod, audience, lang, resp, title)
{
    sections <- irtc_summary_texts(mod, lang=lang)
    quality <- mod$usability$quality
    if (is.null(quality) && !is.null(resp)) {
        quality <- tryCatch(irtc_quality(mod, resp=resp),
            error=function(e) NULL)
    }

    blocks <- list()
    add <- function(type, value, caption=NULL) {
        blocks[[length(blocks) + 1L]] <<- list(type=type, value=value,
            caption=caption)
    }

    add("h1", title)
    add("p", format(Sys.Date(), irtc_tr("%Y-%m-%d", "%Y\u5e74%m\u6708%d\u65e5", lang)))

    ## conclusion (all audiences)
    add("h2", sections$conclusion$title)
    for (p in sections$conclusion$body) add("p", p)

    if (identical(audience, "decision")) {
        add("h2", irtc_tr("Recommendations", "\u51b3\u7b56\u5efa\u8bae", lang))
        for (p in irtc_decision_texts(mod, quality, lang)) add("p", p)
        fig <- irtc_report_figure(irtc_plot_quality_summary(mod, lang=lang,
            resp=resp))
        if (!is.null(fig)) add("img", fig,
            irtc_tr("Item quality summary", "\u9898\u76ee\u8d28\u91cf\u5206\u7ea7\u6c47\u603b", lang))
        if (!is.null(quality)) {
            flagged <- quality[quality$rating %in% c("review", "revise"), ]
            if (nrow(flagged) > 0L) {
                add("h2", irtc_tr("Items needing attention",
                    "\u9700\u8981\u5173\u6ce8\u7684\u9898\u76ee", lang))
                add("table", irtc_report_quality_display(flagged, lang))
            }
        }
        fig <- irtc_report_figure(irtc_plot_wright(mod, lang=lang,
            resp=resp))
        if (!is.null(fig)) add("img", fig,
            irtc_tr("Item difficulty vs person ability",
                "\u9898\u76ee\u96be\u5ea6\u4e0e\u6837\u672c\u80fd\u529b\u5bf9\u7167", lang))
        for (bl in irtc_report_diagnostics_blocks(mod, resp, lang,
            detail=FALSE)) add(bl$type, bl$value, bl$caption)
        for (bl in irtc_report_transparency_blocks(mod, lang,
            detail=FALSE)) add(bl$type, bl$value, bl$caption)
        return(blocks)
    }

    ## survey and stat share the main body -----------------------------------
    add("h2", sections$setup$title)
    for (p in sections$setup$body) add("p", p)

    if (!is.null(sections$quality)) {
        add("h2", sections$quality$title)
        for (p in sections$quality$body) add("p", p)
    }
    if (!is.null(quality)) {
        add("table", irtc_report_quality_display(quality, lang),
            irtc_tr("Item quality table", "\u9898\u76ee\u8d28\u91cf\u8868", lang))
        fig <- irtc_report_figure(irtc_plot_quality_summary(mod, lang=lang,
            resp=resp))
        if (!is.null(fig)) add("img", fig,
            irtc_tr("Item quality summary", "\u9898\u76ee\u8d28\u91cf\u5206\u7ea7\u6c47\u603b", lang))
    }

    if (!is.null(sections$ability)) {
        add("h2", sections$ability$title)
        for (p in sections$ability$body) add("p", p)
    }
    fig <- irtc_report_figure(irtc_plot_ability(mod, lang=lang))
    if (!is.null(fig)) add("img", fig,
        irtc_tr("Ability distribution", "\u6837\u672c\u80fd\u529b\u5206\u5e03", lang))
    fig <- irtc_report_figure(irtc_plot_wright(mod, lang=lang, resp=resp))
    if (!is.null(fig)) add("img", fig,
        irtc_tr("Item difficulty vs person ability (Wright map)",
            "\u9898\u76ee\u96be\u5ea6\u4e0e\u6837\u672c\u80fd\u529b\u5bf9\u7167\u56fe\uff08Wright Map\uff09", lang))

    if (identical(audience, "stat")) {
        add("h2", irtc_tr("Item parameters", "\u9898\u76ee\u53c2\u6570", lang))
        params <- tryCatch(irtc_param_table(mod, resp=resp),
            error=function(e) NULL)
        if (!is.null(params)) add("table", params,
            irtc_tr(paste0("IRT item parameters (linking schema v",
                    irtc_excel_schema_version, ")"),
                paste0("IRT \u9898\u76ee\u53c2\u6570\uff08\u94fe\u63a5\u8868\u7ed3\u6784 v",
                    irtc_excel_schema_version, "\uff09"), lang))
        fig <- irtc_report_figure(irtc_plot_icc(mod, lang=lang),
            width=1050, height=900)
        if (!is.null(fig)) add("img", fig,
            irtc_tr("Item characteristic curves (first 12 items)",
                "\u9898\u76ee\u7279\u5f81\u66f2\u7ebf\uff08\u524d 12 \u9898\uff09", lang))
    }

    ## model diagnostics + data transparency (all non-decision audiences)
    detail <- identical(audience, "stat")
    for (bl in irtc_report_diagnostics_blocks(mod, resp, lang,
        detail=detail)) add(bl$type, bl$value, bl$caption)
    for (bl in irtc_report_transparency_blocks(mod, lang, detail=detail))
        add(bl$type, bl$value, bl$caption)

    add("h2", sections$next_steps$title)
    for (p in sections$next_steps$body) add("p", p)
    blocks
}

## ---------------------------------------------------------------------------
## HTML writer (self-contained, no pandoc)
## ---------------------------------------------------------------------------

irtc_html_escape <- function(x)
{
    x <- gsub("&", "&amp;", x, fixed=TRUE)
    x <- gsub("<", "&lt;", x, fixed=TRUE)
    gsub(">", "&gt;", x, fixed=TRUE)
}

irtc_html_table <- function(df)
{
    head_cells <- paste0("<th>", irtc_html_escape(colnames(df)), "</th>",
        collapse="")
    rows <- vapply(seq_len(nrow(df)), function(i) {
        cells <- vapply(seq_along(df), function(j) {
            val <- df[i, j]
            val <- if (is.na(val)) "" else as.character(val)
            paste0("<td>", irtc_html_escape(val), "</td>")
        }, character(1L))
        paste0("<tr>", paste0(cells, collapse=""), "</tr>")
    }, character(1L))
    paste0("<table><thead><tr>", head_cells, "</tr></thead><tbody>",
        paste0(rows, collapse="\n"), "</tbody></table>")
}

irtc_base64_encode <- function(raw_vec)
{
    chars <- c(LETTERS, letters, as.character(0:9), "+", "/")
    n <- length(raw_vec)
    if (n == 0L) return("")
    pad <- (3L - n %% 3L) %% 3L
    raw_vec <- c(raw_vec, as.raw(rep(0L, pad)))
    m <- matrix(as.integer(raw_vec), nrow=3L)
    idx <- rbind(
        m[1L, ] %/% 4L,
        (m[1L, ] %% 4L) * 16L + m[2L, ] %/% 16L,
        (m[2L, ] %% 16L) * 4L + m[3L, ] %/% 64L,
        m[3L, ] %% 64L
    )
    s <- paste0(chars[idx + 1L], collapse="")
    if (pad > 0L) {
        s <- paste0(substr(s, 1L, nchar(s) - pad),
            paste(rep("=", pad), collapse=""))
    }
    s
}

irtc_report_write_html <- function(blocks, file, lang)
{
    css <- paste(
        "body{font-family:'Helvetica Neue',Arial,'Microsoft YaHei',",
        "'PingFang SC',sans-serif;max-width:900px;margin:2em auto;",
        "padding:0 1em;color:#222;line-height:1.6}",
        "h1{border-bottom:3px solid #3B6FB6;padding-bottom:.3em}",
        "h2{color:#3B6FB6;margin-top:1.6em}",
        "table{border-collapse:collapse;width:100%;margin:1em 0;",
        "font-size:.9em}",
        "th{background:#D9E2F3;text-align:left}",
        "th,td{border:1px solid #bbb;padding:.35em .6em}",
        "tr:nth-child(even){background:#f6f8fb}",
        "img{max-width:100%;margin:.8em 0}",
        "figcaption{color:#666;font-size:.85em}", sep="")
    out <- c("<!DOCTYPE html>",
        paste0("<html lang=\"", if (identical(lang, "zh")) "zh-CN" else
            "en", "\"><head><meta charset=\"utf-8\">"),
        paste0("<title>", irtc_html_escape(blocks[[1L]]$value),
            "</title>"),
        paste0("<style>", css, "</style></head><body>"))
    for (block in blocks) {
        out <- c(out, switch(block$type,
            h1=paste0("<h1>", irtc_html_escape(block$value), "</h1>"),
            h2=paste0("<h2>", irtc_html_escape(block$value), "</h2>"),
            p=paste0("<p>", irtc_html_escape(block$value), "</p>"),
            table={
                cap <- if (!is.null(block$caption)) {
                    paste0("<figcaption>",
                        irtc_html_escape(block$caption), "</figcaption>")
                } else ""
                paste0("<figure>", cap, irtc_html_table(block$value),
                    "</figure>")
            },
            img={
                b64 <- irtc_base64_encode(readBin(block$value, "raw",
                    file.info(block$value)$size))
                cap <- if (!is.null(block$caption)) {
                    paste0("<figcaption>",
                        irtc_html_escape(block$caption), "</figcaption>")
                } else ""
                paste0("<figure><img src=\"data:image/png;base64,", b64,
                    "\" alt=\"\">", cap, "</figure>")
            }))
    }
    out <- c(out, "</body></html>")
    con <- file(file, open="w", encoding="UTF-8")
    on.exit(close(con))
    writeLines(out, con, useBytes=FALSE)
    invisible(file)
}

## ---------------------------------------------------------------------------
## Word writer (officer, Suggests)
## ---------------------------------------------------------------------------

irtc_report_write_docx <- function(blocks, file)
{
    doc <- officer::read_docx()
    for (block in blocks) {
        doc <- switch(block$type,
            h1=officer::body_add_par(doc, block$value, style="heading 1"),
            h2=officer::body_add_par(doc, block$value, style="heading 2"),
            p=officer::body_add_par(doc, block$value, style="Normal"),
            table={
                d <- officer::body_add_table(doc, block$value)
                if (!is.null(block$caption)) {
                    d <- officer::body_add_par(d, block$caption,
                        style="Normal")
                }
                d
            },
            img={
                d <- officer::body_add_img(doc, block$value, width=6,
                    height=4.2)
                if (!is.null(block$caption)) {
                    d <- officer::body_add_par(d, block$caption,
                        style="Normal")
                }
                d
            })
    }
    print(doc, target=file)
    invisible(file)
}
