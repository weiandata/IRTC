# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_quality.R
## Part of the IRTC package
## Plain-language item quality ratings. Combines CTT difficulty and
## discrimination with IRT item fit into a four-level rating
## (good / acceptable / review / revise), each with bilingual reasons and
## advice that non-specialists can act on.

irtc_quality_thresholds <- function()
{
    list(
        p_hard=0.10,       # p-value below this: very hard
        p_easy=0.95,       # p-value above this: very easy
        discr_poor=0.15,   # item-rest correlation below this: poor
        discr_weak=0.25,   # below this: weak
        fit_mild=c(0.70, 1.30),
        fit_severe=c(0.50, 1.50)
    )
}

irtc_quality <- function(mod, resp=NULL, thresholds=NULL)
{
    if (!inherits(mod, "irtc")) {
        irtc_stop(code="E401",
            en="'mod' must be an irtc model object (from irtc() or irtc.mml).",
            zh="\u53c2\u6570 'mod' \u5fc5\u987b\u662f irtc \u6a21\u578b\u5bf9\u8c61\uff08\u7531 irtc() \u6216 irtc.mml \u4ea7\u751f\uff09\u3002",
            fix_en="Fit a model first, e.g. mod <- irtc(data, model=\"1PL\").",
            fix_zh="\u8bf7\u5148\u4f30\u8ba1\u6a21\u578b\uff0c\u4f8b\u5982 mod <- irtc(data, model=\"1PL\")\u3002",
            class="irtc_error_input")
    }
    th <- irtc_quality_thresholds()
    if (!is.null(thresholds)) {
        th[names(thresholds)] <- thresholds
    }
    if (is.null(resp)) resp <- mod$resp
    if (is.null(resp)) {
        irtc_stop(code="E402",
            en=paste0("The model object does not store the response data",
                " (streaming engine); supply it via the 'resp' argument."),
            zh=paste0("\u6a21\u578b\u5bf9\u8c61\u4e2d\u6ca1\u6709\u4fdd\u5b58\u4f5c\u7b54\u6570\u636e\uff08streaming \u5f15\u64ce\uff09\uff1b",
                "\u8bf7\u901a\u8fc7 'resp' \u53c2\u6570\u63d0\u4f9b\u3002"),
            fix_en="Call irtc_quality(mod, resp=your_data).",
            fix_zh="\u8bf7\u8c03\u7528 irtc_quality(mod, resp=\u4f60\u7684\u6570\u636e)\u3002",
            class="irtc_error_input")
    }
    resp <- as.data.frame(resp, stringsAsFactors=FALSE)

    ctt <- irtc_ctt(resp)
    fit <- irtc_itemfit(mod, resp=resp)
    n_items <- nrow(ctt$items)

    rating <- character(n_items)
    reasons_en <- character(n_items)
    reasons_zh <- character(n_items)
    advice_en <- character(n_items)
    advice_zh <- character(n_items)

    for (j in seq_len(n_items)) {
        p <- ctt$items$pvalue[j]
        r <- ctt$items$discr[j]
        of <- fit$outfit[j]
        inf <- fit$infit[j]
        pts <- 0L
        rs_en <- character(0)
        rs_zh <- character(0)
        ad_en <- character(0)
        ad_zh <- character(0)

        if (!is.na(p) && p < th$p_hard) {
            pts <- pts + 1L
            rs_en <- c(rs_en, paste0("very hard (correct rate ",
                round(100 * p), "%)"))
            rs_zh <- c(rs_zh, paste0("\u9898\u76ee\u8fc7\u96be\uff08\u5f97\u5206\u7387\u4ec5 ",
                round(100 * p), "%\uff09"))
            ad_en <- c(ad_en, "check the key and the item wording")
            ad_zh <- c(ad_zh, "\u8bf7\u6838\u5bf9\u7b54\u6848\u952e\u4e0e\u9898\u5e72\u8868\u8ff0")
        } else if (!is.na(p) && p > th$p_easy) {
            pts <- pts + 1L
            rs_en <- c(rs_en, paste0("very easy (correct rate ",
                round(100 * p), "%)"))
            rs_zh <- c(rs_zh, paste0("\u9898\u76ee\u8fc7\u6613\uff08\u5f97\u5206\u7387\u8fbe ",
                round(100 * p), "%\uff09"))
            ad_en <- c(ad_en, "the item barely differentiates test takers")
            ad_zh <- c(ad_zh, "\u8be5\u9898\u51e0\u4e4e\u65e0\u6cd5\u533a\u5206\u8003\u751f\u6c34\u5e73")
        }

        if (!is.na(r) && r < 0) {
            pts <- pts + 4L
            rs_en <- c(rs_en, paste0("negative discrimination (r=",
                round(r, 2), "): high performers do worse on this item"))
            rs_zh <- c(rs_zh, paste0("\u533a\u5206\u5ea6\u4e3a\u8d1f\uff08r=", round(r, 2),
                "\uff09\uff1a\u6c34\u5e73\u9ad8\u7684\u4eba\u53cd\u800c\u66f4\u5bb9\u6613\u505a\u9519"))
            ad_en <- c(ad_en, "check for a wrong key or a misleading item")
            ad_zh <- c(ad_zh, "\u5f88\u53ef\u80fd\u662f\u7b54\u6848\u952e\u9519\u8bef\u6216\u9898\u76ee\u6709\u6b67\u4e49\uff0c\u8bf7\u4f18\u5148\u6392\u67e5")
        } else if (!is.na(r) && r < th$discr_poor) {
            pts <- pts + 2L
            rs_en <- c(rs_en, paste0("poor discrimination (r=",
                round(r, 2), ")"))
            rs_zh <- c(rs_zh, paste0("\u533a\u5206\u5ea6\u5f88\u4f4e\uff08r=", round(r, 2), "\uff09"))
            ad_en <- c(ad_en, "consider revising or replacing the item")
            ad_zh <- c(ad_zh, "\u5efa\u8bae\u4fee\u6539\u6216\u66ff\u6362\u8be5\u9898")
        } else if (!is.na(r) && r < th$discr_weak) {
            pts <- pts + 1L
            rs_en <- c(rs_en, paste0("weak discrimination (r=",
                round(r, 2), ")"))
            rs_zh <- c(rs_zh, paste0("\u533a\u5206\u5ea6\u504f\u4f4e\uff08r=", round(r, 2), "\uff09"))
            ad_en <- c(ad_en, "usable, but review the item content")
            ad_zh <- c(ad_zh, "\u53ef\u4ee5\u4f7f\u7528\uff0c\u4f46\u5efa\u8bae\u590d\u67e5\u9898\u76ee\u5185\u5bb9")
        }

        fit_vals <- c(outfit=of, infit=inf)
        for (fname in names(fit_vals)) {
            fv <- fit_vals[[fname]]
            if (is.na(fv)) next
            if (fv < th$fit_severe[1L] || fv > th$fit_severe[2L]) {
                pts <- pts + 2L
                rs_en <- c(rs_en, paste0("severe misfit (", fname, "=",
                    round(fv, 2), ")"))
                rs_zh <- c(rs_zh, paste0("\u6a21\u578b\u62df\u5408\u4e25\u91cd\u504f\u79bb\uff08", fname, "=",
                    round(fv, 2), "\uff09"))
                ad_en <- c(ad_en,
                    "responses do not follow the expected pattern")
                ad_zh <- c(ad_zh, "\u4f5c\u7b54\u6a21\u5f0f\u4e0e\u6a21\u578b\u9884\u671f\u660e\u663e\u4e0d\u7b26\uff0c\u8bf7\u68c0\u67e5\u8be5\u9898")
            } else if (fv < th$fit_mild[1L] || fv > th$fit_mild[2L]) {
                pts <- pts + 1L
                rs_en <- c(rs_en, paste0("mild misfit (", fname, "=",
                    round(fv, 2), ")"))
                rs_zh <- c(rs_zh, paste0("\u6a21\u578b\u62df\u5408\u8f7b\u5ea6\u504f\u79bb\uff08", fname, "=",
                    round(fv, 2), "\uff09"))
            }
        }

        rating[j] <- if (pts == 0L) {
            "good"
        } else if (pts == 1L) {
            "acceptable"
        } else if (pts <= 3L) {
            "review"
        } else {
            "revise"
        }
        reasons_en[j] <- if (length(rs_en) == 0L)
            "all indicators in the normal range" else
            paste(rs_en, collapse="; ")
        reasons_zh[j] <- if (length(rs_zh) == 0L)
            "\u5404\u9879\u6307\u6807\u5747\u5728\u6b63\u5e38\u8303\u56f4" else paste(rs_zh, collapse="\uff1b")
        advice_en[j] <- if (length(ad_en) == 0L) "keep the item" else
            paste(unique(ad_en), collapse="; ")
        advice_zh[j] <- if (length(ad_zh) == 0L) "\u53ef\u653e\u5fc3\u4f7f\u7528" else
            paste(unique(ad_zh), collapse="\uff1b")
    }

    out <- data.frame(
        item=ctt$items$item,
        N=ctt$items$N,
        pvalue=ctt$items$pvalue,
        discr=ctt$items$discr,
        outfit=fit$outfit,
        infit=fit$infit,
        rating=rating,
        reasons_en=reasons_en,
        reasons_zh=reasons_zh,
        advice_en=advice_en,
        advice_zh=advice_zh,
        stringsAsFactors=FALSE, row.names=NULL
    )
    attr(out, "alpha") <- ctt$alpha
    attr(out, "thresholds") <- th
    class(out) <- c("irtc_quality", "data.frame")
    out
}

irtc_quality_rating_label <- function(rating, lang=irtc_lang())
{
    labels <- list(
        good=c(en="Good", zh="\u597d"),
        acceptable=c(en="Acceptable", zh="\u53ef\u7528"),
        review=c(en="Review", zh="\u9700\u68c0\u67e5"),
        revise=c(en="Revise", zh="\u5efa\u8bae\u4fee\u6539")
    )
    vapply(rating, function(r) {
        lab <- labels[[r]]
        if (is.null(lab)) r else unname(lab[[lang]])
    }, character(1L), USE.NAMES=FALSE)
}

print.irtc_quality <- function(x, lang=irtc_lang(), ...)
{
    ## column subsets (e.g. x[, c("item", "rating")]) keep the class but
    ## lose columns this method formats; fall back to a plain display
    required <- c("item", "N", "pvalue", "discr", "outfit", "infit",
        "rating", "reasons_en", "reasons_zh")
    if (!all(required %in% colnames(x))) {
        return(print.data.frame(x, row.names=FALSE, ...))
    }
    cat(irtc_tr("Item quality ratings", "\u9898\u76ee\u8d28\u91cf\u8bc4\u7ea7", lang), "\n", sep="")
    show <- data.frame(
        item=x$item, N=x$N, pvalue=x$pvalue, discr=x$discr,
        outfit=x$outfit, infit=x$infit,
        rating=irtc_quality_rating_label(x$rating, lang),
        reasons=if (identical(lang, "zh")) x$reasons_zh else x$reasons_en,
        stringsAsFactors=FALSE
    )
    print(show, row.names=FALSE)
    tab <- table(factor(x$rating,
        levels=c("good", "acceptable", "review", "revise")))
    cat(irtc_tr("Summary: ", "\u6c47\u603b\uff1a", lang),
        paste(paste0(irtc_quality_rating_label(names(tab), lang), " ",
            as.integer(tab)), collapse=" | "), "\n", sep="")
    invisible(x)
}
