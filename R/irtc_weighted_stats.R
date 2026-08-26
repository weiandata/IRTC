# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_weighted_stats.R
## Part of the IRTC package
## Case-weighted versions of the descriptive statistics the usability layer
## reports. In a complex-sample survey the IRT parameters are estimated with the
## sampling weights, so the classical statistics printed beside them have to be
## computed on the same basis or the table mixes two populations.
##
## Every helper reduces exactly to its unweighted stats:: counterpart when the
## weights are constant, so unweighted callers see no change.

## Validate case weights and normalize them to mean 1 (sum n). NULL gives
## constant weights of 1, which makes every helper below unweighted.
irtc_prep_case_weights <- function(w, n)
{
    if (is.null(w)) {
        return(rep(1, n))
    }
    w <- as.numeric(w)
    if (length(w) == 1L) {
        w <- rep(w, n)
    }
    if (length(w) != n) {
        irtc_stop(code="E410",
            en=paste0("'weights' has length ", length(w), " but the data have ",
                n, " rows."),
            zh=paste0("'weights' \u957f\u5ea6\u4e3a ", length(w),
                "\uff0c\u4f46\u6570\u636e\u6709 ", n, " \u884c\u3002"),
            fix_en="Supply one weight per person, in the same row order.",
            fix_zh="\u8bf7\u6309\u76f8\u540c\u7684\u884c\u987a\u5e8f\u4e3a\u6bcf\u4e2a\u6837\u672c\u63d0\u4f9b\u4e00\u4e2a\u6743\u91cd\u3002",
            class="irtc_error_input")
    }
    if (any(!is.finite(w)) || any(w < 0) || sum(w) <= 0) {
        irtc_stop(code="E410",
            en="'weights' must be finite, non-negative and not all zero.",
            zh="'weights' \u5fc5\u987b\u4e3a\u6709\u9650\u7684\u975e\u8d1f\u6570\uff0c\u4e14\u4e0d\u80fd\u5168\u4e3a\u96f6\u3002",
            fix_en="Check the weight column for missing or negative values.",
            fix_zh="\u8bf7\u68c0\u67e5\u6743\u91cd\u5217\u662f\u5426\u5b58\u5728\u7f3a\u5931\u503c\u6216\u8d1f\u503c\u3002",
            class="irtc_error_input")
    }
    w * n / sum(w)
}

## Weighted mean over the non-missing entries of x.
irtc_weighted_mean <- function(x, w)
{
    use <- !is.na(x)
    if (!any(use)) return(NA_real_)
    sw <- sum(w[use])
    if (sw <= 0) return(NA_real_)
    sum(w[use] * x[use]) / sw
}

## Weighted covariance of two vectors over their commonly observed entries.
## Denominator sum(w) - 1 reproduces stats::cov()'s n - 1 when w is constant.
irtc_weighted_cov2 <- function(x, y, w)
{
    use <- !is.na(x) & !is.na(y)
    if (sum(use) < 2L) return(NA_real_)
    ww <- w[use]
    sw <- sum(ww)
    if (sw <= 1) return(NA_real_)
    xx <- x[use] - sum(ww * x[use]) / sw
    yy <- y[use] - sum(ww * y[use]) / sw
    sum(ww * xx * yy) / (sw - 1)
}

## Weighted Pearson correlation over the commonly observed entries.
irtc_weighted_cor <- function(x, y, w)
{
    cxy <- irtc_weighted_cov2(x, y, w)
    cxx <- irtc_weighted_cov2(x, x, w)
    cyy <- irtc_weighted_cov2(y, y, w)
    if (!is.finite(cxy) || !is.finite(cxx) || !is.finite(cyy) ||
        cxx <= 0 || cyy <= 0) {
        return(NA_real_)
    }
    cxy / sqrt(cxx * cyy)
}

## Weighted covariance matrix, pairwise complete (as stats::cov(use=
## "pairwise.complete.obs")). Returns NULL when any pair is unusable, letting
## the caller fall back to complete cases.
irtc_weighted_cov <- function(X, w)
{
    k <- ncol(X)
    out <- matrix(NA_real_, k, k, dimnames=list(colnames(X), colnames(X)))
    for (j in seq_len(k)) {
        for (l in j:k) {
            v <- irtc_weighted_cov2(X[, j], X[, l], w)
            out[j, l] <- out[l, j] <- v
        }
    }
    if (anyNA(out)) return(NULL)
    out
}

## Weighted variance of x (non-missing entries).
irtc_weighted_var <- function(x, w)
{
    irtc_weighted_cov2(x, x, w)
}

## Weighted percentile rank, in percent: the share of the weighted population
## below each value, counting ties at half weight. This is the weighted
## analogue of (rank - 0.5) / n and reduces to it exactly under constant
## weights, ties included. NA values stay NA.
irtc_weighted_percentile <- function(v, w)
{
    out <- rep(NA_real_, length(v))
    use <- !is.na(v)
    if (!any(use)) {
        return(out)
    }
    vv <- v[use]
    ww <- w[use]
    total <- sum(ww)
    if (!is.finite(total) || total <= 0) {
        return(out)
    }
    ## cumulative weight strictly below each distinct value, plus half the
    ## weight sitting exactly on it
    ord <- order(vv)
    sorted_v <- vv[ord]
    sorted_w <- ww[ord]
    cum_before <- c(0, cumsum(sorted_w)[-length(sorted_w)])
    ## collapse ties: every tied observation shares the group's below-weight
    grp <- match(sorted_v, sorted_v)          # first index of each tied run
    below <- cum_before[grp]
    tie_w <- as.numeric(tapply(sorted_w, grp, sum))[match(grp, sort(unique(grp)))]
    pct <- 100 * (below + 0.5 * tie_w) / total
    out[use][ord] <- pct
    out
}

## Weighted standard deviation (non-missing entries).
irtc_weighted_sd <- function(x, w)
{
    v <- irtc_weighted_cov2(x, x, w)
    if (!is.finite(v) || v < 0) NA_real_ else sqrt(v)
}

## Weighted T score: mean 50, SD 10 on the weighted sample.
irtc_weighted_tscore <- function(v, w)
{
    m <- irtc_weighted_mean(v, w)
    s <- irtc_weighted_sd(v, w)
    if (!is.finite(s) || s <= 0) {
        return(rep(NA_real_, length(v)))
    }
    50 + 10 * (v - m) / s
}

## Person identifiers as text. A numeric ID read from SPSS or Excel arrives as
## a double, and as.character() would render a long one in scientific notation
## ("1e+15"), silently corrupting the key used to join results back to the
## sample. Format whole numbers as plain digits instead.
irtc_format_id <- function(pid)
{
    if (is.numeric(pid) && all(is.na(pid) | pid == round(pid))) {
        return(format(pid, scientific=FALSE, trim=TRUE, justify="none"))
    }
    as.character(pid)
}
