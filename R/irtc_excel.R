# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_excel.R
## Part of the IRTC package
## One call writes three separate Excel workbooks:
##   1. <prefix>_item_quality.xlsx   - plain-language item quality table
##   2. <prefix>_item_parameters.xlsx- difficulty/discrimination table with a
##                                     frozen schema for cross-year linking
##   3. <prefix>_person_ability.xlsx - flat person ability table for pasting
##                                     into a master sample sheet
## Requires the optional 'openxlsx' package (Suggests).

irtc_excel_schema_version <- "1.0"

irtc_excel <- function(mod, dir=".", prefix="IRTC", lang=irtc_lang(),
    resp=NULL, overwrite=FALSE, verbose=TRUE)
{
    if (!inherits(mod, "irtc")) {
        irtc_stop(code="E401",
            en="'mod' must be an irtc model object (from irtc() or irtc.mml).",
            zh="\u53c2\u6570 'mod' \u5fc5\u987b\u662f irtc \u6a21\u578b\u5bf9\u8c61\uff08\u7531 irtc() \u6216 irtc.mml \u4ea7\u751f\uff09\u3002",
            fix_en="Fit a model first, e.g. mod <- irtc(data, model=\"1PL\").",
            fix_zh="\u8bf7\u5148\u4f30\u8ba1\u6a21\u578b\uff0c\u4f8b\u5982 mod <- irtc(data, model=\"1PL\")\u3002",
            class="irtc_error_input")
    }
    irtc_require("openxlsx",
        purpose_en="write Excel result files",
        purpose_zh="\u5bfc\u51fa Excel \u7ed3\u679c\u6587\u4ef6")
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    if (is.null(resp)) resp <- mod$resp

    paths <- c(
        quality=file.path(dir, paste0(prefix, "_item_quality.xlsx")),
        parameters=file.path(dir, paste0(prefix, "_item_parameters.xlsx")),
        ability=file.path(dir, paste0(prefix, "_person_ability.xlsx"))
    )
    exists_already <- paths[file.exists(paths)]
    if (!overwrite && length(exists_already) > 0L) {
        irtc_stop(code="E501",
            en=paste0("Output file(s) already exist: ",
                paste(basename(exists_already), collapse=", "), "."),
            zh=paste0("\u8f93\u51fa\u6587\u4ef6\u5df2\u5b58\u5728\uff1a",
                paste(basename(exists_already), collapse="\u3001"), "\u3002"),
            fix_en="Use overwrite=TRUE, or change 'dir'/'prefix'.",
            fix_zh="\u8bf7\u4f7f\u7528 overwrite=TRUE\uff0c\u6216\u66f4\u6362 'dir'/'prefix'\u3002",
            class="irtc_error_export", data=list(paths=exists_already))
    }

    irtc_excel_quality(mod, paths[["quality"]], lang=lang, resp=resp)
    irtc_excel_parameters(mod, paths[["parameters"]], lang=lang, resp=resp)
    irtc_excel_ability(mod, paths[["ability"]], lang=lang)

    if (verbose) {
        message(irtc_tr(
            paste0("Wrote 3 Excel files to '", normalizePath(dir), "'."),
            paste0("\u5df2\u5728 '", normalizePath(dir),
                "' \u751f\u6210 3 \u4e2a Excel \u6587\u4ef6\u3002"), lang))
    }
    invisible(paths)
}

## ---------------------------------------------------------------------------
## Shared styling helpers
## ---------------------------------------------------------------------------

irtc_excel_write_sheet <- function(wb, sheet, data, freeze=TRUE)
{
    openxlsx::addWorksheet(wb, sheet)
    header_style <- openxlsx::createStyle(textDecoration="bold",
        fgFill="#D9E2F3", border="bottom", halign="center")
    openxlsx::writeData(wb, sheet, data, headerStyle=header_style,
        withFilter=TRUE)
    if (freeze) {
        openxlsx::freezePane(wb, sheet, firstRow=TRUE)
    }
    widths <- pmin(pmax(nchar(colnames(data)) * 1.6, 10), 50)
    openxlsx::setColWidths(wb, sheet, cols=seq_along(data), widths=widths)
    invisible(wb)
}

irtc_excel_notes_sheet <- function(wb, notes, lang)
{
    sheet <- irtc_tr("Notes", "\u8bf4\u660e", lang)
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, notes)
    openxlsx::setColWidths(wb, sheet, cols=c(1, 2), widths=c(24, 90))
    invisible(wb)
}

irtc_difficulty_label <- function(pvalue, lang)
{
    vapply(pvalue, function(p) {
        if (is.na(p)) return(irtc_tr("unknown", "\u672a\u77e5", lang))
        if (p > 0.85) {
            irtc_tr("easy", "\u5bb9\u6613", lang)
        } else if (p >= 0.50) {
            irtc_tr("moderate", "\u9002\u4e2d", lang)
        } else if (p >= 0.25) {
            irtc_tr("hard", "\u8f83\u96be", lang)
        } else {
            irtc_tr("very hard", "\u5f88\u96be", lang)
        }
    }, character(1L))
}

irtc_discr_label <- function(discr, lang)
{
    vapply(discr, function(r) {
        if (is.na(r)) return(irtc_tr("unknown", "\u672a\u77e5", lang))
        if (r < 0) {
            irtc_tr("negative - check the item!",
                "\u4e3a\u8d1f\u2014\u2014\u8bf7\u6392\u67e5\uff01", lang)
        } else if (r < 0.15) {
            irtc_tr("poor", "\u5f88\u4f4e", lang)
        } else if (r < 0.25) {
            irtc_tr("weak", "\u504f\u4f4e", lang)
        } else if (r < 0.40) {
            irtc_tr("good", "\u826f\u597d", lang)
        } else {
            irtc_tr("excellent", "\u5f88\u597d", lang)
        }
    }, character(1L))
}

## ---------------------------------------------------------------------------
## 1. Item quality workbook (plain language)
## ---------------------------------------------------------------------------

irtc_excel_quality <- function(mod, path, lang, resp)
{
    quality <- mod$usability$quality
    if (is.null(quality)) {
        if (is.null(resp)) {
            irtc_stop(code="E402",
                en=paste0("The model object stores neither quality results",
                    " nor response data; supply 'resp'."),
                zh=paste0("\u6a21\u578b\u5bf9\u8c61\u4e2d\u65e2\u65e0\u8d28\u91cf\u7ed3\u679c\u4e5f\u65e0\u4f5c\u7b54\u6570\u636e\uff1b",
                    "\u8bf7\u63d0\u4f9b 'resp' \u53c2\u6570\u3002"),
                fix_en="Call irtc_excel(mod, resp=your_data).",
                fix_zh="\u8bf7\u8c03\u7528 irtc_excel(mod, resp=\u4f60\u7684\u6570\u636e)\u3002",
                class="irtc_error_input")
        }
        quality <- irtc_quality(mod, resp=resp)
    }

    tbl <- data.frame(
        a=quality$item,
        b=quality$N,
        c=round(100 * quality$pvalue, 1),
        d=irtc_difficulty_label(quality$pvalue, lang),
        e=quality$discr,
        f=irtc_discr_label(quality$discr, lang),
        g=quality$outfit,
        h=quality$infit,
        i=irtc_quality_rating_label(quality$rating, lang),
        j=if (identical(lang, "zh")) quality$reasons_zh else
            quality$reasons_en,
        k=if (identical(lang, "zh")) quality$advice_zh else
            quality$advice_en,
        stringsAsFactors=FALSE
    )
    colnames(tbl) <- c(
        irtc_tr("Item", "\u9898\u53f7", lang),
        irtc_tr("N answered", "\u4f5c\u7b54\u4eba\u6570", lang),
        irtc_tr("Score rate (%)", "\u5f97\u5206\u7387(%)", lang),
        irtc_tr("Difficulty", "\u96be\u5ea6\u8bc4\u4ef7", lang),
        irtc_tr("Discrimination", "\u533a\u5206\u5ea6", lang),
        irtc_tr("Discrimination level", "\u533a\u5206\u5ea6\u8bc4\u4ef7", lang),
        irtc_tr("Fit (outfit)", "\u62df\u5408(outfit)", lang),
        irtc_tr("Fit (infit)", "\u62df\u5408(infit)", lang),
        irtc_tr("Overall rating", "\u8d28\u91cf\u8bc4\u7ea7", lang),
        irtc_tr("Reasons", "\u539f\u56e0", lang),
        irtc_tr("Advice", "\u5904\u7406\u5efa\u8bae", lang)
    )

    wb <- openxlsx::createWorkbook()
    sheet <- irtc_tr("Item quality", "\u9898\u76ee\u8d28\u91cf", lang)
    irtc_excel_write_sheet(wb, sheet, tbl)

    ## colour the rating column by level
    fills <- c(good="#C6EFCE", acceptable="#E2EFDA", review="#FFEB9C",
        revise="#FFC7CE")
    rating_col <- 9L
    for (i in seq_len(nrow(quality))) {
        style <- openxlsx::createStyle(fgFill=fills[[quality$rating[i]]])
        openxlsx::addStyle(wb, sheet, style, rows=i + 1L, cols=rating_col,
            stack=TRUE)
    }

    th <- attr(quality, "thresholds")
    if (is.null(th)) th <- irtc_quality_thresholds()
    notes <- data.frame(
        x=c(
            irtc_tr("Score rate (%)", "\u5f97\u5206\u7387(%)", lang),
            irtc_tr("Discrimination", "\u533a\u5206\u5ea6", lang),
            irtc_tr("Fit (outfit/infit)", "\u62df\u5408(outfit/infit)", lang),
            irtc_tr("Overall rating", "\u8d28\u91cf\u8bc4\u7ea7", lang),
            "Cronbach alpha"
        ),
        y=c(
            irtc_tr(paste0("Average score as % of the maximum; near 100%",
                    " everyone answers correctly, near 0% almost no one",
                    " does. Flagged below ", 100 * th$p_hard,
                    "% or above ", 100 * th$p_easy, "%."),
                paste0("\u5e73\u5747\u5f97\u5206\u5360\u6ee1\u5206\u7684\u767e\u5206\u6bd4\uff1b\u63a5\u8fd1 100% \u8bf4\u660e\u4eba\u4eba\u90fd\u5bf9\uff0c",
                    "\u63a5\u8fd1 0% \u8bf4\u660e\u51e0\u4e4e\u6ca1\u4eba\u5bf9\u3002\u4f4e\u4e8e ", 100 * th$p_hard,
                    "% \u6216\u9ad8\u4e8e ", 100 * th$p_easy, "% \u4f1a\u88ab\u6807\u8bb0\u3002"), lang),
            irtc_tr(paste0("Correlation between this item and the rest of",
                    " the test. Higher is better; negative usually means a",
                    " wrong key. Flagged below ", th$discr_weak, "."),
                paste0("\u8be5\u9898\u4e0e\u5176\u4f59\u9898\u76ee\u603b\u5206\u7684\u76f8\u5173\u3002\u6570\u503c\u8d8a\u9ad8\u8d8a\u597d\uff1b\u4e3a\u8d1f\u901a\u5e38",
                    "\u610f\u5473\u7740\u7b54\u6848\u952e\u9519\u8bef\u3002\u4f4e\u4e8e ", th$discr_weak,
                    " \u4f1a\u88ab\u6807\u8bb0\u3002"), lang),
            irtc_tr(paste0("How well responses follow the model; ideal is",
                    " 1.0, normal range ", th$fit_mild[1L], " to ",
                    th$fit_mild[2L], "."),
                paste0("\u4f5c\u7b54\u4e0e\u6a21\u578b\u9884\u671f\u7684\u543b\u5408\u7a0b\u5ea6\uff1b\u7406\u60f3\u503c\u4e3a 1.0\uff0c\u6b63\u5e38\u8303\u56f4 ",
                    th$fit_mild[1L], " \u81f3 ", th$fit_mild[2L], "\u3002"), lang),
            irtc_tr(paste0("Good = keep; Acceptable = usable; Review = ",
                    "inspect the item; Revise = fix or replace before",
                    " reuse."),
                paste0("\u201c\u597d\u201d=\u653e\u5fc3\u4f7f\u7528\uff1b\u201c\u53ef\u7528\u201d=\u53ef\u4ee5\u4f7f\u7528\uff1b\u201c\u9700\u68c0\u67e5\u201d=\u8bf7\u4eba\u5de5",
                    "\u590d\u6838\u8be5\u9898\uff1b\u201c\u5efa\u8bae\u4fee\u6539\u201d=\u91cd\u590d\u4f7f\u7528\u524d\u5e94\u4fee\u6539\u6216\u66ff\u6362\u3002"), lang),
            irtc_tr(paste0("Internal consistency of the whole test: ",
                    ifelse(is.na(attr(quality, "alpha")), "NA",
                        attr(quality, "alpha")), "."),
                paste0("\u6574\u5377\u5185\u90e8\u4e00\u81f4\u6027\u4fe1\u5ea6\uff1a",
                    ifelse(is.na(attr(quality, "alpha")), "\u65e0\u6cd5\u8ba1\u7b97",
                        attr(quality, "alpha")), "\u3002"), lang)
        ), stringsAsFactors=FALSE
    )
    colnames(notes) <- c(irtc_tr("Column", "\u680f\u76ee", lang),
        irtc_tr("How to read it", "\u5982\u4f55\u7406\u89e3", lang))
    irtc_excel_notes_sheet(wb, notes, lang)
    openxlsx::saveWorkbook(wb, path, overwrite=TRUE)
    invisible(path)
}

## ---------------------------------------------------------------------------
## 2. Item parameter workbook (frozen schema for cross-year linking)
## ---------------------------------------------------------------------------

irtc_param_table <- function(mod, resp=NULL)
{
    AXsi <- irtc_extract_axsi(mod)
    B <- mod$B
    n_items <- dim(B)[1L]
    maxK <- dim(B)[2L]
    alpha <- B[, 2L, 1L]
    item_names <- if (!is.null(resp)) colnames(resp) else
        if (!is.null(mod$item$item)) as.character(mod$item$item) else
        paste0("I", seq_len(n_items))
    if (length(item_names) != n_items) {
        item_names <- paste0("I", seq_len(n_items))
    }
    se_axsi <- mod$se.AXsi
    intercepts <- -AXsi   # beta parameterisation

    beta <- rep(NA_real_, n_items)
    se_beta <- rep(NA_real_, n_items)
    ## polytomous items have up to maxK-1 step thresholds; dichotomous
    ## data sets get no tau columns at all
    tau <- matrix(NA_real_, n_items, if (maxK > 2L) maxK - 1L else 0L)
    for (j in seq_len(n_items)) {
        xsi_irt <- intercepts[j, ] / alpha[j]
        k_max <- sum(!is.na(xsi_irt)) - 1L
        if (k_max < 1L) next
        beta[j] <- xsi_irt[k_max + 1L] / k_max
        if (!is.null(se_axsi) && !all(is.na(se_axsi))) {
            se_beta[j] <- se_axsi[j, k_max + 1L] / (abs(alpha[j]) * k_max)
        }
        if (k_max > 1L) {
            for (k in seq_len(k_max)) {
                tau[j, k] <- xsi_irt[k + 1L] - beta[j] - xsi_irt[k]
            }
        }
    }

    n_obs <- if (!is.null(resp)) colSums(!is.na(resp)) else
        if (!is.null(mod$item$N)) mod$item$N else rep(NA_integer_, n_items)
    pvalue <- if (!is.null(resp)) {
        vapply(as.data.frame(resp), function(col) {
            vals <- col[!is.na(col)]
            if (length(vals) == 0L || max(vals) == 0) NA_real_ else
                mean(vals) / max(vals)
        }, numeric(1L))
    } else rep(NA_real_, n_items)

    out <- data.frame(
        schema_version=irtc_excel_schema_version,
        analysis_id=format(Sys.time(), "%Y%m%d%H%M%S"),
        model=if (!is.null(mod$usability$model)) mod$usability$model else
            mod$irtmodel,
        item_id=item_names,
        n_obs=n_obs,
        p_value=round(pvalue, 4),
        slope_a=round(alpha, 4),
        difficulty_b=round(beta, 4),
        se_b=round(se_beta, 4),
        stringsAsFactors=FALSE, row.names=NULL
    )
    if (ncol(tau) > 0L) {
        tau <- round(tau, 4)
        colnames(tau) <- paste0("tau_", seq_len(ncol(tau)))
        out <- cbind(out, tau)
    }
    out
}

irtc_excel_parameters <- function(mod, path, lang, resp)
{
    tbl <- irtc_param_table(mod, resp=resp)
    wb <- openxlsx::createWorkbook()
    irtc_excel_write_sheet(wb, "item_parameters", tbl)

    notes <- data.frame(
        x=c("schema_version", "analysis_id", "model", "item_id", "n_obs",
            "p_value", "slope_a", "difficulty_b", "se_b", "tau_k"),
        y=c(
            irtc_tr(paste0("Fixed layout version (",
                    irtc_excel_schema_version, "). Columns never change",
                    " within a major version, so files from different",
                    " years can be merged directly."),
                paste0("\u8868\u7ed3\u6784\u7248\u672c\uff08", irtc_excel_schema_version,
                    "\uff09\u3002\u540c\u4e00\u4e3b\u7248\u672c\u5185\u5217\u7ed3\u6784\u6c38\u4e0d\u53d8\u5316\uff0c\u4e0d\u540c\u5e74\u5ea6\u7684\u6587\u4ef6",
                    "\u53ef\u76f4\u63a5\u5408\u5e76\u3002"), lang),
            irtc_tr("Time stamp of this analysis (yyyymmddHHMMSS).",
                "\u672c\u6b21\u5206\u6790\u7684\u65f6\u95f4\u6233\uff08yyyymmddHHMMSS\uff09\u3002", lang),
            irtc_tr("IRT model used for calibration.",
                "\u6807\u5b9a\u6240\u7528\u7684 IRT \u6a21\u578b\u3002", lang),
            irtc_tr(paste0("Item identifier. Use identical ids for anchor",
                    " items across years to enable linking."),
                paste0("\u9898\u76ee\u6807\u8bc6\u3002\u8de8\u5e74\u5ea6\u951a\u9898\u8bf7\u4f7f\u7528\u5b8c\u5168\u4e00\u81f4\u7684\u9898\u76ee\u6807\u8bc6\uff0c",
                    "\u4ee5\u4fbf\u94fe\u63a5\u7b49\u503c\u3002"), lang),
            irtc_tr("Number of valid responses.", "\u6709\u6548\u4f5c\u7b54\u4eba\u6570\u3002", lang),
            irtc_tr("Classical difficulty (share of maximum score).",
                "\u7ecf\u5178\u96be\u5ea6\uff08\u5e73\u5747\u5f97\u5206\u5360\u6ee1\u5206\u6bd4\u4f8b\uff09\u3002", lang),
            irtc_tr(paste0("IRT discrimination a. Fixed to a common value",
                    " in 1PL/PCM/RSM; estimated in 2PL/GPCM."),
                paste0("IRT \u533a\u5206\u5ea6 a\u30021PL/PCM/RSM \u4e2d\u4e3a\u516c\u5171\u5e38\u6570\uff0c",
                    "2PL/GPCM \u4e2d\u4e3a\u4f30\u8ba1\u503c\u3002"), lang),
            irtc_tr(paste0("IRT difficulty b (item location, logit scale).",
                    " Compare anchors across years on this column."),
                paste0("IRT \u96be\u5ea6 b\uff08\u9898\u76ee\u4f4d\u7f6e\uff0clogit \u91cf\u5c3a\uff09\u3002\u8de8\u5e74\u5ea6\u951a\u9898",
                    "\u6bd4\u8f83\u8bf7\u4f7f\u7528\u672c\u5217\u3002"), lang),
            irtc_tr(paste0("Approximate standard error of b (slope treated",
                    " as fixed)."),
                "b \u7684\u8fd1\u4f3c\u6807\u51c6\u8bef\uff08\u5c06\u533a\u5206\u5ea6\u89c6\u4e3a\u56fa\u5b9a\uff09\u3002", lang),
            irtc_tr("Step thresholds for polytomous items (centred).",
                "\u591a\u7ea7\u8ba1\u5206\u9898\u7684\u6b65\u9aa4\u9608\u503c\uff08\u4e2d\u5fc3\u5316\uff09\u3002", lang)
        ), stringsAsFactors=FALSE
    )
    colnames(notes) <- c(irtc_tr("Column", "\u680f\u76ee", lang),
        irtc_tr("Meaning", "\u542b\u4e49", lang))
    irtc_excel_notes_sheet(wb, notes, lang)
    openxlsx::saveWorkbook(wb, path, overwrite=TRUE)
    invisible(path)
}

## ---------------------------------------------------------------------------
## 3. Person ability workbook (flat, paste-ready)
## ---------------------------------------------------------------------------

irtc_person_table <- function(mod, lang=irtc_lang())
{
    person <- mod$person
    eap <- irtc_extract_eap(mod)
    n_dim <- ncol(eap)
    pid <- if (!is.null(mod$pid)) mod$pid else person$pid
    if (is.null(pid)) pid <- seq_len(nrow(eap))

    out <- data.frame(pid=as.character(pid), stringsAsFactors=FALSE)
    if (!is.null(mod$resp)) {
        out[[irtc_tr("n_answered", "\u4f5c\u7b54\u9898\u6570", lang)]] <-
            rowSums(!is.na(mod$resp))
    }
    if (!is.null(person$score)) {
        out[[irtc_tr("raw_score", "\u539f\u59cb\u603b\u5206", lang)]] <- person$score
    }
    if (!is.null(person$max)) {
        out[[irtc_tr("max_score", "\u6ee1\u5206", lang)]] <- person$max
    }
    sd_cols <- grep("^SD\\.EAP", colnames(person), value=TRUE)
    for (d in seq_len(n_dim)) {
        dim_suffix <- if (n_dim > 1L) paste0("_dim", d) else ""
        v <- eap[, d]
        out[[paste0(irtc_tr("ability_EAP", "\u80fd\u529b\u503cEAP", lang),
            dim_suffix)]] <- round(v, 4)
        if (length(sd_cols) >= d) {
            out[[paste0(irtc_tr("SE", "\u6807\u51c6\u8bef", lang), dim_suffix)]] <-
                round(person[[sd_cols[d]]], 4)
        }
        pct <- round(100 * (rank(v, na.last="keep") - 0.5) /
            sum(!is.na(v)), 1)
        out[[paste0(irtc_tr("percentile", "\u767e\u5206\u4f4d", lang),
            dim_suffix)]] <- pct
        z <- (v - mean(v, na.rm=TRUE)) / stats::sd(v, na.rm=TRUE)
        out[[paste0(irtc_tr("T_score", "T\u5206\u6570", lang), dim_suffix)]] <-
            round(50 + 10 * z, 1)
    }
    names(out)[1L] <- irtc_tr("person_id", "\u4e2a\u6848ID", lang)
    out
}

irtc_excel_ability <- function(mod, path, lang)
{
    tbl <- irtc_person_table(mod, lang=lang)
    wb <- openxlsx::createWorkbook()
    sheet <- irtc_tr("Person ability", "\u6837\u672c\u80fd\u529b\u503c", lang)
    irtc_excel_write_sheet(wb, sheet, tbl)

    notes <- data.frame(
        x=c(irtc_tr("ability_EAP", "\u80fd\u529b\u503cEAP", lang),
            irtc_tr("SE", "\u6807\u51c6\u8bef", lang),
            irtc_tr("percentile", "\u767e\u5206\u4f4d", lang),
            irtc_tr("T_score", "T\u5206\u6570", lang)),
        y=c(
            irtc_tr(paste0("Ability estimate on the logit scale; 0 is",
                    " average, higher is stronger. Rows are in the same",
                    " order as the input data, so the table can be pasted",
                    " next to the master sample sheet."),
                paste0("logit \u91cf\u5c3a\u4e0a\u7684\u80fd\u529b\u4f30\u8ba1\u503c\uff1b0 \u4e3a\u5e73\u5747\u6c34\u5e73\uff0c\u8d8a\u5927\u8d8a\u5f3a\u3002",
                    "\u884c\u987a\u5e8f\u4e0e\u8f93\u5165\u6570\u636e\u4e00\u81f4\uff0c\u53ef\u76f4\u63a5\u7c98\u8d34\u5230\u603b\u6837\u672c\u8868\u65c1\u8fb9\u3002"),
                lang),
            irtc_tr("Uncertainty of the ability estimate.",
                "\u80fd\u529b\u4f30\u8ba1\u503c\u7684\u4e0d\u786e\u5b9a\u5ea6\u3002", lang),
            irtc_tr("Share of persons at or below this ability (0-100).",
                "\u80fd\u529b\u4e0d\u9ad8\u4e8e\u8be5\u6837\u672c\u7684\u4eba\u6570\u767e\u5206\u6bd4\uff080-100\uff09\u3002", lang),
            irtc_tr("Ability rescaled to mean 50, SD 10.",
                "\u6362\u7b97\u4e3a\u5747\u503c 50\u3001\u6807\u51c6\u5dee 10 \u7684\u5206\u6570\u3002", lang)
        ), stringsAsFactors=FALSE
    )
    colnames(notes) <- c(irtc_tr("Column", "\u680f\u76ee", lang),
        irtc_tr("Meaning", "\u542b\u4e49", lang))
    irtc_excel_notes_sheet(wb, notes, lang)
    openxlsx::saveWorkbook(wb, path, overwrite=TRUE)
    invisible(path)
}
