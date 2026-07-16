# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: plain_summary.R
## Part of the IRTC package
## Layered plain-language summary of a fitted model: conclusion first, then
## details. The section builder irtc_summary_texts() is shared with the
## report generator (irtc_report).

plain_summary <- function(mod, lang=irtc_lang())
{
    sections <- irtc_summary_texts(mod, lang=lang)
    rule <- paste(rep("-", 60), collapse="")
    for (sec in sections) {
        cat(rule, "\n", sec$title, "\n", rule, "\n", sep="")
        for (p in sec$body) cat(p, "\n")
        cat("\n")
    }
    invisible(sections)
}

## Interpret an EAP reliability value in words.
irtc_reliability_label <- function(rel, lang=irtc_lang())
{
    if (is.na(rel)) return(irtc_tr("not available", "\u65e0\u6cd5\u8ba1\u7b97", lang))
    if (rel >= 0.9) {
        irtc_tr("excellent", "\u975e\u5e38\u597d", lang)
    } else if (rel >= 0.8) {
        irtc_tr("good", "\u826f\u597d", lang)
    } else if (rel >= 0.7) {
        irtc_tr("acceptable", "\u5c1a\u53ef", lang)
    } else {
        irtc_tr("low - interpret individual scores with caution",
            "\u504f\u4f4e \u2014\u2014 \u89e3\u8bfb\u4e2a\u4eba\u5206\u6570\u65f6\u9700\u8c28\u614e", lang)
    }
}

irtc_model_label <- function(model, lang=irtc_lang())
{
    labels <- list(
        "1PL"=c(en="Rasch / one-parameter logistic model (1PL)",
            zh="Rasch/\u5355\u53c2\u6570\u6a21\u578b\uff081PL\uff09"),
        "PCM"=c(en="partial credit model (PCM)", zh="\u90e8\u5206\u8ba1\u5206\u6a21\u578b\uff08PCM\uff09"),
        "PCM2"=c(en="partial credit model (PCM2 parameterisation)",
            zh="\u90e8\u5206\u8ba1\u5206\u6a21\u578b\uff08PCM2 \u53c2\u6570\u5316\uff09"),
        "RSM"=c(en="rating scale model (RSM)", zh="\u8bc4\u5b9a\u91cf\u8868\u6a21\u578b\uff08RSM\uff09"),
        "2PL"=c(en="two-parameter logistic model (2PL)",
            zh="\u53cc\u53c2\u6570\u6a21\u578b\uff082PL\uff09"),
        "GPCM"=c(en="generalised partial credit model (GPCM)",
            zh="\u5e7f\u4e49\u90e8\u5206\u8ba1\u5206\u6a21\u578b\uff08GPCM\uff09")
    )
    lab <- labels[[model]]
    if (is.null(lab)) model else unname(lab[[lang]])
}

## Build the bilingual summary sections. Returns a list of
## list(title=..., body=character vector) elements.
irtc_summary_texts <- function(mod, lang=irtc_lang())
{
    if (!inherits(mod, "irtc")) {
        irtc_stop(code="E401",
            en="'mod' must be an irtc model object (from irtc() or irtc.mml).",
            zh="\u53c2\u6570 'mod' \u5fc5\u987b\u662f irtc \u6a21\u578b\u5bf9\u8c61\uff08\u7531 irtc() \u6216 irtc.mml \u4ea7\u751f\uff09\u3002",
            fix_en="Fit a model first, e.g. mod <- irtc(data, model=\"1PL\").",
            fix_zh="\u8bf7\u5148\u4f30\u8ba1\u6a21\u578b\uff0c\u4f8b\u5982 mod <- irtc(data, model=\"1PL\")\u3002",
            class="irtc_error_input")
    }
    n_persons <- mod$nstud
    n_items <- mod$nitems
    model <- if (!is.null(mod$usability$model)) mod$usability$model else
        mod$irtmodel
    rel <- suppressWarnings(mean(unlist(mod$EAP.rel), na.rm=TRUE))
    if (!is.finite(rel)) rel <- NA_real_
    quality <- mod$usability$quality
    if (is.null(quality) && !is.null(mod$resp)) {
        quality <- tryCatch(irtc_quality(mod), error=function(e) NULL)
    }
    eap <- tryCatch(irtc_extract_eap(mod), error=function(e) NULL)

    sections <- list()

    ## 1. conclusion ---------------------------------------------------------
    concl <- character(0)
    rel_label <- irtc_reliability_label(rel, lang)
    if (!is.null(quality)) {
        n_ok <- sum(quality$rating %in% c("good", "acceptable"))
        concl <- c(concl, irtc_tr(
            paste0("The test measured ", n_persons, " persons with ",
                n_items, " items. Score reliability is ",
                ifelse(is.na(rel), "NA", round(rel, 2)), " (", rel_label,
                "). ", n_ok, " of ", nrow(quality),
                " items are of good or acceptable quality."),
            paste0("\u672c\u6b21\u6d4b\u9a8c\u5171 ", n_persons, " \u4eba\u4f5c\u7b54 ", n_items,
                " \u4e2a\u9898\u76ee\u3002\u5206\u6570\u4fe1\u5ea6\u4e3a ",
                ifelse(is.na(rel), "\u65e0\u6cd5\u8ba1\u7b97", round(rel, 2)), "\uff08",
                rel_label, "\uff09\u3002", nrow(quality), " \u4e2a\u9898\u76ee\u4e2d\u6709 ", n_ok,
                " \u4e2a\u8d28\u91cf\u4e3a\u201c\u597d\u201d\u6216\u201c\u53ef\u7528\u201d\u3002"), lang))
        n_bad <- sum(quality$rating == "revise")
        if (n_bad > 0L) {
            bad_names <- quality$item[quality$rating == "revise"]
            concl <- c(concl, irtc_tr(
                paste0("Attention: ", n_bad, " item(s) need revision: ",
                    paste(bad_names, collapse=", "), "."),
                paste0("\u9700\u8981\u6ce8\u610f\uff1a\u6709 ", n_bad, " \u4e2a\u9898\u76ee\u5efa\u8bae\u4fee\u6539\uff1a",
                    paste(bad_names, collapse="\u3001"), "\u3002"), lang))
        }
    } else {
        concl <- c(concl, irtc_tr(
            paste0("The test measured ", n_persons, " persons with ",
                n_items, " items. Score reliability is ",
                ifelse(is.na(rel), "NA", round(rel, 2)), " (", rel_label,
                ")."),
            paste0("\u672c\u6b21\u6d4b\u9a8c\u5171 ", n_persons, " \u4eba\u4f5c\u7b54 ", n_items,
                " \u4e2a\u9898\u76ee\u3002\u5206\u6570\u4fe1\u5ea6\u4e3a ",
                ifelse(is.na(rel), "\u65e0\u6cd5\u8ba1\u7b97", round(rel, 2)), "\uff08",
                rel_label, "\uff09\u3002"), lang))
    }
    sections$conclusion <- list(
        title=irtc_tr("Conclusion", "\u603b\u4f53\u7ed3\u8bba", lang), body=concl)

    ## 2. analysis setup -------------------------------------------------------
    setup <- c(
        irtc_tr(paste0("Model: ", irtc_model_label(model, lang), "."),
            paste0("\u4f7f\u7528\u6a21\u578b\uff1a", irtc_model_label(model, lang), "\u3002"), lang),
        irtc_tr(paste0("Persons: ", n_persons, "; items: ", n_items,
                "; latent dimensions: ", mod$ndim, "."),
            paste0("\u6837\u672c\u6570\uff1a", n_persons, "\uff1b\u9898\u76ee\u6570\uff1a", n_items,
                "\uff1b\u6f5c\u5728\u7ef4\u5ea6\u6570\uff1a", mod$ndim, "\u3002"), lang)
    )
    removed <- mod$usability$removed_items
    if (!is.null(removed) && length(removed) > 0L) {
        setup <- c(setup, irtc_tr(
            paste0("Removed before estimation (unusable): ",
                paste(removed, collapse=", "), "."),
            paste0("\u4f30\u8ba1\u524d\u5254\u9664\u7684\u65e0\u6548\u9898\u76ee\uff1a",
                paste(removed, collapse="\u3001"), "\u3002"), lang))
    }
    sections$setup <- list(
        title=irtc_tr("Analysis overview", "\u5206\u6790\u6982\u51b5", lang), body=setup)

    ## 3. item quality ----------------------------------------------------------
    if (!is.null(quality)) {
        tab <- table(factor(quality$rating,
            levels=c("good", "acceptable", "review", "revise")))
        qual_body <- irtc_tr(
            paste0("Item quality: ", tab[["good"]], " good, ",
                tab[["acceptable"]], " acceptable, ", tab[["review"]],
                " to review, ", tab[["revise"]], " to revise."),
            paste0("\u9898\u76ee\u8d28\u91cf\u5206\u5e03\uff1a\u597d ", tab[["good"]], " \u4e2a\uff0c\u53ef\u7528 ",
                tab[["acceptable"]], " \u4e2a\uff0c\u9700\u68c0\u67e5 ", tab[["review"]],
                " \u4e2a\uff0c\u5efa\u8bae\u4fee\u6539 ", tab[["revise"]], " \u4e2a\u3002"), lang)
        flagged <- quality[quality$rating %in% c("review", "revise"), ]
        details <- character(0)
        if (nrow(flagged) > 0L) {
            reasons <- if (identical(lang, "zh")) flagged$reasons_zh else
                flagged$reasons_en
            details <- paste0("  - ", flagged$item, ": ", reasons)
        }
        alpha <- attr(quality, "alpha")
        alpha_line <- irtc_tr(
            paste0("Internal consistency (Cronbach's alpha): ",
                ifelse(is.na(alpha), "NA", alpha), "."),
            paste0("\u5185\u90e8\u4e00\u81f4\u6027\uff08Cronbach's alpha\uff09\uff1a",
                ifelse(is.na(alpha), "\u65e0\u6cd5\u8ba1\u7b97", alpha), "\u3002"), lang)
        sections$quality <- list(
            title=irtc_tr("Item quality", "\u9898\u76ee\u8d28\u91cf", lang),
            body=c(qual_body, alpha_line, details))
    }

    ## 4. ability distribution ---------------------------------------------------
    if (!is.null(eap)) {
        dim_names <- colnames(eap)
        ab <- character(0)
        for (d in seq_len(ncol(eap))) {
            v <- eap[, d]
            ab <- c(ab, irtc_tr(
                paste0(if (ncol(eap) > 1L) paste0("Dimension ", d, ": ")
                    else "",
                    "mean ability ", round(mean(v, na.rm=TRUE), 2),
                    ", spread (SD) ", round(stats::sd(v, na.rm=TRUE), 2),
                    ", range ", round(min(v, na.rm=TRUE), 2), " to ",
                    round(max(v, na.rm=TRUE), 2), "."),
                paste0(if (ncol(eap) > 1L) paste0("\u7b2c ", d, " \u7ef4\uff1a"),
                    "\u80fd\u529b\u5e73\u5747\u503c ", round(mean(v, na.rm=TRUE), 2),
                    "\uff0c\u79bb\u6563\u7a0b\u5ea6\uff08\u6807\u51c6\u5dee\uff09", round(stats::sd(v, na.rm=TRUE), 2),
                    "\uff0c\u8303\u56f4 ", round(min(v, na.rm=TRUE), 2), " \u81f3 ",
                    round(max(v, na.rm=TRUE), 2), "\u3002"), lang))
        }
        ab <- c(ab, irtc_tr(
            paste0("Ability scores are on the logit scale; 0 is the",
                " population-model average, higher means stronger."),
            paste0("\u80fd\u529b\u503c\u4e3a logit \u91cf\u5c3a\uff1b0 \u4ee3\u8868\u7fa4\u4f53\u5e73\u5747\u6c34\u5e73\uff0c",
                "\u6570\u503c\u8d8a\u5927\u80fd\u529b\u8d8a\u5f3a\u3002"), lang))
        sections$ability <- list(
            title=irtc_tr("Ability distribution", "\u6837\u672c\u80fd\u529b\u5206\u5e03", lang),
            body=ab)
    }

    ## 5. next steps ---------------------------------------------------------------
    steps <- c(
        irtc_tr("Export the three Excel tables: irtc_excel(mod).",
            "\u5bfc\u51fa\u4e09\u4e2a Excel \u7ed3\u679c\u8868\uff1airtc_excel(mod)\u3002", lang),
        irtc_tr("Create a report: irtc_report(mod, \"report.docx\").",
            "\u751f\u6210\u5206\u6790\u62a5\u544a\uff1airtc_report(mod, \"report.docx\")\u3002", lang),
        irtc_tr("Full technical output: summary(mod).",
            "\u67e5\u770b\u5b8c\u6574\u6280\u672f\u7ed3\u679c\uff1asummary(mod)\u3002", lang)
    )
    sections$next_steps <- list(
        title=irtc_tr("Next steps", "\u4e0b\u4e00\u6b65", lang), body=steps)

    sections
}
