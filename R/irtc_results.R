# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_results.R
## Part of the IRTC package
## Machine-readable results with a stable, documented schema, aimed at
## automated callers (pipelines, AI agents). Column names are fixed English
## snake_case identifiers and never depend on the language option.
## Schema version: irtc_results_schema_version.

irtc_results_schema_version <- "1.0"

irtc_results <- function(mod, resp=NULL)
{
    if (!inherits(mod, "irtc")) {
        irtc_stop(code="E401",
            en="'mod' must be an irtc model object (from irtc() or irtc.mml).",
            zh="\u53c2\u6570 'mod' \u5fc5\u987b\u662f irtc \u6a21\u578b\u5bf9\u8c61\uff08\u7531 irtc() \u6216 irtc.mml \u4ea7\u751f\uff09\u3002",
            fix_en="Fit a model first, e.g. mod <- irtc(data, model=\"1PL\").",
            fix_zh="\u8bf7\u5148\u4f30\u8ba1\u6a21\u578b\uff0c\u4f8b\u5982 mod <- irtc(data, model=\"1PL\")\u3002",
            class="irtc_error_input")
    }
    if (is.null(resp)) resp <- mod$resp

    ## --- model_info (one row) ------------------------------------------------
    rel <- suppressWarnings(mean(unlist(mod$EAP.rel), na.rm=TRUE))
    if (!is.finite(rel)) rel <- NA_real_
    model_info <- data.frame(
        schema_version=irtc_results_schema_version,
        package_version=as.character(utils::packageVersion("IRTC")),
        model=if (!is.null(mod$usability$model)) mod$usability$model else
            mod$irtmodel,
        n_persons=mod$nstud,
        n_items=mod$nitems,
        n_dimensions=mod$ndim,
        deviance=round(mod$deviance, 4),
        n_parameters=mod$ic$Npars,
        aic=round(mod$ic$AIC, 4),
        bic=round(mod$ic$BIC, 4),
        eap_reliability=round(rel, 4),
        iterations=mod$iter,
        stringsAsFactors=FALSE
    )

    ## --- items ---------------------------------------------------------------
    items <- tryCatch(irtc_param_table(mod, resp=resp),
        error=function(e) NULL)
    if (!is.null(items)) {
        items$schema_version <- NULL
        items$analysis_id <- NULL
        quality <- mod$usability$quality
        if (is.null(quality) && !is.null(resp)) {
            quality <- tryCatch(irtc_quality(mod, resp=resp),
                error=function(e) NULL)
        }
        if (!is.null(quality)) {
            extra <- data.frame(
                item_id=quality$item,
                discr_ctt=quality$discr,
                outfit=quality$outfit,
                infit=quality$infit,
                rating=quality$rating,
                reasons_en=quality$reasons_en,
                reasons_zh=quality$reasons_zh,
                advice_en=quality$advice_en,
                advice_zh=quality$advice_zh,
                stringsAsFactors=FALSE
            )
            item_order <- items$item_id
            items <- merge(items, extra, by="item_id", all.x=TRUE,
                sort=FALSE)
            items <- items[match(item_order, items$item_id), , drop=FALSE]
            rownames(items) <- NULL
        }
    }

    ## --- persons ----------------------------------------------------------------
    persons <- tryCatch({
        eap <- irtc_extract_eap(mod)
        n_dim <- ncol(eap)
        pid <- if (!is.null(mod$pid)) mod$pid else seq_len(nrow(eap))
        p <- data.frame(person_id=as.character(pid),
            stringsAsFactors=FALSE)
        if (!is.null(resp)) p$n_answered <- rowSums(!is.na(resp))
        if (!is.null(mod$person$score)) p$raw_score <- mod$person$score
        if (!is.null(mod$person$max)) p$max_score <- mod$person$max
        sd_cols <- grep("^SD\\.EAP", colnames(mod$person), value=TRUE)
        for (d in seq_len(n_dim)) {
            sfx <- if (n_dim > 1L) paste0("_dim", d) else ""
            v <- eap[, d]
            p[[paste0("eap", sfx)]] <- round(v, 4)
            if (length(sd_cols) >= d) {
                p[[paste0("se", sfx)]] <- round(mod$person[[sd_cols[d]]], 4)
            }
            p[[paste0("percentile", sfx)]] <- round(100 *
                (rank(v, na.last="keep") - 0.5) / sum(!is.na(v)), 1)
            z <- (v - mean(v, na.rm=TRUE)) / stats::sd(v, na.rm=TRUE)
            p[[paste0("t_score", sfx)]] <- round(50 + 10 * z, 1)
        }
        p
    }, error=function(e) NULL)

    out <- list(
        model_info=model_info,
        items=items,
        persons=persons,
        cleaning_log=mod$usability$data_log,
        check_issues=if (!is.null(mod$usability$check))
            mod$usability$check$issues else NULL
    )
    class(out) <- "irtc_results"
    out
}

print.irtc_results <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("IRTC machine-readable results (schema v",
        "IRTC \u673a\u5668\u53ef\u8bfb\u7ed3\u679c\uff08\u7ed3\u6784\u7248\u672c v", lang),
        irtc_results_schema_version, ")\n", sep="")
    for (name in names(x)) {
        if (is.null(x[[name]])) next
        cat("  $", name, ": ", nrow(x[[name]]), " x ", ncol(x[[name]]),
            "\n", sep="")
    }
    invisible(x)
}

## JSON export (requires the optional 'jsonlite' package).
irtc_json <- function(mod, file=NULL, resp=NULL, pretty=TRUE)
{
    irtc_require("jsonlite",
        purpose_en="export JSON results",
        purpose_zh="\u5bfc\u51fa JSON \u7ed3\u679c")
    results <- if (inherits(mod, "irtc_results")) mod else
        irtc_results(mod, resp=resp)
    json <- jsonlite::toJSON(unclass(results), dataframe="rows",
        na="null", pretty=pretty, auto_unbox=TRUE)
    if (!is.null(file)) {
        con <- base::file(file, open="w", encoding="UTF-8")
        on.exit(close(con))
        writeLines(json, con)
        return(invisible(file))
    }
    json
}
