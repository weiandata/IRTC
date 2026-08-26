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
