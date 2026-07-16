# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-read-weights.R
## Tests for sampling weight import in irtc_read() and the pweights
## pass-through in irtc().

irtc_test_sim_wgt <- function(n=150, k=5, seed=7)
{
    set.seed(seed)
    theta <- stats::rnorm(n)
    b <- seq(-1, 1, length.out=k)
    resp <- sapply(seq_len(k), function(j) {
        as.numeric(stats::runif(n) < stats::plogis(theta - b[j]))
    })
    colnames(resp) <- paste0("I", seq_len(k))
    as.data.frame(resp)
}

test_that("irtc_read auto-detects an English weight column", {
    df <- irtc_test_sim_wgt(n=20)
    df$weight <- stats::runif(20, 0.5, 2)
    out <- irtc_read(df, verbose=FALSE)
    expect_equal(ncol(out$resp), 5L)
    expect_false("weight" %in% colnames(out$resp))
    expect_equal(length(out$weights), 20L)
    expect_true("I115" %in% out$log$code)
})

test_that("irtc_read auto-detects a Chinese weight column", {
    df <- irtc_test_sim_wgt(n=15)
    df[["\u6743\u91cd"]] <- rep(1.5, 15)
    out <- irtc_read(df, verbose=FALSE)
    expect_equal(ncol(out$resp), 5L)
    expect_equal(out$weights, rep(1.5, 15))
})

test_that("irtc_read accepts an explicit weights column by name and index", {
    df <- irtc_test_sim_wgt(n=12)
    df$myw <- seq(0.1, 1.2, by=0.1)
    out <- irtc_read(df, weights="myw", verbose=FALSE)
    expect_equal(out$weights, seq(0.1, 1.2, by=0.1))
    expect_true("I116" %in% out$log$code)
    out2 <- irtc_read(df, weights=6, verbose=FALSE)
    expect_equal(out2$weights, seq(0.1, 1.2, by=0.1))
})

test_that("explicit weights column beats auto-detection", {
    df <- irtc_test_sim_wgt(n=10)
    df$weight <- rep(2, 10)
    df$myw <- rep(3, 10)
    out <- irtc_read(df, weights="myw", verbose=FALSE)
    expect_equal(out$weights, rep(3, 10))
    ## the unused 'weight' column stays in the response data and is
    ## reported by downstream checks rather than silently guessed
    expect_true("weight" %in% colnames(out$resp))
})

test_that("guess_weights=FALSE disables auto-detection", {
    df <- irtc_test_sim_wgt(n=10)
    df$weight <- rep(2, 10)
    out <- irtc_read(df, guess_weights=FALSE, verbose=FALSE)
    expect_null(out$weights)
    expect_true("weight" %in% colnames(out$resp))
})

test_that("missing weights column raises E109", {
    df <- irtc_test_sim_wgt(n=10)
    cond <- tryCatch(irtc_read(df, weights="nope", verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E109")
    cond2 <- tryCatch(irtc_read(df, weights=99, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond2$code, "E109")
})

test_that("non-numeric weights raise E107", {
    df <- irtc_test_sim_wgt(n=10)
    df$weight <- c(rep("1.0", 9), "abc")
    cond <- tryCatch(irtc_read(df, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E107")
})

test_that("zero or negative weights raise E108", {
    df <- irtc_test_sim_wgt(n=10)
    df$weight <- c(rep(1, 9), 0)
    cond <- tryCatch(irtc_read(df, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E108")
    df$weight <- c(rep(1, 9), -2)
    cond2 <- tryCatch(irtc_read(df, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond2$code, "E108")
})

test_that("missing weight values are set to 1 with W117", {
    df <- irtc_test_sim_wgt(n=10)
    df$weight <- c(rep(2, 8), NA, NA)
    expect_warning(out <- irtc_read(df, verbose=FALSE),
        class="irtc_warning_read")
    expect_equal(out$weights, c(rep(2, 8), 1, 1))
    expect_true("W117" %in% out$log$code)
})

test_that("weights stay aligned when empty rows are dropped", {
    df <- irtc_test_sim_wgt(n=6)
    df[3, ] <- NA
    df$weight <- seq_len(6)
    out <- irtc_read(df, verbose=FALSE)
    expect_equal(nrow(out$resp), 5L)
    expect_equal(out$weights, c(1, 2, 4, 5, 6))
})

test_that("weights are read from a csv file and printed", {
    df <- irtc_test_sim_wgt(n=8)
    df$wt <- rep(1.25, 8)
    path <- tempfile(fileext=".csv")
    utils::write.csv(df, path, row.names=FALSE)
    out <- irtc_read(path, verbose=FALSE)
    expect_equal(out$weights, rep(1.25, 8))
    txt <- paste(capture.output(print(out, lang="en")), collapse="\n")
    expect_match(txt, "weighted N = 10")
    unlink(path)
})

test_that("irtc uses the weights column as pweights", {
    resp <- irtc_test_sim_wgt(n=150, k=5)
    w <- stats::runif(150, 0.5, 2)
    df <- cbind(resp, weight=w)
    mod <- irtc(df, model="1PL", verbose=FALSE)
    ref <- irtc.mml(resp=as.matrix(resp), irtmodel="1PL", pweights=w,
        verbose=FALSE)
    expect_equal(mod$pweights, ref$pweights, tolerance=1e-8)
    expect_equal(mod$xsi$xsi, ref$xsi$xsi, tolerance=1e-6)
})

test_that("explicit pweights wins over the weights column with W418", {
    resp <- irtc_test_sim_wgt(n=100, k=5)
    df <- cbind(resp, weight=stats::runif(100, 0.5, 2))
    pw <- rep(1, 100)
    expect_warning(
        mod <- irtc(df, model="1PL", verbose=FALSE, pweights=pw),
        class="irtc_warning_estimation")
    expect_equal(unname(mod$pweights), pw, tolerance=1e-8)
})
