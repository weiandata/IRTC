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
        fit <- mod$usability$itemfit
        if (is.null(fit) && !is.null(resp)) {
            fit <- tryCatch(irtc_itemfit(mod, resp=resp),
                error=function(e) NULL)
        }
        if (!is.null(fit)) {
            add("h2", irtc_tr("Item fit", "\u9898\u76ee\u62df\u5408", lang))
            add("table", as.data.frame(fit))
        }
        add("h2", irtc_tr("Model information", "\u6a21\u578b\u4fe1\u606f", lang))
        ic <- mod$ic
        info <- data.frame(
            a=c("Deviance", "N parameters", "AIC", "BIC",
                irtc_tr("EAP reliability", "EAP \u4fe1\u5ea6", lang),
                irtc_tr("Iterations", "\u8fed\u4ee3\u6b21\u6570", lang)),
            b=c(round(mod$deviance, 2),
                ic$Npars,
                round(ic$AIC, 2), round(ic$BIC, 2),
                paste(round(unlist(mod$EAP.rel), 3), collapse=", "),
                mod$iter),
            stringsAsFactors=FALSE)
        colnames(info) <- c(irtc_tr("Statistic", "\u7edf\u8ba1\u91cf", lang),
            irtc_tr("Value", "\u53d6\u503c", lang))
        add("table", info)
        fig <- irtc_report_figure(irtc_plot_icc(mod, lang=lang),
            width=1050, height=900)
        if (!is.null(fig)) add("img", fig,
            irtc_tr("Item characteristic curves (first 12 items)",
                "\u9898\u76ee\u7279\u5f81\u66f2\u7ebf\uff08\u524d 12 \u9898\uff09", lang))
    }

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
