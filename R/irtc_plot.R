# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_plot.R
## Part of the IRTC package
## Base-graphics plots (zero extra dependencies) used interactively via
## plot.irtc() and embedded into the Word/HTML reports:
##   wright  - item difficulty vs person ability map
##   ability - person ability histogram
##   quality - item quality rating summary
##   icc     - item characteristic curves

plot.irtc <- function(x, type=c("wright", "ability", "quality", "icc"),
    lang=irtc_lang(), items=NULL, resp=NULL, ...)
{
    type <- match.arg(type)
    switch(type,
        wright=irtc_plot_wright(x, lang=lang, resp=resp),
        ability=irtc_plot_ability(x, lang=lang),
        quality=irtc_plot_quality_summary(x, lang=lang, resp=resp),
        icc=irtc_plot_icc(x, lang=lang, items=items))
    invisible(x)
}

irtc_plot_wright <- function(mod, lang=irtc_lang(), resp=NULL)
{
    eap <- irtc_extract_eap(mod)[, 1L]
    if (is.null(resp)) resp <- mod$resp
    par_tbl <- irtc_param_table(mod, resp=resp)
    b <- par_tbl$difficulty_b
    rng <- range(c(eap, b), na.rm=TRUE) + c(-0.4, 0.4)

    old <- graphics::par(no.readonly=TRUE)
    on.exit(graphics::par(old), add=TRUE)
    graphics::layout(matrix(1:2, nrow=2L), heights=c(2, 1.6))

    graphics::par(mar=c(0.6, 4, 2.5, 1))
    graphics::hist(eap, breaks=seq(rng[1L], rng[2L], length.out=31),
        col="#7B9FD4", border="white",
        main=irtc_tr("Item difficulty vs person ability (Wright map)",
            "\u9898\u76ee\u96be\u5ea6\u4e0e\u6837\u672c\u80fd\u529b\u5bf9\u7167\u56fe\uff08Wright Map\uff09", lang),
        xlab="", ylab=irtc_tr("Persons", "\u4eba\u6570", lang), xaxt="n")

    graphics::par(mar=c(4, 4, 0.6, 1))
    y <- rep_len(seq(0.8, 0.2, length.out=4L), length(b))
    graphics::plot(b, y, xlim=rng, ylim=c(0, 1), pch=18, cex=1.3,
        col="#C05050", xlab=irtc_tr("Ability / difficulty (logit)",
            "\u80fd\u529b / \u96be\u5ea6\uff08logit\uff09", lang),
        ylab=irtc_tr("Items", "\u9898\u76ee", lang), yaxt="n")
    graphics::text(b, y + 0.12, par_tbl$item_id, cex=0.7, srt=45, adj=0)
    graphics::abline(v=mean(eap, na.rm=TRUE), lty=2L, col="#7B9FD4")
    invisible(NULL)
}

irtc_plot_ability <- function(mod, lang=irtc_lang())
{
    eap <- irtc_extract_eap(mod)
    n_dim <- ncol(eap)
    old <- graphics::par(no.readonly=TRUE)
    on.exit(graphics::par(old), add=TRUE)
    if (n_dim > 1L) {
        graphics::par(mfrow=c(ceiling(n_dim / 2), min(n_dim, 2L)))
    }
    for (d in seq_len(n_dim)) {
        v <- eap[, d]
        graphics::hist(v, breaks=30L, col="#7B9FD4", border="white",
            main=if (n_dim > 1L) {
                paste0(irtc_tr("Ability distribution - dimension ",
                    "\u80fd\u529b\u5206\u5e03 \u2014\u2014 \u7b2c ", lang), d,
                    irtc_tr("", " \u7ef4", lang))
            } else {
                irtc_tr("Ability distribution", "\u6837\u672c\u80fd\u529b\u5206\u5e03", lang)
            },
            xlab=irtc_tr("Ability (EAP, logit)", "\u80fd\u529b\u503c\uff08EAP\uff0clogit\uff09",
                lang),
            ylab=irtc_tr("Persons", "\u4eba\u6570", lang))
        graphics::abline(v=mean(v, na.rm=TRUE), lty=2L, col="#C05050")
    }
    invisible(NULL)
}

irtc_plot_quality_summary <- function(mod, lang=irtc_lang(), resp=NULL)
{
    quality <- mod$usability$quality
    if (is.null(quality)) {
        quality <- irtc_quality(mod, resp=resp)
    }
    tab <- table(factor(quality$rating,
        levels=c("good", "acceptable", "review", "revise")))
    cols <- c("#4CAF50", "#A5D6A7", "#FFC107", "#EF5350")
    mids <- graphics::barplot(as.integer(tab),
        names.arg=irtc_quality_rating_label(names(tab), lang),
        col=cols, border=NA,
        main=irtc_tr("Item quality summary", "\u9898\u76ee\u8d28\u91cf\u5206\u7ea7\u6c47\u603b", lang),
        ylab=irtc_tr("Number of items", "\u9898\u76ee\u6570", lang),
        ylim=c(0, max(tab) * 1.2 + 1))
    graphics::text(mids, as.integer(tab), labels=as.integer(tab), pos=3L)
    invisible(NULL)
}

irtc_plot_icc <- function(mod, lang=irtc_lang(), items=NULL)
{
    AXsi <- irtc_extract_axsi(mod)
    B <- mod$B
    n_items <- dim(B)[1L]
    maxK <- dim(B)[2L]
    if (dim(B)[3L] > 1L) {
        irtc_stop(code="E502",
            en="ICC plots are only available for unidimensional models.",
            zh="ICC \u66f2\u7ebf\u76ee\u524d\u4ec5\u652f\u6301\u5355\u7ef4\u6a21\u578b\u3002",
            fix_en="Plot each dimension's items separately.",
            fix_zh="\u8bf7\u5206\u7ef4\u5ea6\u5355\u72ec\u7ed8\u5236\u3002",
            class="irtc_error_report")
    }
    item_names <- if (!is.null(mod$resp)) colnames(mod$resp) else
        paste0("I", seq_len(n_items))
    if (is.null(items)) {
        items <- seq_len(min(n_items, 12L))
    } else if (is.character(items)) {
        items <- match(items, item_names)
        items <- items[!is.na(items)]
    }
    theta <- seq(-4, 4, length.out=121L)
    n_show <- length(items)
    old <- graphics::par(no.readonly=TRUE)
    on.exit(graphics::par(old), add=TRUE)
    n_col <- min(3L, n_show)
    graphics::par(mfrow=c(ceiling(n_show / n_col), n_col),
        mar=c(3.5, 3.5, 2, 0.8), mgp=c(2, 0.7, 0))
    for (j in items) {
        k_use <- which(is.finite(AXsi[j, ]))
        if (length(k_use) < 2L) next
        eta <- matrix(AXsi[j, k_use], nrow=length(theta),
            ncol=length(k_use), byrow=TRUE)
        eta <- eta + outer(theta, B[j, k_use, 1L])
        eta <- eta - apply(eta, 1L, max)
        prob <- exp(eta) / rowSums(exp(eta))
        if (length(k_use) == 2L) {
            graphics::plot(theta, prob[, 2L], type="l", lwd=2L,
                col="#3B6FB6", ylim=c(0, 1), main=item_names[j],
                xlab=irtc_tr("Ability", "\u80fd\u529b\u503c", lang),
                ylab=irtc_tr("P(correct)", "\u7b54\u5bf9\u6982\u7387", lang))
        } else {
            graphics::matplot(theta, prob, type="l", lwd=2L,
                lty=1L, ylim=c(0, 1), main=item_names[j],
                xlab=irtc_tr("Ability", "\u80fd\u529b\u503c", lang),
                ylab=irtc_tr("P(category)", "\u7c7b\u522b\u6982\u7387", lang))
        }
    }
    invisible(NULL)
}
